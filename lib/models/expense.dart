import 'package:cheapcheap/models/recurrence.dart';

class Expense {
  Expense({
    required this.id,
    required this.date,
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.iconId,
    this.categoryId,
    this.note = '',
    this.recurrence,
  });

  final String id;
  final DateTime date;
  final String name;
  final double amount;
  final bool isIncome;
  final String iconId;
  final String? categoryId;
  final String note;
  final Recurrence? recurrence;

  Expense copyWith({
    String? id,
    DateTime? date,
    String? name,
    double? amount,
    bool? isIncome,
    String? iconId,
    String? categoryId,
    String? note,
    Recurrence? recurrence,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      iconId: iconId ?? this.iconId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'name': name,
      'amount': amount,
      'isIncome': isIncome,
      'iconId': iconId,
      'categoryId': categoryId,
      'note': note,
      'recurrence': recurrence?.toJson(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      isIncome: json['isIncome'] as bool? ?? false,
      iconId: json['iconId'] as String? ?? 'wallet',
      categoryId: json['categoryId'] as String?,
      note: json['note'] as String? ?? '',
      recurrence: json['recurrence'] == null
          ? null
          : Recurrence.fromJson(
              Map<String, dynamic>.from(json['recurrence'] as Map),
            ),
    );
  }
}
