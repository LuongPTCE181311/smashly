import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/routes/dev_menu_screen.dart';
import 'package:smashly/routes/widget_catalog_screen.dart';
import 'package:smashly/shared/widgets/app_logo.dart';
import 'package:smashly/shared/widgets/order_status_badge.dart';
import 'package:smashly/shared/widgets/states/error_state.dart';

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  home: home,
  onGenerateRoute: AppRoutes.onGenerateRoute,
);

final _list = find.byType(Scrollable).first;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: _list);
  await tester.pump();
}

void main() {
  testWidgets('dev menu mở được Widget Catalog', (tester) async {
    await tester.pumpWidget(_app(const DevMenuScreen()));

    await _scrollTo(
      tester,
      find.text('Widget Catalog (mọi component dùng chung)'),
    );
    await tester.tap(find.text('Widget Catalog (mọi component dùng chung)'));
    await tester.pumpAndSettle();

    expect(find.byType(WidgetCatalogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cuộn hết catalog không lỗi, đủ các nhóm component', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const WidgetCatalogScreen()));

    for (final section in [
      'Màu · AppColors',
      'Kiểu chữ · AppTextStyles',
      'PrimaryButton',
      'SecondaryButton',
      'AppTextField',
      'StockBadge',
      'OrderStatusBadge',
      'PriceText · RatingView',
      'ProductCard · CategoryCard',
      'AppDialog.confirm',
      'LoadingState · EmptyState · ErrorState',
      'AppLogo',
    ]) {
      await _scrollTo(tester, find.text(section));
      expect(find.text(section), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await _scrollTo(tester, find.text('Không khởi tạo được dữ liệu'));
    expect(find.byType(ErrorState), findsWidgets);
    await _scrollTo(tester, find.text('Chỉ biểu tượng'));
    expect(find.byType(AppLogo), findsWidgets);
  });

  testWidgets('đủ 5 nhãn trạng thái đơn hàng', (tester) async {
    await tester.pumpWidget(_app(const WidgetCatalogScreen()));

    await _scrollTo(tester, find.text('Đã hủy'));

    expect(
      find.byType(OrderStatusBadge),
      findsNWidgets(OrderStatus.values.length),
    );
  });

  for (final (button, result) in [('Hủy đơn', true), ('Giữ đơn', false)]) {
    testWidgets('dialog hủy đơn: bấm "$button" thì confirm trả $result', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const WidgetCatalogScreen()));
      final open = find.text('Mở dialog hủy đơn');

      await _scrollTo(tester, open);
      await tester.tap(open);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(button));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('AppDialog.confirm trả về $result'), findsOneWidget);
    });
  }
}
