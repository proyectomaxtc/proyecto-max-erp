import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat(
    "#,##0",
    "es_AR",
  );

  static String format(num value) {
    return "\$ ${_formatter.format(value)}";
  }
}