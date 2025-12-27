import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  final String id;
  final String? accountId;
  final double amount;
  final DateTime date;
  final String merchantName;
  final String category;
  final bool isSubscription;
  final String? notes;
  final String? statementId;

  const TransactionModel({
    required this.id,
    this.accountId,
    required this.amount,
    required this.date,
    required this.merchantName,
    required this.category,
    this.isSubscription = false,
    this.notes,
    this.statementId,
  });

  bool get isExpense => amount < 0;
  bool get isIncome => amount > 0;
  double get absoluteAmount => amount.abs();

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      accountId: map['accountId'] as String?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      merchantName: map['merchantName'] as String,
      category: map['category'] as String,
      isSubscription: map['isSubscription'] as bool? ?? false,
      notes: map['notes'] as String?,
      statementId: map['statementId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'merchantName': merchantName,
      'category': category,
      'isSubscription': isSubscription,
      'notes': notes,
      'statementId': statementId,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? accountId,
    double? amount,
    DateTime? date,
    String? merchantName,
    String? category,
    bool? isSubscription,
    String? notes,
    String? statementId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      isSubscription: isSubscription ?? this.isSubscription,
      notes: notes ?? this.notes,
      statementId: statementId ?? this.statementId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    accountId,
    amount,
    date,
    merchantName,
    category,
    isSubscription,
    notes,
    statementId,
  ];
}
