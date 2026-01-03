import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/risk_alert.dart';
import '../widgets/alert_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<RiskAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);

    try {
      final alerts = await _db.getAllRiskAlerts();
      setState(() {
        _alerts = alerts.where((a) => !a.isDismissed).toList();
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
      onRefresh: _loadAlerts,
      child: _alerts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                return AlertCard(
                  alert: _alerts[index],
                  onDismiss: () => _dismissAlert(_alerts[index]),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'All Clear!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'No risk alerts detected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _dismissAlert(RiskAlert alert) async {
    await _db.dismissAlert(alert.id!);
    _loadAlerts();
  }
}
