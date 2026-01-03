import '../../models/transaction.dart';
import '../../models/risk_alert.dart';
import '../../models/spending_fingerprint.dart';

/// SSIA Phase 4: Actionable Insight Generation
/// Converts CRS into human-readable alerts with reasons and suggested actions
class Phase4Insights {
  /// Generate risk alerts from scored transactions
  /// 
  /// Each alert answers:
  /// - Why was this flagged?
  /// - What should the student do next?
  static List<RiskAlert> generateAlerts({
    required List<Transaction> transactions,
    required SpendingFingerprint fingerprint,
  }) {
    final alerts = <RiskAlert>[];

    for (final transaction in transactions) {
      // Only generate alerts for amber and red risk levels
      if (transaction.riskLevel == 'green') continue;

      // Detect specific alert types
      final alertType = _detectAlertType(transaction, transactions);
      
      // Generate explainable reason and suggested action
      final insight = _generateInsight(
        transaction: transaction,
        alertType: alertType,
        fingerprint: fingerprint,
        allTransactions: transactions,
      );

      alerts.add(RiskAlert(
        transactionId: transaction.id!,
        alertType: alertType,
        riskLevel: transaction.riskLevel,
        reason: insight.reason,
        suggestedAction: insight.suggestedAction,
        detectedAt: DateTime.now(),
      ));
    }

    return alerts;
  }

  /// Detect specific alert type based on transaction patterns
  static String _detectAlertType(
    Transaction transaction,
    List<Transaction> allTransactions,
  ) {
    // Check for duplicate payment
    final duplicates = allTransactions.where((t) =>
      t.id != transaction.id &&
      t.merchant.toLowerCase() == transaction.merchant.toLowerCase() &&
      (t.amount - transaction.amount).abs() < 1.0 && // Same amount (±₹1)
      t.timestamp.difference(transaction.timestamp).inMinutes.abs() < 60 // Within 1 hour
    );
    
    if (duplicates.isNotEmpty) {
      return 'duplicate_payment';
    }

    // Check for spending spike
    if (transaction.spendIntensity > 2.5) {
      return 'spending_spike';
    }

    // Check for micro-transactions (repeated small amounts)
    if (transaction.amount < 50) {
      final recentSmall = allTransactions.where((t) =>
        t.amount < 50 &&
        t.timestamp.isAfter(transaction.timestamp.subtract(const Duration(hours: 24)))
      );
      
      if (recentSmall.length >= 5) {
        return 'micro_transaction';
      }
    }

    // Check for subscription trap
    if (transaction.paymentMode == 'Subscription' || transaction.recurrenceFlag) {
      return 'subscription_trap';
    }

    return 'spending_spike'; // Default
  }

  /// Generate explainable insight with reason and suggested action
  static _Insight _generateInsight({
    required Transaction transaction,
    required String alertType,
    required SpendingFingerprint fingerprint,
    required List<Transaction> allTransactions,
  }) {
    switch (alertType) {
      case 'duplicate_payment':
        return _Insight(
          reason: 'Duplicate payment detected: ₹${transaction.amount.toStringAsFixed(0)} to ${transaction.merchant} within the last hour.',
          suggestedAction: 'Check your payment history and contact the merchant if this was charged twice by mistake.',
        );

      case 'spending_spike':
        final categoryAvg = fingerprint.getCategoryAverage(transaction.category);
        final multiplier = categoryAvg > 0 
            ? (transaction.amount / categoryAvg).toStringAsFixed(1)
            : '—';
        
        return _Insight(
          reason: 'This expense (₹${transaction.amount.toStringAsFixed(0)}) is ${multiplier}× higher than your usual ${transaction.category.toLowerCase()} spend.',
          suggestedAction: 'Review if this was a planned expense. Consider setting a budget limit for ${transaction.category.toLowerCase()}.',
        );

      case 'micro_transaction':
        final recentSmall = allTransactions.where((t) =>
          t.amount < 50 &&
          t.timestamp.isAfter(transaction.timestamp.subtract(const Duration(hours: 24)))
        ).length;
        
        final totalSmall = allTransactions.where((t) =>
          t.amount < 50 &&
          t.timestamp.isAfter(transaction.timestamp.subtract(const Duration(hours: 24)))
        ).fold<double>(0.0, (sum, t) => sum + t.amount);
        
        return _Insight(
          reason: '$recentSmall small transactions (₹${totalSmall.toStringAsFixed(0)} total) in the last 24 hours.',
          suggestedAction: 'Small expenses add up quickly. Consider consolidating purchases or using cash to track better.',
        );

      case 'subscription_trap':
        final isNew = !fingerprint.fixedRecurringCosts.any(
          (cost) => cost.merchant.toLowerCase() == transaction.merchant.toLowerCase(),
        );
        
        if (isNew) {
          // Calculate impact
          final monthlyImpact = transaction.amount;
          final canteenMeals = (monthlyImpact / 50).floor(); // Assuming ₹50 per meal
          
          return _Insight(
            reason: 'New subscription detected: ${transaction.merchant} at ₹${transaction.amount.toStringAsFixed(0)}/month.',
            suggestedAction: 'This costs ₹${monthlyImpact.toStringAsFixed(0)}/month ≈ $canteenMeals canteen meals. Review if you\'ll use it regularly.',
          );
        } else {
          final knownCost = fingerprint.fixedRecurringCosts.firstWhere(
            (cost) => cost.merchant.toLowerCase() == transaction.merchant.toLowerCase(),
          );
          
          return _Insight(
            reason: 'Subscription amount changed: ₹${knownCost.amount.toStringAsFixed(0)} → ₹${transaction.amount.toStringAsFixed(0)} for ${transaction.merchant}.',
            suggestedAction: 'Verify this price change is expected. Check for plan upgrades or hidden fees.',
          );
        }

      default:
        return _Insight(
          reason: transaction.riskReason ?? 'Unusual spending pattern detected.',
          suggestedAction: 'Review this transaction and ensure it was intentional.',
        );
    }
  }

  /// Generate student-centric insights summary
  static Map<String, dynamic> generateInsightsSummary({
    required List<Transaction> transactions,
    required SpendingFingerprint fingerprint,
    double? currentBalance,
  }) {
    // Category-wise spending
    final categorySpending = <String, double>{};
    for (final transaction in transactions) {
      categorySpending[transaction.category] = 
          (categorySpending[transaction.category] ?? 0) + transaction.amount;
    }

    // Weekly vs monthly comparison
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    
    final weeklySpend = transactions
        .where((t) => t.timestamp.isAfter(oneWeekAgo))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    
    final monthlySpend = transactions
        .where((t) => t.timestamp.isAfter(oneMonthAgo))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    // Burn rate indicator
    final dailyBurnRate = fingerprint.dailyBurnRate;
    final daysRemaining = currentBalance != null && dailyBurnRate > 0
        ? (currentBalance / dailyBurnRate).floor()
        : null;

    // Subscription cost impact
    final totalSubscriptions = fingerprint.fixedRecurringCosts
        .where((cost) => cost.frequency == 'monthly')
        .fold<double>(0.0, (sum, cost) => sum + cost.amount);
    
    final canteenMealsEquivalent = (totalSubscriptions / 50).floor();

    // Safe to spend amount
    final safeToSpend = currentBalance != null
        ? currentBalance - fingerprint.totalFixedMonthlyCosts
        : null;

    return {
      'categorySpending': categorySpending,
      'weeklySpend': weeklySpend,
      'monthlySpend': monthlySpend,
      'dailyBurnRate': dailyBurnRate,
      'daysRemaining': daysRemaining,
      'totalSubscriptions': totalSubscriptions,
      'canteenMealsEquivalent': canteenMealsEquivalent,
      'safeToSpend': safeToSpend,
    };
  }
}

/// Internal insight helper
class _Insight {
  final String reason;
  final String suggestedAction;
  
  _Insight({required this.reason, required this.suggestedAction});
}
