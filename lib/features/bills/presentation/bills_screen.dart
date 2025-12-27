import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../domain/bills_provider.dart';
import 'bill_form_screen.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final billsAsync = ref.watch(billsProvider);

    return billsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (bills) {
        final overdueBills = bills.where((b) => b.isOverdue).toList();
        final upcomingBills =
            bills.where((b) => !b.isOverdue && !b.isPaid).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final paidBills = bills.where((b) => b.isPaid).toList();

        final totalDue = upcomingBills.fold<double>(
          0,
          (sum, b) => sum + b.amount,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bills'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () {},
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showBillForm(context),
            child: const Icon(Icons.add),
          ),
          body: bills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bills yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first bill',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upcoming Bills',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${totalDue.toStringAsFixed(2)}',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '${upcomingBills.length} bills upcoming',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.billColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.event_note,
                                  color: AppTheme.billColor,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Overdue section
                      if (overdueBills.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.expenseColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Overdue',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.expenseColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...overdueBills.map(
                          (bill) => _BillCard(
                            bill: bill,
                            onTap: () => _showBillForm(context, bill),
                            onTogglePaid: () => _togglePaid(ref, bill),
                          ),
                        ),
                      ],
                      // Upcoming section
                      if (upcomingBills.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Upcoming',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...upcomingBills.map(
                          (bill) => _BillCard(
                            bill: bill,
                            onTap: () => _showBillForm(context, bill),
                            onTogglePaid: () => _togglePaid(ref, bill),
                          ),
                        ),
                      ],
                      // Paid section
                      if (paidBills.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Paid',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.incomeColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...paidBills.map(
                          (bill) => _BillCard(
                            bill: bill,
                            onTap: () => _showBillForm(context, bill),
                            onTogglePaid: () => _togglePaid(ref, bill),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showBillForm(BuildContext context, [BillModel? bill]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => BillFormScreen(bill: bill)));
  }

  void _togglePaid(WidgetRef ref, BillModel bill) {
    final service = ref.read(billServiceProvider);
    if (bill.isPaid) {
      service.markAsUnpaid(bill);
    } else {
      service.markAsPaid(bill);
    }
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePaid;

  const _BillCard({required this.bill, this.onTap, this.onTogglePaid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (bill.isPaid) {
      statusColor = AppTheme.incomeColor;
      statusText = 'Paid';
      statusIcon = Icons.check_circle;
    } else if (bill.isOverdue) {
      statusColor = AppTheme.expenseColor;
      statusText = '${bill.daysUntilDue.abs()} days overdue';
      statusIcon = Icons.warning_amber_rounded;
    } else if (bill.isDueSoon) {
      statusColor = AppTheme.warningColor;
      statusText = 'Due in ${bill.daysUntilDue} days';
      statusIcon = Icons.schedule;
    } else {
      statusColor = theme.colorScheme.primary;
      statusText = 'Due ${dateFormat.format(bill.dueDate)}';
      statusIcon = Icons.event;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          bill.name,
          style: bill.isPaid
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: Row(
          children: [
            Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
            ),
            if (bill.category != null) ...[
              Text(
                ' • ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                bill.category!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${bill.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                color: bill.isPaid ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                bill.isPaid ? Icons.check_circle : Icons.check_circle_outline,
                color: bill.isPaid ? AppTheme.incomeColor : null,
              ),
              onPressed: onTogglePaid,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
