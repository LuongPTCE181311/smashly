import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_colors.dart';
import 'package:smashly/features/admin/widgets/admin_stock_label.dart';

void main() {
  Future<void> pump(WidgetTester tester, int stock) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AdminStockLabel(stock: stock))),
    );
  }

  Color textColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  testWidgets('tồn kho luôn có chữ, màu chỉ nhấn mạnh', (tester) async {
    await pump(tester, 12);
    expect(textColor(tester, 'Kho: 12'), AppColors.success);

    await pump(tester, 3);
    expect(textColor(tester, '3 · Sắp hết'), AppColors.warning);

    await pump(tester, 0);
    expect(textColor(tester, '0 · Hết'), AppColors.error);
  });
}
