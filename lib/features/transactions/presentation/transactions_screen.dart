import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/account_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../accounts/domain/accounts_provider.dart';
import '../domain/transactions_provider.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final currentFilter = ref.watch(transactionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: TransactionFilter.values.map((filter) {
                final isSelected = filter == currentFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(transactionFilterProvider.notifier).state =
                          filter;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Transactions list
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentFilter == TransactionFilter.all
                              ? 'No transactions yet'
                              : 'No ${_filterLabel(currentFilter).toLowerCase()} found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a transaction',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    AccountModel? account;

                    // Try to find account if accounts loaded
                    if (tx.accountId != null && accountsAsync.hasValue) {
                      try {
                        account = accountsAsync.value!.firstWhere(
                          (a) => a.id == tx.accountId,
                        );
                      } catch (_) {}
                    }

                    return _TransactionCard(
                      transaction: tx,
                      account: account,
                      dateFormat: dateFormat,
                      onTap: () => _showTransactionForm(context, tx),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.income:
        return 'Income';
      case TransactionFilter.expenses:
        return 'Expenses';
      case TransactionFilter.subscriptions:
        return 'Subscriptions';
    }
  }

  void _showTransactionForm(
    BuildContext context, [
    TransactionModel? transaction,
  ]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final AccountModel? account;
  final DateFormat dateFormat;
  final VoidCallback? onTap;

  const _TransactionCard({
    required this.transaction,
    this.account,
    required this.dateFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.isExpense;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isExpense ? AppTheme.expenseColor : AppTheme.incomeColor)
                  .withValues(alpha: 0.1),
          child: Icon(
            transaction.isSubscription
                ? Icons.subscriptions
                : isExpense
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
          ),
        ),
        title: Text(transaction.merchantName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.category} • ${dateFormat.format(transaction.date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (account != null || transaction.accountId == null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 12,
                      color: account != null
                          ? Color(account!.color)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      account?.name ?? 'Unassigned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: account != null
                            ? Color(account!.color)
                            : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'}\$${transaction.absoluteAmount.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
