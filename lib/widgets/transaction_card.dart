import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategory.getByName(transaction.category);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${category.colorHex.substring(1)}')).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          transaction.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Text(' • '),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(transaction.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Amount and Risk
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${transaction.amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  _buildRiskBadge(transaction.riskLevel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String riskLevel) {
    Color color;
    String emoji;
    
    switch (riskLevel) {
      case 'red':
        color = const Color(0xFFEF4444);
        emoji = '🔴';
        break;
      case 'amber':
        color = const Color(0xFFF59E0B);
        emoji = '🟠';
        break;
      case 'green':
      default:
        color = const Color(0xFF10B981);
        emoji = '🟢';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
