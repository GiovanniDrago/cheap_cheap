import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/trophy.dart';
import 'package:cheapcheap/services/trophy_service.dart';

String trophyTitle(AppLocalizations strings, TrophyKind kind) {
  switch (kind) {
    case TrophyKind.topExpenseCategoryCurrentMonth:
      return strings.trophyTopExpenseCategoryCurrentMonth;
    case TrophyKind.highestExpenseCurrentMonth:
      return strings.trophyHighestExpenseCurrentMonth;
    case TrophyKind.highestIncomeAllTime:
      return strings.trophyHighestIncomeAllTime;
    case TrophyKind.topExpenseCategoryAllTime:
      return strings.trophyTopExpenseCategoryAllTime;
    case TrophyKind.highestExpenseAllTime:
      return strings.trophyHighestExpenseAllTime;
  }
}

String trophyPeriodLabel(AppLocalizations strings, TrophyPeriod period) {
  switch (period) {
    case TrophyPeriod.currentMonth:
      return strings.currentMonth;
    case TrophyPeriod.allTime:
      return strings.allTime;
  }
}

String trophySubject(
  Trophy trophy,
  List<Category> categories,
  List<Expense> expenses,
  AppLocalizations strings,
) {
  final categoryId = trophy.categoryId;
  if (categoryId != null) {
    return _categoryName(categoryId, categories, strings);
  }

  final expenseId = trophy.expenseId;
  if (expenseId != null) {
    return _expenseName(expenseId, expenses);
  }

  return '';
}

String rankingEntrySubject(
  TrophyRankingEntry entry,
  List<Category> categories,
  List<Expense> expenses,
  AppLocalizations strings,
) {
  final categoryId = entry.categoryId;
  if (categoryId != null) {
    return _categoryName(categoryId, categories, strings);
  }

  final expenseId = entry.expenseId;
  if (expenseId != null) {
    return _expenseName(expenseId, expenses);
  }

  return '';
}

String _categoryName(
  String categoryId,
  List<Category> categories,
  AppLocalizations strings,
) {
  if (categoryId == TrophyService.uncategorizedId) {
    return strings.noCategory;
  }

  for (final category in categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }

  return strings.noCategory;
}

String _expenseName(String expenseId, List<Expense> expenses) {
  for (final expense in expenses) {
    if (expense.id == expenseId) {
      return expense.name;
    }
  }

  return '';
}
