/// Personal Spending Fingerprint (PSF)
/// Phase 2: Student Behavior Profiling
/// Each student's unique spending baseline - stored locally
class SpendingFingerprint {
  // Category-wise averages
  final Map<String, double> categoryAverages;
  
  // Typical spending hours (hour -> frequency)
  final Map<int, int> typicalSpendingHours;
  
  // Weekly burn rate (₹/week)
  final double weeklyBurnRate;
  
  // Fixed recurring costs
  final List<RecurringCost> fixedRecurringCosts;
  
  // Personal risk tolerance band (0.0 - 1.0)
  final double riskToleranceBand;
  
  // Total transactions analyzed
  final int totalTransactions;
  
  // Last updated timestamp
  final DateTime lastUpdated;

  SpendingFingerprint({
    required this.categoryAverages,
    required this.typicalSpendingHours,
    required this.weeklyBurnRate,
    required this.fixedRecurringCosts,
    this.riskToleranceBand = 0.5,
    required this.totalTransactions,
    required this.lastUpdated,
  });

  /// Get average spend for a category
  double getCategoryAverage(String category) {
    return categoryAverages[category] ?? 0.0;
  }

  /// Check if hour is typical for spending
  bool isTypicalSpendingHour(int hour) {
    final frequency = typicalSpendingHours[hour] ?? 0;
    final avgFrequency = typicalSpendingHours.values.isEmpty 
        ? 0 
        : typicalSpendingHours.values.reduce((a, b) => a + b) / typicalSpendingHours.length;
    return frequency >= avgFrequency * 0.5; // At least 50% of average
  }

  /// Calculate daily burn rate
  double get dailyBurnRate => weeklyBurnRate / 7;

  /// Get total fixed monthly costs
  double get totalFixedMonthlyCosts {
    return fixedRecurringCosts
        .where((cost) => cost.frequency == 'monthly')
        .fold(0.0, (sum, cost) => sum + cost.amount);
  }

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'categoryAverages': categoryAverages,
      'typicalSpendingHours': typicalSpendingHours.map((k, v) => MapEntry(k.toString(), v)),
      'weeklyBurnRate': weeklyBurnRate,
      'fixedRecurringCosts': fixedRecurringCosts.map((c) => c.toMap()).toList(),
      'riskToleranceBand': riskToleranceBand,
      'totalTransactions': totalTransactions,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from Map
  factory SpendingFingerprint.fromMap(Map<String, dynamic> map) {
    return SpendingFingerprint(
      categoryAverages: Map<String, double>.from(map['categoryAverages'] ?? {}),
      typicalSpendingHours: (map['typicalSpendingHours'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(int.parse(k), v as int)) ?? {},
      weeklyBurnRate: map['weeklyBurnRate'] ?? 0.0,
      fixedRecurringCosts: (map['fixedRecurringCosts'] as List<dynamic>?)
          ?.map((c) => RecurringCost.fromMap(c))
          .toList() ?? [],
      riskToleranceBand: map['riskToleranceBand'] ?? 0.5,
      totalTransactions: map['totalTransactions'] ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  /// Create empty fingerprint for new users
  factory SpendingFingerprint.empty() {
    return SpendingFingerprint(
      categoryAverages: {},
      typicalSpendingHours: {},
      weeklyBurnRate: 0.0,
      fixedRecurringCosts: [],
      riskToleranceBand: 0.5,
      totalTransactions: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Recurring Cost Model
class RecurringCost {
  final String merchant;
  final double amount;
  final String frequency; // daily, weekly, monthly
  final DateTime lastDetected;

  RecurringCost({
    required this.merchant,
    required this.amount,
    required this.frequency,
    required this.lastDetected,
  });

  Map<String, dynamic> toMap() {
    return {
      'merchant': merchant,
      'amount': amount,
      'frequency': frequency,
      'lastDetected': lastDetected.toIso8601String(),
    };
  }

  factory RecurringCost.fromMap(Map<String, dynamic> map) {
    return RecurringCost(
      merchant: map['merchant'],
      amount: map['amount'],
      frequency: map['frequency'],
      lastDetected: DateTime.parse(map['lastDetected']),
    );
  }
}
