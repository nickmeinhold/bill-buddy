import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/budget_model.dart';
import '../domain/budgets_provider.dart';
import 'budget_form_screen.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetsAsync = ref.watch(budgetsProvider);
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return budgetsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (budgets) {
        final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.limit);
        final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spent);
        final remaining = totalBudget - totalSpent;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Budgets'),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () {},
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showBudgetForm(context),
            child: const Icon(Icons.add),
          ),
          body: budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No budgets yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first budget',
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
                      // Overview card with pie chart
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentMonth,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '\$${totalSpent.toStringAsFixed(0)}',
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'of \$${totalBudget.toStringAsFixed(0)} budget',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 30,
                                        sections: [
                                          PieChartSectionData(
                                            value: totalSpent,
                                            color: AppTheme.expenseColor,
                                            radius: 20,
                                            showTitle: false,
                                          ),
                                          PieChartSectionData(
                                            value: remaining > 0 ? remaining : 0,
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            radius: 20,
                                            showTitle: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    context,
                                    label: 'Remaining',
                                    value: '\$${remaining.abs().toStringAsFixed(0)}',
                                    color: remaining >= 0
                                        ? AppTheme.incomeColor
                                        : AppTheme.expenseColor,
                                  ),
                                  _buildStatItem(
                                    context,
                                    label: 'Categories',
                                    value: '${budgets.length}',
                                    color: theme.colorScheme.primary,
                                  ),
                                  _buildStatItem(
                                    context,
                                    label: 'Over Budget',
                                    value: '${budgets.where((b) => b.isOverBudget).length}',
                                    color: AppTheme.expenseColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Budget Categories',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Budget items
                      ...budgets.map((budget) => _BudgetCard(
                            budget: budget,
                            onTap: () => _showBudgetForm(context, budget),
                          )),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showBudgetForm(BuildContext context, [BudgetModel? budget]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BudgetFormScreen(budget: budget),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback? onTap;

  const _BudgetCard({required this.budget, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = budget.isOverBudget
        ? AppTheme.expenseColor
        : budget.isNearLimit
            ? AppTheme.warningColor
            : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.category,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (budget.isOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Over budget',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.expenseColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${budget.spent.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${budget.limit.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (budget.percentUsed / 100).clamp(0, 1),
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${budget.remaining.abs().toStringAsFixed(0)} ${budget.isOverBudget ? 'over' : 'remaining'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
