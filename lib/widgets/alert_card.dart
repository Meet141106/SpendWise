import 'package:flutter/material.dart';
import '../models/risk_alert.dart';

class AlertCard extends StatelessWidget {
  final RiskAlert alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    alert.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getAlertTitle(alert.alertType),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _buildRiskBadge(alert.riskLevel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.reason,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Color(0xFF667EEA),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.suggestedAction,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF667EEA),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    Color color;
    String label;
    
    switch (riskLevel) {
      case 'red':
        color = const Color(0xFFEF4444);
        label = 'High Risk';
        break;
      case 'amber':
        color = const Color(0xFFF59E0B);
        label = 'Unusual';
        break;
      case 'green':
      default:
        color = const Color(0xFF10B981);
        label = 'Normal';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getAlertTitle(String alertType) {
    switch (alertType) {
      case 'duplicate_payment':
        return 'Duplicate Payment Detected';
      case 'spending_spike':
        return 'Spending Spike';
      case 'micro_transaction':
        return 'Frequent Small Payments';
      case 'subscription_trap':
        return 'Subscription Alert';
      default:
        return 'Risk Alert';
    }
  }
}
