import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String change;
  final Gradient gradient;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Flexible(
                  child: Text(
                    change,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 10,
                        ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9CA3AF),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
