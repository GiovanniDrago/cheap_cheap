import 'dart:math' as math;

import 'package:cheapcheap/models/recurrence.dart';

enum SplitFrequency { weekly, monthly }

class SplitPlan {
  SplitPlan({
    required this.totalPayments,
    required this.frequency,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 1,
    this.reminderMessage = '',
  });

  final int totalPayments;
  final SplitFrequency frequency;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final String reminderMessage;

  SplitPlan copyWith({
    int? totalPayments,
    SplitFrequency? frequency,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    String? reminderMessage,
  }) {
    return SplitPlan(
      totalPayments: totalPayments ?? this.totalPayments,
      frequency: frequency ?? this.frequency,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      reminderMessage: reminderMessage ?? this.reminderMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPayments': totalPayments,
      'frequency': frequency.name,
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'reminderMessage': reminderMessage,
    };
  }

  factory SplitPlan.fromJson(Map<String, dynamic> json) {
    return SplitPlan(
      totalPayments: json['totalPayments'] as int? ?? 1,
      frequency: SplitFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => SplitFrequency.monthly,
      ),
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 1,
      reminderMessage: json['reminderMessage'] as String? ?? '',
    );
  }
}

class ExpenseAllocation {
  const ExpenseAllocation({
    required this.expense,
    required this.date,
    required this.amount,
    required this.installmentNumber,
    required this.totalPayments,
  });

  final Expense expense;
  final DateTime date;
  final double amount;
  final int installmentNumber;
  final int totalPayments;

  bool get isSplit => totalPayments > 1;
}

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
    this.splitPlan,
    this.refundDate,
    this.refundNote = '',
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
  final SplitPlan? splitPlan;
  final DateTime? refundDate;
  final String refundNote;

  bool get isRefunded => refundDate != null;

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
    SplitPlan? splitPlan,
    DateTime? refundDate,
    String? refundNote,
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
      splitPlan: splitPlan ?? this.splitPlan,
      refundDate: refundDate ?? this.refundDate,
      refundNote: refundNote ?? this.refundNote,
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
      'splitPlan': splitPlan?.toJson(),
      'refundDate': refundDate?.toIso8601String(),
      'refundNote': refundNote,
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
      splitPlan: json['splitPlan'] == null
          ? null
          : SplitPlan.fromJson(
              Map<String, dynamic>.from(json['splitPlan'] as Map),
            ),
      refundDate: json['refundDate'] == null
          ? null
          : DateTime.parse(json['refundDate'] as String),
      refundNote: json['refundNote'] as String? ?? '',
    );
  }

  List<double> splitAmounts() {
    final plan = splitPlan;
    if (plan == null || plan.totalPayments <= 1) {
      return [amount];
    }

    final sign = amount < 0 ? -1 : 1;
    final totalCents = (amount.abs() * 100).round();
    final perCents = totalCents ~/ plan.totalPayments;
    final remainder = totalCents % plan.totalPayments;

    return List<double>.generate(plan.totalPayments, (index) {
      final cents = perCents + (index < remainder ? 1 : 0);
      return sign * cents / 100;
    });
  }

  List<ExpenseAllocation> allocations() {
    final plan = splitPlan;
    final amounts = splitAmounts();
    final totalPayments = plan?.totalPayments ?? 1;

    return List<ExpenseAllocation>.generate(amounts.length, (index) {
      return ExpenseAllocation(
        expense: this,
        date: _allocationDate(index),
        amount: amounts[index],
        installmentNumber: index + 1,
        totalPayments: totalPayments,
      );
    });
  }

  DateTime _allocationDate(int installmentIndex) {
    final plan = splitPlan;
    if (plan == null || plan.totalPayments <= 1) {
      return refundDate ?? date;
    }

    switch (plan.frequency) {
      case SplitFrequency.weekly:
        return date.add(Duration(days: installmentIndex * 7));
      case SplitFrequency.monthly:
        return _addMonthsKeepingDay(date, installmentIndex);
    }
  }

  DateTime _addMonthsKeepingDay(DateTime source, int monthOffset) {
    final targetMonth = DateTime(source.year, source.month + monthOffset, 1);
    final maxDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final clampedDay = math.min(source.day, maxDay);

    return DateTime(
      targetMonth.year,
      targetMonth.month,
      clampedDay,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }
}
