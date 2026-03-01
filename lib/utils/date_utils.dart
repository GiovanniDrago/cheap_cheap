DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime addMonths(DateTime date, int offset) {
  return DateTime(date.year, date.month + offset, 1);
}
