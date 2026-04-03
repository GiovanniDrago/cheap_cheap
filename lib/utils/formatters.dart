import 'package:intl/intl.dart';

double parseAmount(String value) {
  final normalized = value.replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

String formatDateField(DateTime date, String locale) {
  return DateFormat.yMd(locale).format(date);
}

String formatDateShort(DateTime date, String locale) {
  return DateFormat.yMMMd(locale).format(date);
}

String formatCurrency(double amount, String currency, String locale) {
  final format = NumberFormat.currency(
    locale: locale,
    symbol: currency,
    decimalDigits: 2,
  );
  return format.format(amount);
}
