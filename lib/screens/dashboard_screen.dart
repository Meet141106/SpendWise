import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../core/database/database_helper.dart';
import '../models/risk_alert.dart';
import 'expenses_screen.dart';
import 'insights_screen.dart';
import 'alerts_screen.dart';
import '../widgets/metric_card.dart';
import '../widgets/category_chart.dart';
import '../widgets/alert_card.dart';
import '../widgets/add_expense_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TransactionService _transactionService = TransactionService();
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  // Dashboard data
  double _totalSpent = 0.0;
  double _burnRate = 0.0;
  double _safeToSpend = 0.0;
  int _alertCount = 0;
  Map<String, double> _categorySpending = {};
  List<RiskAlert> _recentAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _transactionService.getStatistics();
      final alerts = await _db.getUnreadAlerts();
      
      setState(() {
        _totalSpent = stats['monthlySpent'] ?? 0.0;
        _burnRate = stats['dailyBurnRate'] ?? 0.0;
        _categorySpending = stats['categorySpending'] ?? {};
        _alertCount = alerts.length;
        _recentAlerts = alerts.take(3).toList();
        
        // Calculate safe to spend (mock - can be enhanced)
        _safeToSpend = 5000 - _totalSpent; // Assuming ₹5000 budget
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboard(),
      const ExpensesScreen(),
      const InsightsScreen(),
      const AlertsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('💡', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text('SpendWise'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_rounded),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExpenseDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Financial Overview',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your spending intelligence at a glance',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Key Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                MetricCard(
                  icon: '💰',
                  label: 'Total Spent (This Month)',
                  value: '₹${_totalSpent.toStringAsFixed(0)}',
                  change: _totalSpent > 0 ? '+${(_totalSpent / 5000 * 100).toStringAsFixed(0)}%' : '—',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
                MetricCard(
                  icon: '⚡',
                  label: 'Burn Rate',
                  value: '₹${_burnRate.toStringAsFixed(0)}/day',
                  change: 'Daily average',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                  ),
                ),
                MetricCard(
                  icon: '🛡️',
                  label: 'Safe to Spend',
                  value: '₹${_safeToSpend.toStringAsFixed(0)}',
                  change: 'After fixed costs',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  ),
                ),
                MetricCard(
                  icon: '⚠️',
                  label: 'Risk Alerts',
                  value: _alertCount.toString(),
                  change: 'Flagged transactions',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Category Breakdown
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _categorySpending.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            const Text('📊', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first expense to see insights',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      )
                    : CategoryChart(categorySpending: _categorySpending),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Alerts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (_recentAlerts.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedIndex = 3),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentAlerts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'All Clear!',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No risk alerts detected',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._recentAlerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AlertCard(
                      alert: alert,
                      onTap: () => setState(() => _selectedIndex = 3),
                    ),
                  )),
            const SizedBox(height: 100), // FAB padding
          ],
        ),
      ),
    );
  }

  Future<void> _showAddExpenseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );

    if (result == true) {
      _loadDashboardData();
    }
  }
}
