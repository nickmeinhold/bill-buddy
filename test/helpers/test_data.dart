import 'package:bill_buddy/shared/models/bill_model.dart';
import 'package:bill_buddy/shared/models/budget_model.dart';
import 'package:bill_buddy/shared/models/subscription_model.dart';
import 'package:bill_buddy/shared/models/transaction_model.dart';

class TestData {
  // Subscriptions
  static SubscriptionModel get netflixSubscription => SubscriptionModel(
    id: 'sub_1',
    name: 'Netflix',
    amount: 15.99,
    frequency: SubscriptionFrequency.monthly,
    nextBillingDate: DateTime(2024, 2, 15),
    category: 'Entertainment',
    status: SubscriptionStatus.active,
    notes: 'Family plan',
  );

  static SubscriptionModel get weeklySubscription => SubscriptionModel(
    id: 'sub_2',
    name: 'Weekly Box',
    amount: 25.00,
    frequency: SubscriptionFrequency.weekly,
    nextBillingDate: DateTime(2024, 1, 22),
    category: 'Food & Dining',
  );

  static SubscriptionModel get yearlySubscription => SubscriptionModel(
    id: 'sub_3',
    name: 'Annual Software',
    amount: 120.00,
    frequency: SubscriptionFrequency.yearly,
    nextBillingDate: DateTime(2024, 12, 1),
    category: 'Productivity',
  );

  static SubscriptionModel get quarterlySubscription => SubscriptionModel(
    id: 'sub_4',
    name: 'Quarterly Service',
    amount: 90.00,
    frequency: SubscriptionFrequency.quarterly,
    nextBillingDate: DateTime(2024, 3, 1),
    category: 'Utilities',
  );

  // Bills
  static BillModel overdueBill(DateTime now) => BillModel(
    id: 'bill_1',
    name: 'Electricity',
    amount: 150.00,
    dueDate: now.subtract(const Duration(days: 5)),
    frequency: BillFrequency.monthly,
    isPaid: false,
    remindDaysBefore: 3,
    category: 'Utilities',
  );

  static BillModel dueSoonBill(DateTime now) => BillModel(
    id: 'bill_2',
    name: 'Internet',
    amount: 79.99,
    dueDate: now.add(const Duration(days: 2)),
    frequency: BillFrequency.monthly,
    isPaid: false,
    remindDaysBefore: 3,
    category: 'Utilities',
  );

  static BillModel futureBill(DateTime now) => BillModel(
    id: 'bill_3',
    name: 'Insurance',
    amount: 200.00,
    dueDate: now.add(const Duration(days: 30)),
    frequency: BillFrequency.monthly,
    isPaid: false,
    remindDaysBefore: 3,
    category: 'Insurance',
  );

  static BillModel paidBill(DateTime now) => BillModel(
    id: 'bill_4',
    name: 'Rent',
    amount: 1500.00,
    dueDate: now.subtract(const Duration(days: 1)),
    frequency: BillFrequency.monthly,
    isPaid: true,
    category: 'Housing',
  );

  // Budgets
  static BudgetModel get underBudget => BudgetModel(
    id: 'budget_1',
    category: 'Food & Dining',
    limit: 500.00,
    spent: 250.00,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2024, 1, 1),
  );

  static BudgetModel get nearLimitBudget => BudgetModel(
    id: 'budget_2',
    category: 'Entertainment',
    limit: 100.00,
    spent: 85.00,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2024, 1, 1),
  );

  static BudgetModel get overBudget => BudgetModel(
    id: 'budget_3',
    category: 'Shopping',
    limit: 200.00,
    spent: 250.00,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2024, 1, 1),
  );

  static BudgetModel get zeroBudget => BudgetModel(
    id: 'budget_4',
    category: 'Savings',
    limit: 0,
    spent: 0,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2024, 1, 1),
  );

  // Transactions
  static TransactionModel get expenseTransaction => TransactionModel(
    id: 'txn_1',
    amount: -45.99,
    date: DateTime(2024, 1, 15),
    merchantName: 'Grocery Store',
    category: 'Groceries',
  );

  static TransactionModel expenseWithDate(DateTime date) => TransactionModel(
    id: 'txn_1',
    amount: -45.99,
    date: date,
    merchantName: 'Grocery Store',
    category: 'Groceries',
  );

  static TransactionModel incomeWithDate(DateTime date) => TransactionModel(
    id: 'txn_2',
    amount: 2500.00,
    date: date,
    merchantName: 'Employer Inc',
    category: 'Income',
  );

  static TransactionModel get subscriptionTransaction => TransactionModel(
    id: 'txn_3',
    amount: -15.99,
    date: DateTime(2024, 1, 15),
    merchantName: 'Netflix',
    category: 'Entertainment',
    isSubscription: true,
  );
}
