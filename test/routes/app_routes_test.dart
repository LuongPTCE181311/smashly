import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/features/shell/app_shell.dart';
import 'package:smashly/features/shell/app_tab.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/routes/placeholder_screen.dart';

Widget _app(String initialRoute) => MaterialApp(
  theme: AppTheme.light,
  initialRoute: initialRoute,
  onGenerateRoute: AppRoutes.onGenerateRoute,
);

void main() {
  const pushedRoutes = [
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.productDetail,
    AppRoutes.checkout,
    AppRoutes.orderSuccess,
    AppRoutes.orderDetail,
    AppRoutes.adminDashboard,
    AppRoutes.adminProducts,
    AppRoutes.adminProductForm,
    AppRoutes.adminProfile,
  ];

  for (final route in pushedRoutes) {
    testWidgets('route $route dựng được màn', (tester) async {
      await tester.pumpWidget(_app(AppRoutes.devMenu));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(route, arguments: 1);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PlaceholderScreen), findsOneWidget);
    });
  }

  testWidgets('route tab mở AppShell ở đúng tab', (tester) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamedAndRemoveUntil(AppRoutes.cart, (_) => false);
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.cart.index);
    expect(find.text('S07 · Giỏ hàng'), findsOneWidget);
  });

  testWidgets('goToTab đóng màn đè lên trên rồi đổi tab', (tester) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    await tester.pumpAndSettle();
    navigator.pushNamed(AppRoutes.productDetail, arguments: 1);
    await tester.pumpAndSettle();

    AppShell.goToTab(
      tester.element(find.text('S06 · Chi tiết sản phẩm')),
      AppTab.cart,
    );
    await tester.pumpAndSettle();

    expect(find.text('S06 · Chi tiết sản phẩm'), findsNothing);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.cart.index);
  });
}
