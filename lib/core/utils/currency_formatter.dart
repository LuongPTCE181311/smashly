import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  // Tự đổi dấu ngăn cách để không cần initializeDateFormatting('vi_VN').
  static final _fmt = NumberFormat('#,##0', 'en_US');

  /// 2890000 -> "2.890.000₫"
  static String format(int vnd) => '${_fmt.format(vnd).replaceAll(',', '.')}₫';
}
