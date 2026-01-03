import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/csv_import_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_expense_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TransactionService _transactionService = TransactionService();
  final CSVImportService _csvService = CSVImportService();
  
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  
  String _selectedCategory = 'all';
  String _selectedRiskLevel = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _transactionService.getAllTransactions();
      setState(() {
        _transactions = transactions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((t) {
      final categoryMatch = _selectedCategory == 'all' || t.category == _selectedCategory;
      final riskMatch = _selectedRiskLevel == 'all' || t.riskLevel == _selectedRiskLevel;
      return categoryMatch && riskMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryFilter(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRiskFilter(),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            return TransactionCard(
                              transaction: _filteredTransactions[index],
                              onTap: () => _showTransactionDetails(_filteredTransactions[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All Categories')),
        ...ExpenseCategory.all.map((cat) => DropdownMenuItem(
              value: cat.name,
              child: Text('${cat.icon} ${cat.name}'),
            )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildRiskFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRiskLevel,
      decoration: const InputDecoration(
        labelText: 'Risk Level',
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Levels')),
        DropdownMenuItem(value: 'green', child: Text('🟢 Green')),
        DropdownMenuItem(value: 'amber', child: Text('🟠 Amber')),
        DropdownMenuItem(value: 'red', child: Text('🔴 Red')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRiskLevel = value!;
          _applyFilters();
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No Expenses Yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense or import CSV',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const AddExpenseDialog(),
                  );
                  if (result == true) _loadTransactions();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _importCSV,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import CSV'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _importCSV() async {
    final result = await _csvService.importCSV();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      
      if (result.success) {
        _loadTransactions();
      }
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  ExpenseCategory.getByName(transaction.category).icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${transaction.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow('Category', transaction.category),
            _buildDetailRow('Payment Mode', transaction.paymentMode),
            _buildDetailRow('Time Bucket', transaction.timeBucket),
            _buildDetailRow('Risk Level', _getRiskLevelText(transaction.riskLevel)),
            if (transaction.riskReason != null)
              _buildDetailRow('Risk Reason', transaction.riskReason!),
            if (transaction.note != null)
              _buildDetailRow('Note', transaction.note!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  String _getRiskLevelText(String level) {
    switch (level) {
      case 'green':
        return '🟢 Normal';
      case 'amber':
        return '🟠 Unusual';
      case 'red':
        return '🔴 High Risk';
      default:
        return level;
    }
  }
}
