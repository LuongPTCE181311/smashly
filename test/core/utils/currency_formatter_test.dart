import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/currency_formatter.dart';

void main() {
  test('formats VND with dot separators', () {
    expect(CurrencyFormatter.format(2890000), '2.890.000₫');
    expect(CurrencyFormatter.format(30000), '30.000₫');
    expect(CurrencyFormatter.format(0), '0₫');
  });
}
