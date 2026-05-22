import 'package:flutter/material.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime addMonths(DateTime date, int offset) {
  return DateTime(date.year, date.month + offset, 1);
}

/// Returns a locale override for date pickers so the calendar starts on
/// Monday when the user has chosen [weekStart] == 'monday'.
///
/// For English the ambient locale defaults to Sunday (en_US).  Switching to
/// `en_GB` makes Flutter's pickers start on Monday while keeping the rest of
/// the UI in English.
Locale? pickerLocale(Locale appLocale, String weekStart) {
  if (weekStart == 'monday' && appLocale.languageCode == 'en') {
    return const Locale('en', 'GB');
  }
  return null;
}
