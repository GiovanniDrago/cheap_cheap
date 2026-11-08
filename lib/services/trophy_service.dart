import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/trophy.dart';

class TrophyService {
  const TrophyService._();

  static const String uncategorizedId = 'no_category';
  static const int maxRankingEntries = 3;

  static List<Trophy> calculate({
    required List<Expense> expenses,
    required List<Category> categories,
    required DateTime referenceDate,
  }) {
    final month = DateTime(referenceDate.year, referenceDate.month);
    final knownCategoryIds = categories.map((category) => category.id).toSet();

    final expenseTransactions = expenses
        .where(
          (expense) =>
              !expense.isIncome &&
              !expense.isRefunded &&
              expense.amount.abs() > 0,
        )
        .toList();
    final incomeTransactions = expenses
        .where((expense) => expense.isIncome && expense.amount.abs() > 0)
        .toList();
    final currentMonthExpenses = expenseTransactions
        .where((expense) => _isInMonth(_effectiveDate(expense), month))
        .toList();

    return [
      _build(
        kind: TrophyKind.topExpenseCategoryCurrentMonth,
        period: TrophyPeriod.currentMonth,
        subjectType: TrophySubjectType.category,
        entries: _categoryEntries(
          expenses: currentMonthExpenses,
          knownCategoryIds: knownCategoryIds,
          month: month,
        ),
      ),
      _build(
        kind: TrophyKind.highestExpenseCurrentMonth,
        period: TrophyPeriod.currentMonth,
        subjectType: TrophySubjectType.expense,
        entries: _transactionEntries(currentMonthExpenses),
      ),
      _build(
        kind: TrophyKind.highestIncomeAllTime,
        period: TrophyPeriod.allTime,
        subjectType: TrophySubjectType.income,
        entries: _transactionEntries(incomeTransactions),
      ),
      _build(
        kind: TrophyKind.topExpenseCategoryAllTime,
        period: TrophyPeriod.allTime,
        subjectType: TrophySubjectType.category,
        entries: _categoryEntries(
          expenses: expenseTransactions,
          knownCategoryIds: knownCategoryIds,
        ),
      ),
      _build(
        kind: TrophyKind.highestExpenseAllTime,
        period: TrophyPeriod.allTime,
        subjectType: TrophySubjectType.expense,
        entries: _transactionEntries(expenseTransactions),
      ),
    ];
  }

  static Trophy _build({
    required TrophyKind kind,
    required TrophyPeriod period,
    required TrophySubjectType subjectType,
    required List<TrophyRankingEntry> entries,
  }) {
    final winner = entries.isEmpty ? null : entries.first;
    return Trophy(
      kind: kind,
      period: period,
      subjectType: subjectType,
      value: winner?.value ?? 0,
      categoryId: winner?.categoryId,
      expenseId: winner?.expenseId,
      date: winner?.date,
      entries: entries,
    );
  }

  static List<TrophyRankingEntry> _categoryEntries({
    required List<Expense> expenses,
    required Set<String> knownCategoryIds,
    DateTime? month,
  }) {
    final totals = <String, _CategoryAccumulator>{};

    for (final expense in expenses) {
      for (final allocation in expense.allocations()) {
        if (month != null && !_isInMonth(allocation.date, month)) {
          continue;
        }

        final categoryId = expense.categoryId;
        final key = categoryId != null && knownCategoryIds.contains(categoryId)
            ? categoryId
            : uncategorizedId;
        final accumulator = totals.putIfAbsent(
          key,
          () => _CategoryAccumulator(),
        );
        accumulator.total += allocation.amount.abs();
        final earliest = accumulator.earliest;
        if (earliest == null || allocation.date.isBefore(earliest)) {
          accumulator.earliest = allocation.date;
        }
      }
    }

    final entries = totals.entries
        .where((entry) => entry.value.total > 0 && entry.value.earliest != null)
        .map(
          (entry) => TrophyRankingEntry(
            value: entry.value.total,
            date: entry.value.earliest!,
            categoryId: entry.key,
          ),
        )
        .toList()
      ..sort(_compareEntries);

    return _limit(entries);
  }

  static List<TrophyRankingEntry> _transactionEntries(List<Expense> expenses) {
    final entries = expenses
        .map(
          (expense) => TrophyRankingEntry(
            value: expense.amount.abs(),
            date: _effectiveDate(expense),
            expenseId: expense.id,
          ),
        )
        .toList()
      ..sort(_compareEntries);

    return _limit(entries);
  }

  static List<TrophyRankingEntry> _limit(List<TrophyRankingEntry> entries) {
    if (entries.length <= maxRankingEntries) {
      return entries;
    }
    return entries.sublist(0, maxRankingEntries);
  }

  static int _compareEntries(TrophyRankingEntry a, TrophyRankingEntry b) {
    final byValue = b.value.compareTo(a.value);
    if (byValue != 0) {
      return byValue;
    }

    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) {
      return byDate;
    }

    return a.subjectId.compareTo(b.subjectId);
  }

  static bool _isInMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  static DateTime _effectiveDate(Expense expense) {
    return expense.refundDate ?? expense.date;
  }
}

class _CategoryAccumulator {
  double total = 0;
  DateTime? earliest;
}
