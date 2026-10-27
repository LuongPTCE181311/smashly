import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/features/auth/register_screen.dart';
import 'package:smashly/features/cart/cart_screen.dart';
import 'package:smashly/features/shell/app_shell.dart';
import 'package:smashly/features/shell/app_tab.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/routes/placeholder_screen.dart';

import '../features/auth/fake_auth_repository.dart';

// Dựng đúng 1 route: `initialRoute: '/dev'` sẽ dựng cả `/` (SplashScreen, cần
// AuthProvider) bên dưới, giống lý do trong lib/app.dart.
// AppShell đọc CartProvider cho badge; chưa có user nên repository không bị gọi.
Widget _app(String initialRoute) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(FakeAuthRepository()),
    ),
    ChangeNotifierProvider<CartProvider>(
      create: (_) => CartProvider(
        CartRepository(
          database: () => throw UnimplementedError(),
          cartDao: const CartDao(),
        ),
      ),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    onGenerateInitialRoutes: (_) => [
      AppRoutes.onGenerateRoute(RouteSettings(name: initialRoute)),
    ],
    onGenerateRoute: AppRoutes.onGenerateRoute,
  ),
);

void main() {
  // Argument đúng kiểu đã ghi ở hằng số trong AppRoutes.
  const pushedRoutes = <String, Object?>{
    AppRoutes.adminDashboard: null,
    AppRoutes.adminProductForm: 1,
  };

  for (final MapEntry(key: route, value: arguments) in pushedRoutes.entries) {
    testWidgets('route $route dựng được màn', (tester) async {
      await tester.pumpWidget(_app(AppRoutes.devMenu));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed(route, arguments: arguments);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PlaceholderScreen), findsOneWidget);
    });
  }

  testWidgets('route register dựng RegisterScreen', (tester) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed<dynamic>(AppRoutes.register);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byType(PlaceholderScreen), findsNothing);
  });

  testWidgets('route tab mở AppShell ở đúng tab', (tester) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamedAndRemoveUntil(AppRoutes.cart, (_) => false);
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.cart.index);
    expect(find.byType(CartScreen), findsOneWidget);
  });

  testWidgets('goToTab đóng route 404 đè lên trên rồi đổi tab', (tester) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    await tester.pumpAndSettle();
    navigator.pushNamed<dynamic>('/route-not-found-test');
    await tester.pumpAndSettle();

    final placeholder = find.byType(PlaceholderScreen);
    expect(tester.widget<PlaceholderScreen>(placeholder).code, '404');
    AppShell.goToTab(tester.element(placeholder), AppTab.cart);
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderScreen), findsNothing);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.cart.index);
  });

  testWidgets('goToTab vẫn đổi tab sau khi đóng AppShell thứ hai', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    await tester.pumpAndSettle();
    // Lỡ mở tab bằng pushNamed → shell thứ hai đè lên, rồi Back đóng nó.
    navigator.pushNamed(AppRoutes.cart);
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();

    AppShell.goToTab(tester.element(find.byType(NavigationBar)), AppTab.shop);
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.shop.index);
  });

  testWidgets('goToTab không đóng màn nào khi không có AppShell', (
    tester,
  ) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();

    AppShell.goToTab(
      tester.element(find.text('S13 · Admin Dashboard')),
      AppTab.cart,
    );
    await tester.pumpAndSettle();

    expect(find.text('S13 · Admin Dashboard'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
