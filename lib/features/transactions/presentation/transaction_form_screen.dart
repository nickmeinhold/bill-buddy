import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../accounts/domain/accounts_provider.dart';
import '../domain/transactions_provider.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String _category;
  late DateTime _date;
  late bool _isExpense;
  late bool _isSubscription;
  String? _accountId;

  bool _isLoading = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _merchantController = TextEditingController(text: tx?.merchantName ?? '');
    _amountController = TextEditingController(
      text: tx?.absoluteAmount.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _category = tx?.category ?? AppConstants.defaultCategories.first;
    _date = tx?.date ?? DateTime.now();
    _isExpense = tx?.isExpense ?? true;
    _isSubscription = tx?.isSubscription ?? false;
    _accountId = tx?.accountId;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      final transaction = TransactionModel(
        id: widget.transaction?.id ?? const Uuid().v4(),
        merchantName: _merchantController.text.trim(),
        amount: _isExpense ? -amount.abs() : amount.abs(),
        date: _date,
        category: _category,
        isSubscription: _isSubscription,
        accountId: _accountId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final service = ref.read(transactionServiceProvider);
      if (_isEditing) {
        await service.updateTransaction(transaction);
      } else {
        await service.addTransaction(transaction);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete "${_merchantController.text}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(transactionServiceProvider)
          .deleteTransaction(widget.transaction!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction type toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (selected) {
                setState(() => _isExpense = selected.first);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _merchantController,
              decoration: InputDecoration(
                labelText: _isExpense ? 'Merchant / Description' : 'Source',
                hintText: _isExpense
                    ? 'e.g., Amazon, Starbucks'
                    : 'e.g., Salary, Freelance',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Account Selector
            accountsAsync.when(
              data: (accounts) {
                if (accounts.isEmpty) return const SizedBox.shrink();

                // If account ID is null and not editing, default to first account
                if (_accountId == null && !_isEditing && accounts.isNotEmpty) {
                  // Initializing in build is tricky, usually done in initState or effect.
                  // But since accounts are async, we can just select the first one if current is null.
                  // However, for proper state management, let's just let the user pick or show "Select Account"
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _accountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    hint: const Text('Select Account'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                color: Color(acc.color),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(acc.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() => _accountId = value);
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                DateFormat.yMMMd().format(_date),
                style: theme.textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.defaultCategories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Subscription payment'),
              subtitle: const Text('Mark as a recurring subscription'),
              value: _isSubscription,
              onChanged: (value) {
                setState(() => _isSubscription = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional details...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
