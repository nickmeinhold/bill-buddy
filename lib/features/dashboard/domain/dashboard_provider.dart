import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/models.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';
import '../../bills/domain/bills_provider.dart';
import '../../budgets/domain/budgets_provider.dart';
import '../../transactions/domain/transactions_provider.dart';

class DashboardData {
  final double monthlySpending;
  final double monthlyBudget;
  final int activeSubscriptionCount;
  final double monthlySubscriptionCost;
  final int billsDueThisWeek;
  final List<TransactionModel> recentTransactions;
  final List<BudgetModel> topBudgets;

  const DashboardData({
    required this.monthlySpending,
    required this.monthlyBudget,
    required this.activeSubscriptionCount,
    required this.monthlySubscriptionCost,
    required this.billsDueThisWeek,
    required this.recentTransactions,
    required this.topBudgets,
  });

  double get spendingProgress =>
      monthlyBudget > 0 ? (monthlySpending / monthlyBudget).clamp(0, 1) : 0;
}

final dashboardDataProvider = Provider.autoDispose<AsyncValue<DashboardData>>((ref) {
  final subscriptionsAsync = ref.watch(subscriptionsProvider);
  final billsAsync = ref.watch(billsProvider);
  final budgetsAsync = ref.watch(budgetsProvider);
  final transactionsAsync = ref.watch(transactionsProvider);

  // If any are loading, show loading
  if (subscriptionsAsync.isLoading ||
      billsAsync.isLoading ||
      budgetsAsync.isLoading ||
      transactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // If any have errors, show first error
  if (subscriptionsAsync.hasError) {
    return AsyncValue.error(
        subscriptionsAsync.error!, subscriptionsAsync.stackTrace!);
  }
  if (billsAsync.hasError) {
    return AsyncValue.error(billsAsync.error!, billsAsync.stackTrace!);
  }
  if (budgetsAsync.hasError) {
    return AsyncValue.error(budgetsAsync.error!, budgetsAsync.stackTrace!);
  }
  if (transactionsAsync.hasError) {
    return AsyncValue.error(
        transactionsAsync.error!, transactionsAsync.stackTrace!);
  }

  final subscriptions = subscriptionsAsync.value ?? [];
  final bills = billsAsync.value ?? [];
  final budgets = budgetsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  // Calculate monthly spending from transactions this month
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final monthlyExpenses = transactions
      .where((t) => t.isExpense && t.date.isAfter(startOfMonth))
      .fold<double>(0, (sum, t) => sum + t.absoluteAmount);

  // Calculate total budget limit
  final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.limit);

  // Active subscriptions
  final activeSubscriptions = subscriptions
      .where((s) => s.status == SubscriptionStatus.active)
      .toList();
  final monthlySubscriptionCost =
      activeSubscriptions.fold<double>(0, (sum, s) => sum + s.monthlyAmount);

  // Bills due this week
  final endOfWeek = now.add(const Duration(days: 7));
  final billsDueThisWeek = bills
      .where((b) =>
          !b.isPaid &&
          b.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
          b.dueDate.isBefore(endOfWeek))
      .length;

  // Recent transactions (last 5)
  final recentTransactions = transactions.take(5).toList();

  // Top 3 budgets by percentage used
  final sortedBudgets = [...budgets]
    ..sort((a, b) => b.percentUsed.compareTo(a.percentUsed));
  final topBudgets = sortedBudgets.take(3).toList();

  return AsyncValue.data(DashboardData(
    monthlySpending: monthlyExpenses,
    monthlyBudget: totalBudget,
    activeSubscriptionCount: activeSubscriptions.length,
    monthlySubscriptionCost: monthlySubscriptionCost,
    billsDueThisWeek: billsDueThisWeek,
    recentTransactions: recentTransactions,
    topBudgets: topBudgets,
  ));
});
