import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../models/spending_fingerprint.dart';
import '../models/category.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final TransactionService _transactionService = TransactionService();
  
  bool _isLoading = true;
  SpendingFingerprint? _fingerprint;
  Map<String, dynamic>? _insights;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      final fingerprint = await _transactionService.getFingerprint();
      final stats = await _transactionService.getStatistics();
      
      setState(() {
        _fingerprint = fingerprint;
        _insights = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInsights,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Insights',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Understand your financial behavior',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Spending Fingerprint
            _buildFingerprintCard(),
            const SizedBox(height: 16),

            // Burn Rate Indicator
            _buildBurnRateCard(),
            const SizedBox(height: 16),

            // Subscription Impact
            _buildSubscriptionCard(),
            const SizedBox(height: 16),

            // Category Averages
            _buildCategoryAveragesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Spending Fingerprint',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildFingerprintRow('Total Transactions', _fingerprint!.totalTransactions.toString()),
            _buildFingerprintRow('Weekly Burn Rate', '₹${_fingerprint!.weeklyBurnRate.toStringAsFixed(0)}'),
            _buildFingerprintRow('Daily Average', '₹${_fingerprint!.dailyBurnRate.toStringAsFixed(0)}'),
            _buildFingerprintRow('Risk Tolerance', _getRiskToleranceText(_fingerprint!.riskToleranceBand)),
          ],
        ),
      ),
    );
  }

  Widget _buildBurnRateCard() {
    final daysRemaining = _insights?['daysRemaining'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  'Burn Rate Indicator',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (daysRemaining != null)
              Text(
                'At this pace, your money lasts $daysRemaining days',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else
              Text(
                'Add more transactions to calculate',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final totalSubs = _insights?['totalSubscriptions'] ?? 0.0;
    final meals = _insights?['canteenMealsEquivalent'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔄', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  'Subscription Cost Impact',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalSubs > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${totalSubs.toStringAsFixed(0)}/month in subscriptions',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '≈ $meals canteen meals',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Text(
                'No subscriptions detected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAveragesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Averages',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._fingerprint!.categoryAverages.entries.map((entry) {
              final category = ExpenseCategory.getByName(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(category.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  String _getRiskToleranceText(double tolerance) {
    if (tolerance < 0.3) return 'Low (Conservative)';
    if (tolerance < 0.7) return 'Medium (Balanced)';
    return 'High (Flexible)';
  }
}
