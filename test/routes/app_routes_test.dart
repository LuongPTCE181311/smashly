import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/features/admin/admin_products_screen.dart';
import 'package:smashly/features/auth/login_screen.dart';
import 'package:smashly/features/auth/register_screen.dart';
import 'package:smashly/features/cart/cart_screen.dart';
import 'package:smashly/features/profile/profile_screen.dart';
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
Widget _app(String initialRoute, {AuthProvider? auth}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => auth ?? AuthProvider(_newRepo()),
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

const _admin = User(
  id: 1,
  fullName: 'Smashly Admin',
  email: 'admin@smashly.com',
  phone: '0900000000',
  role: UserRole.admin,
);
const _customer = User(
  id: 2,
  fullName: 'Smashly Customer',
  email: 'customer@smashly.com',
  phone: '0900000001',
  role: UserRole.customer,
);

FakeAuthRepository _newRepo() {
  final repo = FakeAuthRepository();
  addTearDown(() => expect(repo.unexpectedCalls, 0));
  return repo;
}

void main() {
  // Argument đúng kiểu đã ghi ở hằng số trong AppRoutes.
  const pushedRoutes = <String, Object?>{};

  for (final MapEntry(key: route, value: arguments) in pushedRoutes.entries) {
    testWidgets('route $route dựng được màn', (tester) async {
      final repo = _newRepo()..willLogin(_admin);
      final auth = AuthProvider(repo);
      expect(await auth.login(_admin.email, 'Admin@123'), same(_admin));
      await tester.pumpWidget(_app(AppRoutes.devMenu, auth: auth));
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
    navigator.pushNamed<dynamic>('/route-not-found-test');
    await tester.pumpAndSettle();

    final placeholder = find.byType(PlaceholderScreen);
    expect(tester.widget<PlaceholderScreen>(placeholder).code, '404');
    AppShell.goToTab(tester.element(placeholder), AppTab.cart);
    await tester.pumpAndSettle();

    expect(tester.widget<PlaceholderScreen>(placeholder).code, '404');
    expect(navigator.canPop(), isTrue);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chưa đăng nhập mở adminProducts về Login', (tester) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed<dynamic>(AppRoutes.adminProducts);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AdminProductsScreen, skipOffstage: false), findsNothing);
    expect(navigator.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CUSTOMER mở adminDashboard về Login', (tester) async {
    final repo = _newRepo()..willLogin(_customer);
    final auth = AuthProvider(repo);
    expect(await auth.login(_customer.email, 'Customer@123'), same(_customer));
    await tester.pumpWidget(_app(AppRoutes.devMenu, auth: auth));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed<dynamic>(AppRoutes.adminDashboard);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(navigator.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adminProfile không bị guard', (tester) async {
    await tester.pumpWidget(_app(AppRoutes.devMenu));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed<dynamic>(AppRoutes.adminProfile);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Chưa đăng nhập'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(navigator.canPop(), isTrue);
    expect(tester.takeException(), isNull);
  });
}
