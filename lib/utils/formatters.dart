import 'package:intl/intl.dart';

class Formatters {
  static String inr(num value, {int decimals = 2}) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: decimals).format(value);
}
