import 'package:equatable/equatable.dart';

enum BillFrequency { oneTime, weekly, biWeekly, monthly, quarterly, yearly }

class BillModel extends Equatable {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final BillFrequency frequency;
  final bool isPaid;
  final int remindDaysBefore;
  final String? category;
  final String? notes;

  const BillModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.frequency = BillFrequency.monthly,
    this.isPaid = false,
    this.remindDaysBefore = 3,
    this.category,
    this.notes,
  });

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
  bool get isDueSoon {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return !isPaid && daysUntilDue >= 0 && daysUntilDue <= remindDaysBefore;
  }

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  DateTime get nextDueDate {
    if (!isPaid) return dueDate;

    switch (frequency) {
      case BillFrequency.oneTime:
        return dueDate;
      case BillFrequency.weekly:
        return dueDate.add(const Duration(days: 7));
      case BillFrequency.biWeekly:
        return dueDate.add(const Duration(days: 14));
      case BillFrequency.monthly:
        return DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
      case BillFrequency.quarterly:
        return DateTime(dueDate.year, dueDate.month + 3, dueDate.day);
      case BillFrequency.yearly:
        return DateTime(dueDate.year + 1, dueDate.month, dueDate.day);
    }
  }

  factory BillModel.fromMap(Map<String, dynamic> map, String id) {
    return BillModel(
      id: id,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      frequency: BillFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => BillFrequency.monthly,
      ),
      isPaid: map['isPaid'] as bool? ?? false,
      remindDaysBefore: map['remindDaysBefore'] as int? ?? 3,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'frequency': frequency.name,
      'isPaid': isPaid,
      'remindDaysBefore': remindDaysBefore,
      'category': category,
      'notes': notes,
    };
  }

  BillModel copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillFrequency? frequency,
    bool? isPaid,
    int? remindDaysBefore,
    String? category,
    String? notes,
  }) {
    return BillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      isPaid: isPaid ?? this.isPaid,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    dueDate,
    frequency,
    isPaid,
    remindDaysBefore,
    category,
    notes,
  ];
}
