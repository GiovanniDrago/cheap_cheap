import 'package:intl/intl.dart';

double parseAmount(String value) {
  final normalized = value.replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

String formatCurrency(double amount, String currency, String locale) {
  final format = NumberFormat.currency(
    locale: locale,
    symbol: currency,
    decimalDigits: 2,
  );
  return format.format(amount);
}
