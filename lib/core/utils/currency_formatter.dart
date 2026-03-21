import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static String format(num amount) => _formatter.format(amount);

  static String compact(num amount) {
    if (amount >= 1000000) return _compact.format(amount);
    return format(amount);
  }

  static String plain(num amount) {
    return NumberFormat('#,###', 'id_ID').format(amount);
  }
}
