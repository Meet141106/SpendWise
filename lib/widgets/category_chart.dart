import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> categorySpending;

  const CategoryChart({
    super.key,
    required this.categorySpending,
  });

  @override
  Widget build(BuildContext context) {
    final total = categorySpending.values.fold<double>(0.0, (sum, val) => sum + val);
    
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _buildSections(total),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              pieTouchData: PieTouchData(enabled: true),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ..._buildLegend(context),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    return categorySpending.entries.map((entry) {
      final category = ExpenseCategory.getByName(entry.key);
      final percentage = (entry.value / total * 100);
      
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: Color(int.parse('0xFF${category.colorHex.substring(1)}')),
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend(BuildContext context) {
    return categorySpending.entries.map((entry) {
      final category = ExpenseCategory.getByName(entry.key);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${category.colorHex.substring(1)}')),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Text(category.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              '₹${entry.value.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }).toList();
  }
}
