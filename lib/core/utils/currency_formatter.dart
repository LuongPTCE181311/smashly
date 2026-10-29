import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  // Swap the separator by hand so initializeDateFormatting('vi_VN') is not needed.
  static final _fmt = NumberFormat('#,##0', 'en_US');

  /// 2890000 -> "2.890.000₫"
  static String format(int vnd) => '${_fmt.format(vnd).replaceAll(',', '.')}₫';
}
