/// Risk Alert Model
/// Phase 4: Actionable Insight Generation
/// Explainable alerts with reasons and suggested actions
class RiskAlert {
  final int? id;
  final int transactionId;
  final String alertType; // duplicate_payment, spending_spike, micro_transaction, subscription_trap
  final String riskLevel; // green, amber, red
  final String reason; // Explainable reason
  final String suggestedAction; // What the student should do
  final DateTime detectedAt;
  final bool isRead;
  final bool isDismissed;

  RiskAlert({
    this.id,
    required this.transactionId,
    required this.alertType,
    required this.riskLevel,
    required this.reason,
    required this.suggestedAction,
    required this.detectedAt,
    this.isRead = false,
    this.isDismissed = false,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'alertType': alertType,
      'riskLevel': riskLevel,
      'reason': reason,
      'suggestedAction': suggestedAction,
      'detectedAt': detectedAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'isDismissed': isDismissed ? 1 : 0,
    };
  }

  /// Create from Map
  factory RiskAlert.fromMap(Map<String, dynamic> map) {
    return RiskAlert(
      id: map['id'],
      transactionId: map['transactionId'],
      alertType: map['alertType'],
      riskLevel: map['riskLevel'],
      reason: map['reason'],
      suggestedAction: map['suggestedAction'],
      detectedAt: DateTime.parse(map['detectedAt']),
      isRead: map['isRead'] == 1,
      isDismissed: map['isDismissed'] == 1,
    );
  }

  /// Copy with modifications
  RiskAlert copyWith({
    int? id,
    int? transactionId,
    String? alertType,
    String? riskLevel,
    String? reason,
    String? suggestedAction,
    DateTime? detectedAt,
    bool? isRead,
    bool? isDismissed,
  }) {
    return RiskAlert(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      alertType: alertType ?? this.alertType,
      riskLevel: riskLevel ?? this.riskLevel,
      reason: reason ?? this.reason,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      detectedAt: detectedAt ?? this.detectedAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  /// Get icon for alert type
  String get icon {
    switch (alertType) {
      case 'duplicate_payment':
        return '🔄';
      case 'spending_spike':
        return '📈';
      case 'micro_transaction':
        return '💸';
      case 'subscription_trap':
        return '🪤';
      default:
        return '⚠️';
    }
  }

  /// Get color for risk level
  String get colorHex {
    switch (riskLevel) {
      case 'red':
        return '#EF4444';
      case 'amber':
        return '#F59E0B';
      case 'green':
      default:
        return '#10B981';
    }
  }
}
