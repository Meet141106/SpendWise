import '../../models/transaction.dart';
import '../../models/spending_fingerprint.dart';
import '../../models/risk_alert.dart';
import 'phase1_normalization.dart';
import 'phase2_profiling.dart';
import 'phase3_risk_scoring.dart';
import 'phase4_insights.dart';

/// SSIA Engine - Student Spending Intelligence Algorithm
/// 
/// Main orchestrator for all 4 phases:
/// - Phase 1: Transaction Normalization
/// - Phase 2: Student Behavior Profiling
/// - Phase 3: Contextual Risk Scoring
/// - Phase 4: Actionable Insight Generation
/// 
/// This is the CORE INNOVATION - a custom, explainable algorithm
/// designed specifically for student spending behavior analysis.
class SSIAEngine {
  /// Process a new transaction through all 4 SSIA phases
  /// 
  /// Returns: Fully processed transaction with risk scoring
  static Future<SSIAResult> processTransaction({
    required double amount,
    required String merchant,
    required DateTime timestamp,
    required String paymentMode,
    String? category,
    String? note,
    required SpendingFingerprint fingerprint,
    required List<Transaction> existingTransactions,
  }) async {
    // PHASE 1: Normalize transaction
    final normalized = Phase1Normalization.normalize(
      amount: amount,
      merchant: merchant,
      timestamp: timestamp,
      paymentMode: paymentMode,
      category: category,
      note: note,
      fingerprint: fingerprint,
    );

    // PHASE 3: Score transaction risk
    final scored = Phase3RiskScoring.scoreTransaction(
      transaction: normalized,
      fingerprint: fingerprint,
      recentTransactions: existingTransactions,
    );

    // PHASE 2: Update fingerprint with new transaction
    final updatedFingerprint = Phase2Profiling.updateWithNewTransaction(
      fingerprint: fingerprint,
      transaction: scored,
    );

    // PHASE 4: Generate alerts if needed
    final alerts = Phase4Insights.generateAlerts(
      transactions: [scored],
      fingerprint: updatedFingerprint,
    );

    return SSIAResult(
      transaction: scored,
      updatedFingerprint: updatedFingerprint,
      alerts: alerts,
    );
  }

  /// Rebuild entire fingerprint from scratch
  /// Use this when:
  /// - First time setup
  /// - User corrects categories
  /// - Periodic recalibration
  static Future<SpendingFingerprint> rebuildFingerprint({
    required List<Transaction> transactions,
  }) async {
    return Phase2Profiling.buildFingerprint(
      transactions: transactions,
    );
  }

  /// Rescore all transactions with updated fingerprint
  /// Use this after fingerprint rebuild
  static Future<List<Transaction>> rescoreAllTransactions({
    required List<Transaction> transactions,
    required SpendingFingerprint fingerprint,
  }) async {
    return Phase3RiskScoring.scoreBatch(
      transactions: transactions,
      fingerprint: fingerprint,
    );
  }

  /// Generate comprehensive insights summary
  static Future<Map<String, dynamic>> generateInsights({
    required List<Transaction> transactions,
    required SpendingFingerprint fingerprint,
    double? currentBalance,
  }) async {
    return Phase4Insights.generateInsightsSummary(
      transactions: transactions,
      fingerprint: fingerprint,
      currentBalance: currentBalance,
    );
  }

  /// Detect all fraud and anomalies
  static Future<List<RiskAlert>> detectAnomalies({
    required List<Transaction> transactions,
    required SpendingFingerprint fingerprint,
  }) async {
    return Phase4Insights.generateAlerts(
      transactions: transactions,
      fingerprint: fingerprint,
    );
  }

  /// Batch import and process multiple transactions
  /// Used for CSV import
  static Future<BatchProcessResult> batchProcess({
    required List<Map<String, dynamic>> rawTransactions,
    required SpendingFingerprint fingerprint,
  }) async {
    final processedTransactions = <Transaction>[];
    var currentFingerprint = fingerprint;

    // Process each transaction sequentially
    for (final raw in rawTransactions) {
      final result = await processTransaction(
        amount: raw['amount'],
        merchant: raw['merchant'],
        timestamp: raw['timestamp'],
        paymentMode: raw['paymentMode'],
        category: raw['category'],
        note: raw['note'],
        fingerprint: currentFingerprint,
        existingTransactions: processedTransactions,
      );

      processedTransactions.add(result.transaction);
      currentFingerprint = result.updatedFingerprint;
    }

    // Generate all alerts
    final allAlerts = await detectAnomalies(
      transactions: processedTransactions,
      fingerprint: currentFingerprint,
    );

    return BatchProcessResult(
      transactions: processedTransactions,
      finalFingerprint: currentFingerprint,
      alerts: allAlerts,
    );
  }
}

/// SSIA Processing Result
class SSIAResult {
  final Transaction transaction;
  final SpendingFingerprint updatedFingerprint;
  final List<RiskAlert> alerts;

  SSIAResult({
    required this.transaction,
    required this.updatedFingerprint,
    required this.alerts,
  });
}

/// Batch Processing Result
class BatchProcessResult {
  final List<Transaction> transactions;
  final SpendingFingerprint finalFingerprint;
  final List<RiskAlert> alerts;

  BatchProcessResult({
    required this.transactions,
    required this.finalFingerprint,
    required this.alerts,
  });
}
