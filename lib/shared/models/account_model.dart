import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AccountType { checking, savings, creditCard, investment, cash, other }

class AccountModel extends Equatable {
  final String id;
  final String name;
  final AccountType type;
  final int color; // Store as int (0xAARRGGBB)
  final String? icon;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.icon,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.checking,
      ),
      color: map['color'] as int? ?? Colors.blue.value,
      icon: map['icon'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'type': type.name, 'color': color, 'icon': icon};
  }

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? color,
    String? icon,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  @override
  List<Object?> get props => [id, name, type, color, icon];
}
