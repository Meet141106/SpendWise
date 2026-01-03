import '../models/transaction.dart';
import '../models/spending_fingerprint.dart';
import '../models/category.dart';
import '../core/database/database_helper.dart';
import '../core/ssia/ssia_engine.dart';

/// Transaction Service
/// Handles all transaction-related business logic
class TransactionService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Add a new transaction
  Future<Transaction> addTransaction({
    required double amount,
    required String merchant,
    required DateTime timestamp,
    required String paymentMode,
    String? category,
    String? note,
  }) async {
    // Auto-detect category if not provided
    final detectedCategory = category ?? ExpenseCategory.detectCategory(merchant);

    // Get current fingerprint
    final fingerprint = await _db.getSpendingFingerprint();

    // Get existing transactions for context
    final existingTransactions = await _db.getAllTransactions();

    // Process through SSIA
    final result = await SSIAEngine.processTransaction(
      amount: amount,
      merchant: merchant,
      timestamp: timestamp,
      paymentMode: paymentMode,
      category: detectedCategory,
      note: note,
      fingerprint: fingerprint,
      existingTransactions: existingTransactions,
    );

    // Save transaction
    final transactionId = await _db.insertTransaction(result.transaction);
    final savedTransaction = result.transaction.copyWith(id: transactionId);

    // Update fingerprint
    await _db.updateSpendingFingerprint(result.updatedFingerprint);

    // Save alerts
    for (final alert in result.alerts) {
      await _db.insertRiskAlert(alert.copyWith(transactionId: transactionId));
    }

    return savedTransaction;
  }

  /// Get all transactions
  Future<List<Transaction>> getAllTransactions() async {
    return await _db.getAllTransactions();
  }

  /// Get transactions by filter
  Future<List<Transaction>> getFilteredTransactions({
    String? category,
    String? riskLevel,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (startDate != null && endDate != null) {
      return await _db.getTransactionsByDateRange(
        start: startDate,
        end: endDate,
      );
    } else if (category != null && category != 'all') {
      return await _db.getTransactionsByCategory(category);
    } else if (riskLevel != null && riskLevel != 'all') {
      return await _db.getTransactionsByRiskLevel(riskLevel);
    } else {
      return await _db.getAllTransactions();
    }
  }

  /// Update transaction category (user correction)
  /// This triggers fingerprint rebuild
  Future<void> updateTransactionCategory({
    required int transactionId,
    required String newCategory,
  }) async {
    // Get transaction
    final transactions = await _db.getAllTransactions();
    final transaction = transactions.firstWhere((t) => t.id == transactionId);

    // Update category
    final updated = transaction.copyWith(category: newCategory);
    await _db.updateTransaction(updated);

    // Rebuild fingerprint with corrected data
    await rebuildFingerprint();
  }

  /// Delete transaction
  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    
    // Rebuild fingerprint
    await rebuildFingerprint();
  }

  /// Rebuild fingerprint from all transactions
  /// Called when:
  /// - User corrects categories
  /// - Periodic recalibration
  Future<void> rebuildFingerprint() async {
    final transactions = await _db.getAllTransactions();
    
    final newFingerprint = await SSIAEngine.rebuildFingerprint(
      transactions: transactions,
    );
    
    await _db.updateSpendingFingerprint(newFingerprint);

    // Rescore all transactions
    final rescored = await SSIAEngine.rescoreAllTransactions(
      transactions: transactions,
      fingerprint: newFingerprint,
    );

    // Update transactions
    for (final transaction in rescored) {
      await _db.updateTransaction(transaction);
    }

    // Regenerate alerts
    await _regenerateAlerts(rescored, newFingerprint);
  }

  /// Regenerate all alerts
  Future<void> _regenerateAlerts(
    List<Transaction> transactions,
    SpendingFingerprint fingerprint,
  ) async {
    // Clear old alerts (optional - or mark as outdated)
    // For now, we'll just add new ones
    
    final alerts = await SSIAEngine.detectAnomalies(
      transactions: transactions,
      fingerprint: fingerprint,
    );

    await _db.batchInsertAlerts(alerts);
  }

  /// Get spending statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final monthlySpent = await _db.getTotalSpent(
      start: startOfMonth,
      end: now,
    );

    final weeklySpent = await _db.getTotalSpent(
      start: startOfWeek,
      end: now,
    );

    final categorySpending = await _db.getCategorySpending(
      start: startOfMonth,
      end: now,
    );

    final fingerprint = await _db.getSpendingFingerprint();
    final transactions = await _db.getAllTransactions();

    final insights = await SSIAEngine.generateInsights(
      transactions: transactions,
      fingerprint: fingerprint,
      currentBalance: null, // Can be added later
    );

    return {
      'monthlySpent': monthlySpent,
      'weeklySpent': weeklySpent,
      'categorySpending': categorySpending,
      'dailyBurnRate': insights['dailyBurnRate'],
      'daysRemaining': insights['daysRemaining'],
      'totalSubscriptions': insights['totalSubscriptions'],
      'canteenMealsEquivalent': insights['canteenMealsEquivalent'],
    };
  }

  /// Get spending fingerprint
  Future<SpendingFingerprint> getFingerprint() async {
    return await _db.getSpendingFingerprint();
  }
}
