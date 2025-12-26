import 'package:equatable/equatable.dart';

enum BudgetPeriod { weekly, monthly }

class BudgetModel extends Equatable {
  final String id;
  final String category;
  final double limit;
  final double spent;
  final BudgetPeriod period;
  final DateTime startDate;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.limit,
    this.spent = 0,
    this.period = BudgetPeriod.monthly,
    required this.startDate,
  });

  double get remaining => limit - spent;
  double get percentUsed => limit > 0 ? (spent / limit * 100).clamp(0, 100) : 0;
  bool get isOverBudget => spent > limit;
  bool get isNearLimit => percentUsed >= 80 && percentUsed < 100;

  factory BudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return BudgetModel(
      id: id,
      category: map['category'] as String,
      limit: (map['limit'] as num).toDouble(),
      spent: (map['spent'] as num?)?.toDouble() ?? 0,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: DateTime.parse(map['startDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
      'spent': spent,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
    };
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? limit,
    double? spent,
    BudgetPeriod? period,
    DateTime? startDate,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  List<Object?> get props => [id, category, limit, spent, period, startDate];
}
