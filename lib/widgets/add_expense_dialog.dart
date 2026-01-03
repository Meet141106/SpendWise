import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../models/category.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();
  
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedCategory;
  String _selectedPaymentMode = 'UPI';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Expense',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Merchant
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant / Description',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter merchant name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Auto-detect'),
                    ),
                    ...ExpenseCategory.all.map((cat) => DropdownMenuItem(
                          value: cat.name,
                          child: Text('${cat.icon} ${cat.name}'),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),

                // Payment Mode
                DropdownButtonFormField<String>(
                  initialValue: _selectedPaymentMode,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Card', child: Text('Card')),
                    DropdownMenuItem(value: 'Subscription', child: Text('Subscription')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPaymentMode = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Date
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date & Time',
                    ),
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitExpense,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Expense'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _transactionService.addTransaction(
        amount: double.parse(_amountController.text),
        merchant: _merchantController.text,
        timestamp: _selectedDate,
        paymentMode: _selectedPaymentMode,
        category: _selectedCategory,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
