import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final _currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2);
  static final _number   = NumberFormat('#,##0.##');
  static final _date     = DateFormat('dd MMM yyyy');
  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String currency(num? amount) => _currency.format(amount ?? 0);
  static String number(num? value)    => _number.format(value ?? 0);
  static String date(DateTime? dt)    => dt == null ? '—' : _date.format(dt.toLocal());
  static String dateTime(DateTime? dt) => dt == null ? '—' : _dateTime.format(dt.toLocal());
}
