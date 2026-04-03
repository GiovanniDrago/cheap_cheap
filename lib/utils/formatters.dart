import 'package:intl/intl.dart';

double parseAmount(String value) {
  final normalized = value.replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

String formatDateField(DateTime date, String locale) {
  return DateFormat.yMd(locale).format(date);
}

String formatDateShort(DateTime date, String locale) {
  return _capitalizeFormattedWords(DateFormat.yMMMd(locale).format(date));
}

String formatMonthYear(DateTime date, String locale) {
  return _capitalizeFormattedWords(DateFormat.yMMMM(locale).format(date));
}

String formatMonthShort(DateTime date, String locale) {
  return _capitalizeFormattedWords(DateFormat.MMM(locale).format(date));
}

String formatCurrency(double amount, String currency, String locale) {
  final format = NumberFormat.currency(
    locale: locale,
    symbol: currency,
    decimalDigits: 2,
  );
  return format.format(amount);
}

String _capitalizeFormattedWords(String value) {
  final buffer = StringBuffer();
  var capitalizeNext = true;

  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    if (_wordCharacterPattern.hasMatch(char)) {
      buffer.write(capitalizeNext ? char.toUpperCase() : char);
      capitalizeNext = false;
      continue;
    }

    buffer.write(char);
    capitalizeNext = true;
  }

  return buffer.toString();
}

final RegExp _wordCharacterPattern = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]');
