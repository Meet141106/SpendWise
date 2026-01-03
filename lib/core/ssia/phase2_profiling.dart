import '../../models/transaction.dart';
import '../../models/spending_fingerprint.dart';

/// SSIA Phase 2: Student Behavior Profiling
/// Builds and updates Personal Spending Fingerprint (PSF)
class Phase2Profiling {
  /// Build or update Personal Spending Fingerprint from transaction history
  /// 
  /// PSF includes:
  /// - Average spend per category
  /// - Typical spending hours
  /// - Weekly burn rate
  /// - Fixed recurring costs
  /// - Personal risk tolerance band
  static SpendingFingerprint buildFingerprint({
    required List<Transaction> transactions,
    SpendingFingerprint? existingFingerprint,
  }) {
    if (transactions.isEmpty) {
      return existingFingerprint ?? SpendingFingerprint.empty();
    }

    // Calculate category averages
    final categoryAverages = _calculateCategoryAverages(transactions);
    
    // Calculate typical spending hours
    final typicalSpendingHours = _calculateTypicalSpendingHours(transactions);
    
    // Calculate weekly burn rate
    final weeklyBurnRate = _calculateWeeklyBurnRate(transactions);
    
    // Detect fixed recurring costs
    final fixedRecurringCosts = _detectRecurringCosts(transactions);
    
    // Calculate risk tolerance band (based on spending variance)
    final riskToleranceBand = _calculateRiskToleranceBand(transactions);

    return SpendingFingerprint(
      categoryAverages: categoryAverages,
      typicalSpendingHours: typicalSpendingHours,
      weeklyBurnRate: weeklyBurnRate,
      fixedRecurringCosts: fixedRecurringCosts,
      riskToleranceBand: riskToleranceBand,
      totalTransactions: transactions.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Calculate average spend per category
  static Map<String, double> _calculateCategoryAverages(
    List<Transaction> transactions,
  ) {
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (final transaction in transactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      categoryCounts[transaction.category] = 
          (categoryCounts[transaction.category] ?? 0) + 1;
    }

    final categoryAverages = <String, double>{};
    for (final category in categoryTotals.keys) {
      categoryAverages[category] = 
          categoryTotals[category]! / categoryCounts[category]!;
    }

    return categoryAverages;
  }

  /// Calculate typical spending hours (hour -> frequency)
  static Map<int, int> _calculateTypicalSpendingHours(
    List<Transaction> transactions,
  ) {
    final hourFrequency = <int, int>{};

    for (final transaction in transactions) {
      final hour = transaction.timestamp.hour;
      hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
    }

    return hourFrequency;
  }

  /// Calculate weekly burn rate
  /// Total spend in last 7 days ÷ 1 week
  static double _calculateWeeklyBurnRate(List<Transaction> transactions) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    final recentTransactions = transactions.where(
      (t) => t.timestamp.isAfter(oneWeekAgo),
    );

    final totalSpent = recentTransactions.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // If less than 7 days of data, extrapolate
    if (transactions.isEmpty) return 0.0;
    
    final oldestTransaction = transactions.reduce(
      (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b,
    );
    
    final daysSinceOldest = now.difference(oldestTransaction.timestamp).inDays;
    
    if (daysSinceOldest < 7) {
      // Extrapolate to full week
      final totalAllTime = transactions.fold<double>(
        0.0,
        (sum, t) => sum + t.amount,
      );
      return (totalAllTime / (daysSinceOldest + 1)) * 7;
    }

    return totalSpent;
  }

  /// Detect recurring costs (subscriptions, regular payments)
  /// 
  /// Logic:
  /// - Same merchant
  /// - Similar amount (±10%)
  /// - Regular interval (weekly/monthly)
  static List<RecurringCost> _detectRecurringCosts(
    List<Transaction> transactions,
  ) {
    final recurringCosts = <RecurringCost>[];
    final merchantGroups = <String, List<Transaction>>{};

    // Group by merchant
    for (final transaction in transactions) {
      if (!merchantGroups.containsKey(transaction.merchant)) {
        merchantGroups[transaction.merchant] = [];
      }
      merchantGroups[transaction.merchant]!.add(transaction);
    }

    // Analyze each merchant group
    for (final entry in merchantGroups.entries) {
      final merchant = entry.key;
      final merchantTransactions = entry.value;

      if (merchantTransactions.length < 2) continue;

      // Sort by timestamp
      merchantTransactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Check for regular intervals
      final intervals = <int>[];
      for (int i = 1; i < merchantTransactions.length; i++) {
        final daysBetween = merchantTransactions[i].timestamp
            .difference(merchantTransactions[i - 1].timestamp)
            .inDays;
        intervals.add(daysBetween);
      }

      // Check if intervals are consistent
      if (intervals.isEmpty) continue;
      
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final isRegular = intervals.every(
        (interval) => (interval - avgInterval).abs() <= 3, // ±3 days tolerance
      );

      if (isRegular) {
        // Determine frequency
        String frequency;
        if (avgInterval <= 1.5) {
          frequency = 'daily';
        } else if (avgInterval <= 10) {
          frequency = 'weekly';
        } else {
          frequency = 'monthly';
        }

        // Calculate average amount
        final avgAmount = merchantTransactions.fold<double>(
          0.0,
          (sum, t) => sum + t.amount,
        ) / merchantTransactions.length;

        recurringCosts.add(RecurringCost(
          merchant: merchant,
          amount: avgAmount,
          frequency: frequency,
          lastDetected: merchantTransactions.last.timestamp,
        ));
      }
    }

    return recurringCosts;
  }

  /// Calculate risk tolerance band based on spending variance
  /// 
  /// Low variance = low tolerance (0.0 - 0.3)
  /// Medium variance = medium tolerance (0.3 - 0.7)
  /// High variance = high tolerance (0.7 - 1.0)
  static double _calculateRiskToleranceBand(List<Transaction> transactions) {
    if (transactions.length < 3) return 0.5; // Default medium

    final amounts = transactions.map((t) => t.amount).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    
    // Calculate standard deviation
    final variance = amounts.fold<double>(
      0.0,
      (sum, amount) => sum + ((amount - mean) * (amount - mean)),
    ) / amounts.length;
    
    final stdDev = variance > 0 ? variance : 0;
    
    // Coefficient of variation (CV)
    final cv = mean > 0 ? stdDev / mean : 0;
    
    // Map CV to tolerance band (0.0 - 1.0)
    // CV > 1.0 = high variance = high tolerance
    // CV < 0.3 = low variance = low tolerance
    if (cv < 0.3) return 0.2;
    if (cv < 0.7) return 0.5;
    return 0.8;
  }

  /// Update fingerprint with new transaction
  /// Incremental update for efficiency
  static SpendingFingerprint updateWithNewTransaction({
    required SpendingFingerprint fingerprint,
    required Transaction transaction,
  }) {
    // Update category average
    final categoryAverages = Map<String, double>.from(fingerprint.categoryAverages);
    final currentAvg = categoryAverages[transaction.category] ?? 0.0;
    final currentCount = fingerprint.totalTransactions;
    
    // Incremental average: new_avg = (old_avg * n + new_value) / (n + 1)
    categoryAverages[transaction.category] = 
        (currentAvg * currentCount + transaction.amount) / (currentCount + 1);

    // Update typical spending hours
    final typicalSpendingHours = Map<int, int>.from(fingerprint.typicalSpendingHours);
    final hour = transaction.timestamp.hour;
    typicalSpendingHours[hour] = (typicalSpendingHours[hour] ?? 0) + 1;

    return SpendingFingerprint(
      categoryAverages: categoryAverages,
      typicalSpendingHours: typicalSpendingHours,
      weeklyBurnRate: fingerprint.weeklyBurnRate, // Recalculate periodically
      fixedRecurringCosts: fingerprint.fixedRecurringCosts,
      riskToleranceBand: fingerprint.riskToleranceBand,
      totalTransactions: fingerprint.totalTransactions + 1,
      lastUpdated: DateTime.now(),
    );
  }
}
