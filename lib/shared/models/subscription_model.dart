import 'package:equatable/equatable.dart';

enum SubscriptionStatus { active, paused, cancelled }

enum SubscriptionFrequency { weekly, monthly, quarterly, yearly }

class SubscriptionModel extends Equatable {
  final String id;
  final String name;
  final double amount;
  final SubscriptionFrequency frequency;
  final DateTime nextBillingDate;
  final String category;
  final SubscriptionStatus status;
  final String? notes;
  final String? logoUrl;

  const SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextBillingDate,
    required this.category,
    this.status = SubscriptionStatus.active,
    this.notes,
    this.logoUrl,
  });

  double get monthlyAmount {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 4.33;
      case SubscriptionFrequency.monthly:
        return amount;
      case SubscriptionFrequency.quarterly:
        return amount / 3;
      case SubscriptionFrequency.yearly:
        return amount / 12;
    }
  }

  double get yearlyAmount {
    switch (frequency) {
      case SubscriptionFrequency.weekly:
        return amount * 52;
      case SubscriptionFrequency.monthly:
        return amount * 12;
      case SubscriptionFrequency.quarterly:
        return amount * 4;
      case SubscriptionFrequency.yearly:
        return amount;
    }
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      frequency: SubscriptionFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => SubscriptionFrequency.monthly,
      ),
      nextBillingDate: DateTime.parse(map['nextBillingDate'] as String),
      category: map['category'] as String,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      notes: map['notes'] as String?,
      logoUrl: map['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'frequency': frequency.name,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'category': category,
      'status': status.name,
      'notes': notes,
      'logoUrl': logoUrl,
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? name,
    double? amount,
    SubscriptionFrequency? frequency,
    DateTime? nextBillingDate,
    String? category,
    SubscriptionStatus? status,
    String? notes,
    String? logoUrl,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      category: category ?? this.category,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        amount,
        frequency,
        nextBillingDate,
        category,
        status,
        notes,
        logoUrl,
      ];
}
