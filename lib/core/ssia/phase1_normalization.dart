import '../../models/transaction.dart';
import '../../models/spending_fingerprint.dart';

/// SSIA Phase 1: Transaction Normalization
/// Converts raw expense data into a behavioral unit
class Phase1Normalization {
  /// Normalize a raw transaction
  /// 
  /// Input: amount, merchant, timestamp, payment mode
  /// Output: Normalized Transaction Vector with:
  /// - category
  /// - time_bucket (morning/afternoon/night)
  /// - spend_intensity (calculated later with PSF)
  /// - recurrence_flag
  static Transaction normalize({
    required double amount,
    required String merchant,
    required DateTime timestamp,
    required String paymentMode,
    String? category,
    String? note,
    required SpendingFingerprint fingerprint,
  }) {
    // Determine time bucket
    final timeBucket = _getTimeBucket(timestamp);
    
    // Calculate spend intensity (amount ÷ personal average)
    final spendIntensity = _calculateSpendIntensity(
      amount: amount,
      category: category ?? 'Miscellaneous',
      fingerprint: fingerprint,
    );
    
    // Check recurrence flag
    final recurrenceFlag = paymentMode == 'Subscription';
    
    return Transaction(
      amount: amount,
      merchant: merchant,
      timestamp: timestamp,
      paymentMode: paymentMode,
      category: category ?? 'Miscellaneous',
      note: note,
      timeBucket: timeBucket,
      spendIntensity: spendIntensity,
      recurrenceFlag: recurrenceFlag,
    );
  }

  /// Determine time bucket based on hour
  /// Morning: 5 AM - 12 PM
  /// Afternoon: 12 PM - 6 PM
  /// Night: 6 PM - 5 AM
  static String _getTimeBucket(DateTime timestamp) {
    final hour = timestamp.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 18) {
      return 'afternoon';
    } else {
      return 'night';
    }
  }

  /// Calculate spend intensity
  /// spend_intensity = amount ÷ personal category average
  /// 
  /// Interpretation:
  /// - 1.0 = exactly average
  /// - > 1.0 = above average (higher intensity)
  /// - < 1.0 = below average (lower intensity)
  static double _calculateSpendIntensity({
    required double amount,
    required String category,
    required SpendingFingerprint fingerprint,
  }) {
    final categoryAverage = fingerprint.getCategoryAverage(category);
    
    // If no history, intensity is 1.0 (neutral)
    if (categoryAverage == 0.0) {
      return 1.0;
    }
    
    return amount / categoryAverage;
  }

  /// Batch normalize multiple transactions
  static List<Transaction> normalizeBatch({
    required List<Map<String, dynamic>> rawTransactions,
    required SpendingFingerprint fingerprint,
  }) {
    return rawTransactions.map((raw) {
      return normalize(
        amount: raw['amount'],
        merchant: raw['merchant'],
        timestamp: raw['timestamp'],
        paymentMode: raw['paymentMode'],
        category: raw['category'],
        note: raw['note'],
        fingerprint: fingerprint,
      );
    }).toList();
  }
}
