enum TrophyKind {
  topExpenseCategoryCurrentMonth,
  highestExpenseCurrentMonth,
  highestIncomeAllTime,
  topExpenseCategoryAllTime,
  highestExpenseAllTime,
}

enum TrophyPeriod { currentMonth, allTime }

enum TrophySubjectType { category, expense, income }

class TrophyRankingEntry {
  const TrophyRankingEntry({
    required this.value,
    required this.date,
    this.categoryId,
    this.expenseId,
  });

  final double value;
  final DateTime date;
  final String? categoryId;
  final String? expenseId;

  bool get isCategory => categoryId != null;

  String get subjectId => categoryId ?? expenseId ?? '';
}

class Trophy {
  const Trophy({
    required this.kind,
    required this.period,
    required this.subjectType,
    required this.value,
    this.categoryId,
    this.expenseId,
    this.date,
    this.entries = const [],
  });

  final TrophyKind kind;
  final TrophyPeriod period;
  final TrophySubjectType subjectType;
  final double value;
  final String? categoryId;
  final String? expenseId;
  final DateTime? date;
  final List<TrophyRankingEntry> entries;

  bool get hasData => value > 0 && entries.isNotEmpty;

  TrophyRankingEntry? get winner => entries.isEmpty ? null : entries.first;
}
