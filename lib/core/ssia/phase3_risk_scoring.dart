import '../../models/transaction.dart';
import '../../models/spending_fingerprint.dart';

/// SSIA Phase 3: Contextual Risk Scoring (CORE INNOVATION)
/// Computes Contextual Risk Score (CRS) for every transaction
class Phase3RiskScoring {
  /// Compute Contextual Risk Score for a transaction
  /// 
  /// CRS factors:
  /// 1. Amount deviation from personal average
  /// 2. Time deviation (unusual spending hour)
  /// 3. Frequency spike (rapid repeated payments)
  /// 4. Recurrence anomaly (unexpected subscriptions)
  /// 
  /// Returns: Transaction with updated risk level and CRS
  static Transaction scoreTransaction({
    required Transaction transaction,
    required SpendingFingerprint fingerprint,
    required List<Transaction> recentTransactions,
  }) {
    double crs = 0.0;
    final reasons = <String>[];

    // Factor 1: Amount Deviation (40% weight)
    final amountScore = _scoreAmountDeviation(
      transaction: transaction,
      fingerprint: fingerprint,
    );
    crs += amountScore.score * 0.4;
    if (amountScore.reason != null) reasons.add(amountScore.reason!);

    // Factor 2: Time Deviation (20% weight)
    final timeScore = _scoreTimeDeviation(
      transaction: transaction,
      fingerprint: fingerprint,
    );
    crs += timeScore.score * 0.2;
    if (timeScore.reason != null) reasons.add(timeScore.reason!);

    // Factor 3: Frequency Spike (25% weight)
    final frequencyScore = _scoreFrequencySpike(
      transaction: transaction,
      recentTransactions: recentTransactions,
    );
    crs += frequencyScore.score * 0.25;
    if (frequencyScore.reason != null) reasons.add(frequencyScore.reason!);

    // Factor 4: Recurrence Anomaly (15% weight)
    final recurrenceScore = _scoreRecurrenceAnomaly(
      transaction: transaction,
      fingerprint: fingerprint,
    );
    crs += recurrenceScore.score * 0.15;
    if (recurrenceScore.reason != null) reasons.add(recurrenceScore.reason!);

    // Map CRS to risk level
    final riskLevel = _mapCRSToRiskLevel(crs, fingerprint.riskToleranceBand);
    
    return transaction.copyWith(
      contextualRiskScore: crs,
      riskLevel: riskLevel,
      riskReason: reasons.isEmpty ? null : reasons.join(' • '),
    );
  }

  /// Factor 1: Amount Deviation Score
  /// Measures how much the amount deviates from personal average
  static _ScoreResult _scoreAmountDeviation({
    required Transaction transaction,
    required SpendingFingerprint fingerprint,
  }) {
    final categoryAvg = fingerprint.getCategoryAverage(transaction.category);
    
    if (categoryAvg == 0.0) {
      // No baseline, neutral score
      return _ScoreResult(score: 0.0);
    }

    final deviation = (transaction.amount - categoryAvg).abs() / categoryAvg;
    
    // Scoring logic:
    // deviation < 0.5 (50%) = low risk (0.0 - 0.3)
    // deviation 0.5 - 2.0 (50% - 200%) = medium risk (0.3 - 0.7)
    // deviation > 2.0 (200%) = high risk (0.7 - 1.0)
    
    double score;
    String? reason;
    
    if (deviation < 0.5) {
      score = deviation * 0.6; // Max 0.3
    } else if (deviation < 2.0) {
      score = 0.3 + (deviation - 0.5) * 0.27; // 0.3 - 0.7
      final multiplier = (transaction.amount / categoryAvg).toStringAsFixed(1);
      reason = '${multiplier}× your usual ${transaction.category.toLowerCase()} spend';
    } else {
      score = 0.7 + ((deviation - 2.0) / 3.0).clamp(0.0, 0.3); // 0.7 - 1.0
      final multiplier = (transaction.amount / categoryAvg).toStringAsFixed(1);
      reason = '${multiplier}× higher than your typical ${transaction.category.toLowerCase()} expense';
    }
    
    return _ScoreResult(score: score, reason: reason);
  }

  /// Factor 2: Time Deviation Score
  /// Detects unusual spending hours
  static _ScoreResult _scoreTimeDeviation({
    required Transaction transaction,
    required SpendingFingerprint fingerprint,
  }) {
    final hour = transaction.timestamp.hour;
    final isTypical = fingerprint.isTypicalSpendingHour(hour);
    
    if (isTypical || fingerprint.totalTransactions < 10) {
      return _ScoreResult(score: 0.0);
    }
    
    // Unusual hour detected
    String timeLabel;
    if (hour >= 0 && hour < 5) {
      timeLabel = 'late night (${hour}:00)';
    } else if (hour >= 22) {
      timeLabel = 'late night (${hour}:00)';
    } else {
      timeLabel = '${hour}:00';
    }
    
    return _ScoreResult(
      score: 0.6,
      reason: 'Unusual spending time: $timeLabel',
    );
  }

  /// Factor 3: Frequency Spike Score
  /// Detects rapid repeated payments
  static _ScoreResult _scoreFrequencySpike({
    required Transaction transaction,
    required List<Transaction> recentTransactions,
  }) {
    // Check for same merchant in last 24 hours
    final oneDayAgo = transaction.timestamp.subtract(const Duration(days: 1));
    
    final sameMerchantRecent = recentTransactions.where((t) =>
      t.merchant.toLowerCase() == transaction.merchant.toLowerCase() &&
      t.timestamp.isAfter(oneDayAgo) &&
      t.timestamp.isBefore(transaction.timestamp)
    ).toList();
    
    if (sameMerchantRecent.isEmpty) {
      return _ScoreResult(score: 0.0);
    }
    
    // Multiple payments to same merchant in 24 hours
    final count = sameMerchantRecent.length + 1;
    
    if (count >= 3) {
      return _ScoreResult(
        score: 0.9,
        reason: '$count payments to ${transaction.merchant} in 24 hours',
      );
    } else if (count == 2) {
      return _ScoreResult(
        score: 0.5,
        reason: 'Repeated payment to ${transaction.merchant} today',
      );
    }
    
    return _ScoreResult(score: 0.0);
  }

  /// Factor 4: Recurrence Anomaly Score
  /// Detects unexpected subscription patterns
  static _ScoreResult _scoreRecurrenceAnomaly({
    required Transaction transaction,
    required SpendingFingerprint fingerprint,
  }) {
    // Check if this is a subscription payment
    if (transaction.paymentMode != 'Subscription') {
      return _ScoreResult(score: 0.0);
    }
    
    // Check if this merchant is in known recurring costs
    final isKnownRecurring = fingerprint.fixedRecurringCosts.any(
      (cost) => cost.merchant.toLowerCase() == transaction.merchant.toLowerCase(),
    );
    
    if (isKnownRecurring) {
      // Known subscription, check amount deviation
      final knownCost = fingerprint.fixedRecurringCosts.firstWhere(
        (cost) => cost.merchant.toLowerCase() == transaction.merchant.toLowerCase(),
      );
      
      final deviation = (transaction.amount - knownCost.amount).abs() / knownCost.amount;
      
      if (deviation > 0.2) {
        // Amount changed by more than 20%
        return _ScoreResult(
          score: 0.7,
          reason: 'Subscription amount changed: ₹${knownCost.amount.toStringAsFixed(0)} → ₹${transaction.amount.toStringAsFixed(0)}',
        );
      }
      
      return _ScoreResult(score: 0.0);
    } else {
      // New subscription detected
      return _ScoreResult(
        score: 0.6,
        reason: 'New subscription detected: ${transaction.merchant}',
      );
    }
  }

  /// Map CRS to risk level (green, amber, red)
  /// Adjusted by personal risk tolerance band
  static String _mapCRSToRiskLevel(double crs, double riskToleranceBand) {
    // Adjust thresholds based on risk tolerance
    // Low tolerance (0.0 - 0.3): stricter thresholds
    // High tolerance (0.7 - 1.0): lenient thresholds
    
    final amberThreshold = 0.3 + (riskToleranceBand * 0.2); // 0.3 - 0.5
    final redThreshold = 0.6 + (riskToleranceBand * 0.2);   // 0.6 - 0.8
    
    if (crs >= redThreshold) {
      return 'red';
    } else if (crs >= amberThreshold) {
      return 'amber';
    } else {
      return 'green';
    }
  }

  /// Batch score multiple transactions
  static List<Transaction> scoreBatch({
    required List<Transaction> transactions,
    required SpendingFingerprint fingerprint,
  }) {
    final scored = <Transaction>[];
    
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      
      // Get recent transactions before this one
      final recentTransactions = transactions.sublist(0, i);
      
      final scoredTransaction = scoreTransaction(
        transaction: transaction,
        fingerprint: fingerprint,
        recentTransactions: recentTransactions,
      );
      
      scored.add(scoredTransaction);
    }
    
    return scored;
  }
}

/// Internal score result helper
class _ScoreResult {
  final double score;
  final String? reason;
  
  _ScoreResult({required this.score, this.reason});
}
