import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/transaction.dart' as models;
import '../../models/risk_alert.dart';
import '../../models/spending_fingerprint.dart';

/// Database Helper - Offline-First Local Storage
/// Uses SQLite for all data persistence
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spendwise.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        merchant TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        paymentMode TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        timeBucket TEXT NOT NULL,
        spendIntensity REAL NOT NULL,
        recurrenceFlag INTEGER NOT NULL,
        riskLevel TEXT NOT NULL,
        contextualRiskScore REAL NOT NULL,
        riskReason TEXT
      )
    ''');

    // Risk alerts table
    await db.execute('''
      CREATE TABLE risk_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        alertType TEXT NOT NULL,
        riskLevel TEXT NOT NULL,
        reason TEXT NOT NULL,
        suggestedAction TEXT NOT NULL,
        detectedAt TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        isDismissed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (transactionId) REFERENCES transactions (id)
      )
    ''');

    // Spending fingerprint table (single row)
    await db.execute('''
      CREATE TABLE spending_fingerprint (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        data TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // Insert empty fingerprint
    await db.insert('spending_fingerprint', {
      'id': 1,
      'data': jsonEncode(SpendingFingerprint.empty().toMap()),
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  // ==================== TRANSACTIONS ====================

  /// Insert transaction
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  /// Get all transactions
  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final result = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Get transactions by date range
  Future<List<models.Transaction>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Get transactions by category
  Future<List<models.Transaction>> getTransactionsByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Get transactions by risk level
  Future<List<models.Transaction>> getTransactionsByRiskLevel(String riskLevel) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'riskLevel = ?',
      whereArgs: [riskLevel],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => models.Transaction.fromMap(map)).toList();
  }

  /// Update transaction
  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete transaction
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batch insert transactions
  Future<void> batchInsertTransactions(List<models.Transaction> transactions) async {
    final db = await database;
    final batch = db.batch();
    
    for (final transaction in transactions) {
      batch.insert('transactions', transaction.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  // ==================== RISK ALERTS ====================

  /// Insert risk alert
  Future<int> insertRiskAlert(RiskAlert alert) async {
    final db = await database;
    return await db.insert('risk_alerts', alert.toMap());
  }

  /// Get all risk alerts
  Future<List<RiskAlert>> getAllRiskAlerts() async {
    final db = await database;
    final result = await db.query(
      'risk_alerts',
      orderBy: 'detectedAt DESC',
    );
    return result.map((map) => RiskAlert.fromMap(map)).toList();
  }

  /// Get unread alerts
  Future<List<RiskAlert>> getUnreadAlerts() async {
    final db = await database;
    final result = await db.query(
      'risk_alerts',
      where: 'isRead = ? AND isDismissed = ?',
      whereArgs: [0, 0],
      orderBy: 'detectedAt DESC',
    );
    return result.map((map) => RiskAlert.fromMap(map)).toList();
  }

  /// Get alerts by risk level
  Future<List<RiskAlert>> getAlertsByRiskLevel(String riskLevel) async {
    final db = await database;
    final result = await db.query(
      'risk_alerts',
      where: 'riskLevel = ? AND isDismissed = ?',
      whereArgs: [riskLevel, 0],
      orderBy: 'detectedAt DESC',
    );
    return result.map((map) => RiskAlert.fromMap(map)).toList();
  }

  /// Mark alert as read
  Future<int> markAlertAsRead(int id) async {
    final db = await database;
    return await db.update(
      'risk_alerts',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Dismiss alert
  Future<int> dismissAlert(int id) async {
    final db = await database;
    return await db.update(
      'risk_alerts',
      {'isDismissed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Batch insert alerts
  Future<void> batchInsertAlerts(List<RiskAlert> alerts) async {
    final db = await database;
    final batch = db.batch();
    
    for (final alert in alerts) {
      batch.insert('risk_alerts', alert.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  // ==================== SPENDING FINGERPRINT ====================

  /// Get spending fingerprint
  Future<SpendingFingerprint> getSpendingFingerprint() async {
    final db = await database;
    final result = await db.query(
      'spending_fingerprint',
      where: 'id = ?',
      whereArgs: [1],
    );
    
    if (result.isEmpty) {
      return SpendingFingerprint.empty();
    }
    
    final data = jsonDecode(result.first['data'] as String);
    return SpendingFingerprint.fromMap(data);
  }

  /// Update spending fingerprint
  Future<int> updateSpendingFingerprint(SpendingFingerprint fingerprint) async {
    final db = await database;
    return await db.update(
      'spending_fingerprint',
      {
        'data': jsonEncode(fingerprint.toMap()),
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ==================== STATISTICS ====================

  /// Get total spent in date range
  Future<double> getTotalSpent({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE timestamp BETWEEN ? AND ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    return (result.first['total'] as double?) ?? 0.0;
  }

  /// Get category-wise spending
  Future<Map<String, double>> getCategorySpending({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE timestamp BETWEEN ? AND ?
      GROUP BY category
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    final categorySpending = <String, double>{};
    for (final row in result) {
      categorySpending[row['category'] as String] = row['total'] as double;
    }
    
    return categorySpending;
  }

  /// Get alert count by risk level
  Future<Map<String, int>> getAlertCountByRiskLevel() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT riskLevel, COUNT(*) as count
      FROM risk_alerts
      WHERE isDismissed = 0
      GROUP BY riskLevel
    ''');
    
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['riskLevel'] as String] = row['count'] as int;
    }
    
    return counts;
  }

  // ==================== UTILITY ====================

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('risk_alerts');
    await db.update(
      'spending_fingerprint',
      {
        'data': jsonEncode(SpendingFingerprint.empty().toMap()),
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
