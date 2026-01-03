/// Transaction Model
/// Represents a single expense transaction with normalized data
class Transaction {
  final int? id;
  final double amount;
  final String merchant;
  final DateTime timestamp;
  final String paymentMode; // UPI, Cash, Card, Subscription
  final String category; // Food, Transport, Education, Subscriptions, Shopping, Miscellaneous
  final String? note;
  
  // Normalized fields (Phase 1 output)
  final String timeBucket; // morning, afternoon, night
  final double spendIntensity; // amount ÷ personal average
  final bool recurrenceFlag;
  
  // Risk scoring (Phase 3 output)
  final String riskLevel; // green, amber, red
  final double contextualRiskScore;
  final String? riskReason;
  
  Transaction({
    this.id,
    required this.amount,
    required this.merchant,
    required this.timestamp,
    required this.paymentMode,
    required this.category,
    this.note,
    required this.timeBucket,
    required this.spendIntensity,
    required this.recurrenceFlag,
    this.riskLevel = 'green',
    this.contextualRiskScore = 0.0,
    this.riskReason,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'timestamp': timestamp.toIso8601String(),
      'paymentMode': paymentMode,
      'category': category,
      'note': note,
      'timeBucket': timeBucket,
      'spendIntensity': spendIntensity,
      'recurrenceFlag': recurrenceFlag ? 1 : 0,
      'riskLevel': riskLevel,
      'contextualRiskScore': contextualRiskScore,
      'riskReason': riskReason,
    };
  }

  /// Create from Map (database retrieval)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      merchant: map['merchant'],
      timestamp: DateTime.parse(map['timestamp']),
      paymentMode: map['paymentMode'],
      category: map['category'],
      note: map['note'],
      timeBucket: map['timeBucket'],
      spendIntensity: map['spendIntensity'],
      recurrenceFlag: map['recurrenceFlag'] == 1,
      riskLevel: map['riskLevel'] ?? 'green',
      contextualRiskScore: map['contextualRiskScore'] ?? 0.0,
      riskReason: map['riskReason'],
    );
  }

  /// Copy with modifications
  Transaction copyWith({
    int? id,
    double? amount,
    String? merchant,
    DateTime? timestamp,
    String? paymentMode,
    String? category,
    String? note,
    String? timeBucket,
    double? spendIntensity,
    bool? recurrenceFlag,
    String? riskLevel,
    double? contextualRiskScore,
    String? riskReason,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      timestamp: timestamp ?? this.timestamp,
      paymentMode: paymentMode ?? this.paymentMode,
      category: category ?? this.category,
      note: note ?? this.note,
      timeBucket: timeBucket ?? this.timeBucket,
      spendIntensity: spendIntensity ?? this.spendIntensity,
      recurrenceFlag: recurrenceFlag ?? this.recurrenceFlag,
      riskLevel: riskLevel ?? this.riskLevel,
      contextualRiskScore: contextualRiskScore ?? this.contextualRiskScore,
      riskReason: riskReason ?? this.riskReason,
    );
  }
}
