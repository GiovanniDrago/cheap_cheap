import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/stat_key.dart';
import 'package:cheapcheap/models/trophy.dart';
import 'package:cheapcheap/services/trophy_service.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _referenceDate = DateTime(2026, 11, 8);

Expense _expense({
  required String id,
  required DateTime date,
  required double amount,
  String? categoryId,
  bool isIncome = false,
  DateTime? refundDate,
  SplitPlan? splitPlan,
  String? name,
}) {
  return Expense(
    id: id,
    date: date,
    name: name ?? id,
    amount: amount,
    isIncome: isIncome,
    iconId: 'wallet',
    categoryId: categoryId,
    refundDate: refundDate,
    splitPlan: splitPlan,
  );
}

Category _category(String id) {
  return Category(
    id: id,
    name: id,
    iconId: 'wallet',
    isIncomeDefault: false,
    statKey: StatKey.spirit,
  );
}

Trophy _trophy(List<Trophy> trophies, TrophyKind kind) {
  return trophies.firstWhere((trophy) => trophy.kind == kind);
}

void main() {
  test('returns five empty trophies when there is no data', () {
    final trophies = TrophyService.calculate(
      expenses: const [],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    expect(trophies, hasLength(5));
    expect(trophies.every((trophy) => !trophy.hasData), isTrue);
    expect(trophies.every((trophy) => trophy.entries.isEmpty), isTrue);
  });

  test('finds the top expense category for the current month and all time', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'food-1',
          date: DateTime(2026, 11, 2),
          amount: 20,
          categoryId: 'food',
        ),
        _expense(
          id: 'food-2',
          date: DateTime(2026, 11, 5),
          amount: 10,
          categoryId: 'food',
        ),
        _expense(
          id: 'transport',
          date: DateTime(2026, 11, 3),
          amount: 15,
          categoryId: 'transport',
        ),
        _expense(
          id: 'food-old',
          date: DateTime(2026, 10, 1),
          amount: 100,
          categoryId: 'food',
        ),
      ],
      categories: [_category('food'), _category('transport')],
      referenceDate: _referenceDate,
    );

    final current = _trophy(
      trophies,
      TrophyKind.topExpenseCategoryCurrentMonth,
    );
    expect(current.value, 30);
    expect(current.categoryId, 'food');

    final allTime = _trophy(trophies, TrophyKind.topExpenseCategoryAllTime);
    expect(allTime.value, 130);
    expect(allTime.categoryId, 'food');
  });

  test('finds the highest expense for the current month and all time', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'current',
          date: DateTime(2026, 11, 2),
          amount: 20,
          categoryId: 'food',
        ),
        _expense(
          id: 'older',
          date: DateTime(2026, 10, 1),
          amount: 100,
          categoryId: 'food',
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    expect(
      _trophy(trophies, TrophyKind.highestExpenseCurrentMonth).expenseId,
      'current',
    );
    expect(
      _trophy(trophies, TrophyKind.highestExpenseCurrentMonth).value,
      20,
    );
    expect(
      _trophy(trophies, TrophyKind.highestExpenseAllTime).expenseId,
      'older',
    );
    expect(_trophy(trophies, TrophyKind.highestExpenseAllTime).value, 100);
  });

  test('finds the highest income across all months', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'income-old',
          date: DateTime(2026, 1, 10),
          amount: 500,
          isIncome: true,
        ),
        _expense(
          id: 'income-new',
          date: DateTime(2026, 11, 1),
          amount: 300,
          isIncome: true,
        ),
      ],
      categories: const [],
      referenceDate: _referenceDate,
    );

    final income = _trophy(trophies, TrophyKind.highestIncomeAllTime);
    expect(income.value, 500);
    expect(income.expenseId, 'income-old');
  });

  test('breaks ties using the oldest transaction first', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'old',
          date: DateTime(2026, 11, 1),
          amount: 50,
          categoryId: 'food',
        ),
        _expense(
          id: 'new',
          date: DateTime(2026, 11, 2),
          amount: 50,
          categoryId: 'food',
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    final trophy = _trophy(trophies, TrophyKind.highestExpenseCurrentMonth);
    expect(trophy.expenseId, 'old');
    expect(trophy.entries.map((entry) => entry.expenseId), ['old', 'new']);
  });

  test('excludes refunded expenses from expense trophies', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'refunded',
          date: DateTime(2026, 11, 1),
          amount: 500,
          categoryId: 'food',
          refundDate: DateTime(2026, 11, 4),
        ),
        _expense(
          id: 'regular',
          date: DateTime(2026, 11, 2),
          amount: 20,
          categoryId: 'food',
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    expect(
      _trophy(trophies, TrophyKind.highestExpenseCurrentMonth).expenseId,
      'regular',
    );
    expect(
      _trophy(trophies, TrophyKind.topExpenseCategoryCurrentMonth).value,
      20,
    );
  });

  test('attributes installments to their months for category totals', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'split',
          date: DateTime(2026, 11, 15),
          amount: 100,
          categoryId: 'food',
          splitPlan: SplitPlan(
            totalPayments: 2,
            frequency: SplitFrequency.monthly,
          ),
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    expect(
      _trophy(trophies, TrophyKind.topExpenseCategoryCurrentMonth).value,
      50,
    );
    expect(_trophy(trophies, TrophyKind.topExpenseCategoryAllTime).value, 100);
    expect(
      _trophy(trophies, TrophyKind.highestExpenseCurrentMonth).value,
      100,
    );
  });

  test('groups null and unknown categories under no_category', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'no-category',
          date: DateTime(2026, 11, 1),
          amount: 20,
        ),
        _expense(
          id: 'unknown-category',
          date: DateTime(2026, 11, 2),
          amount: 10,
          categoryId: 'missing',
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    final trophy = _trophy(trophies, TrophyKind.topExpenseCategoryCurrentMonth);
    expect(trophy.value, 30);
    expect(trophy.categoryId, TrophyService.uncategorizedId);
    expect(trophy.entries, hasLength(1));
  });

  test('includes future transactions only in all-time trophies', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'current',
          date: DateTime(2026, 11, 2),
          amount: 20,
          categoryId: 'food',
        ),
        _expense(
          id: 'future',
          date: DateTime(2027, 11, 2),
          amount: 500,
          categoryId: 'food',
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    expect(
      _trophy(trophies, TrophyKind.highestExpenseCurrentMonth).expenseId,
      'current',
    );
    expect(
      _trophy(trophies, TrophyKind.highestExpenseAllTime).expenseId,
      'future',
    );
  });

  test('ignores zero-amount transactions', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'zero',
          date: DateTime(2026, 11, 2),
          amount: 0,
          categoryId: 'food',
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    expect(trophies.every((trophy) => !trophy.hasData), isTrue);
  });

  test('limits rankings to the first three entries', () {
    final trophies = TrophyService.calculate(
      expenses: [
        _expense(
          id: 'one',
          date: DateTime(2026, 11, 1),
          amount: 10,
          categoryId: 'food',
        ),
        _expense(
          id: 'two',
          date: DateTime(2026, 11, 2),
          amount: 20,
          categoryId: 'food',
        ),
        _expense(
          id: 'three',
          date: DateTime(2026, 11, 3),
          amount: 30,
          categoryId: 'food',
        ),
        _expense(
          id: 'four',
          date: DateTime(2026, 11, 4),
          amount: 40,
          categoryId: 'food',
        ),
      ],
      categories: [_category('food')],
      referenceDate: _referenceDate,
    );

    final trophy = _trophy(trophies, TrophyKind.highestExpenseCurrentMonth);
    expect(trophy.entries, hasLength(3));
    expect(trophy.entries.map((entry) => entry.expenseId), [
      'four',
      'three',
      'two',
    ]);
  });
}
