import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/services/session_service.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/daos/user_dao.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/features/cart/cart_screen.dart';
import 'package:smashly/features/cart/widgets/cart_item_tile.dart';
import 'package:smashly/features/cart/widgets/cart_product_group.dart';
import 'package:smashly/features/product/product_detail_screen.dart';
import 'package:smashly/features/product/widgets/add_to_cart_bar.dart';
import 'package:smashly/features/shell/app_tab.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _grip = 'Yonex Super Grap (3 cuộn)';

late Directory _tempDir;
late String _originalDbPath;

Future<Database> _db() => DatabaseHelper.instance.database;

Future<void> _until(
  WidgetTester tester,
  bool Function() done, {
  String reason = 'điều kiện chưa xảy ra',
}) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(done(), isTrue, reason: reason);
}

Future<AuthProvider> _loginAsCustomer(WidgetTester tester) async {
  final auth = AuthProvider(
    AuthRepository(
      database: _db,
      userDao: const UserDao(),
      cartDao: const CartDao(),
      sessionService: SessionService(),
      resetDatabase: DatabaseHelper.instance.resetDatabase,
    ),
  );
  await tester.runAsync(auth.restoreSession);
  expect(auth.currentUser?.id, 2, reason: 'phiên khôi phục đúng customer');
  return auth;
}

Future<CartProvider> _pumpApp(WidgetTester tester, AuthProvider auth) async {
  final cartRepository = CartRepository(
    database: _db,
    cartDao: const CartDao(),
  );
  late CartProvider cart;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => cart = CartProvider(cartRepository),
          update: (_, auth, cart) => cart!..updateUser(auth.currentUser?.id),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        onGenerateInitialRoutes: (_) => [
          AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.cart)),
        ],
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
  await _until(
    tester,
    () =>
        find.byType(CartItemTile).evaluate().isNotEmpty ||
        find.byType(CartProductGroup).evaluate().isNotEmpty,
    reason: 'giỏ chưa nạp xong từ SQLite',
  );
  await tester.pumpAndSettle();
  return cart;
}

Future<void> _openDetail(WidgetTester tester, Finder tap) async {
  await tester.tap(tap);
  await tester.pump();
  await _until(
    tester,
    () =>
        find.byType(ProductDetailScreen).evaluate().isNotEmpty &&
        (find.byType(AddToCartBar).evaluate().isNotEmpty ||
            find.text('Sản phẩm không còn bán').evaluate().isNotEmpty),
    reason: 'Product Detail chưa nạp xong',
  );
  await tester.pumpAndSettle();
}

Future<void> _addToCart(WidgetTester tester) async {
  await tester.tap(find.text('Thêm vào giỏ'));
  await tester.pump();
  await _until(
    tester,
    () => find.text('Đã thêm vào giỏ hàng').evaluate().isNotEmpty,
    reason: 'chưa thêm được vào giỏ',
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Future<void> _tapBackArrow(WidgetTester tester) async {
  final circle = find.byTooltip('Quay lại');
  if (circle.evaluate().isNotEmpty) {
    await tester.tap(circle);
  } else {
    await tester.tap(find.byTooltip('Back'));
  }
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

void _expectOnCartTab(WidgetTester tester) {
  expect(find.byType(ProductDetailScreen), findsNothing);
  expect(find.byType(CartScreen), findsOneWidget);
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  expect(bar.selectedIndex, AppTab.cart.index);
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pump(ProductDetailScreen.addedFeedback);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': true, 'userId': 2});
    _originalDbPath = await databaseFactory.getDatabasesPath();
    _tempDir = await Directory.systemTemp.createTemp('smashly_snackbar_it_');
    await databaseFactory.setDatabasesPath(_tempDir.path);
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeForTest();
    await databaseFactory.setDatabasesPath(_originalDbPath);
    await _tempDir.delete(recursive: true);
  });

  testWidgets('BUG-01: SnackBar thêm giỏ tự tắt sau khi Back', (tester) async {
    final auth = await _loginAsCustomer(tester);
    try {
      final cart = await _pumpApp(tester, auth);
      await _openDetail(tester, find.text(_grip));
      await _addToCart(tester);

      // TC-PROD-07: thông báo không biến mất quá sớm.
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Đã thêm vào giỏ hàng'), findsOneWidget);

      await _tapBackArrow(tester);
      _expectOnCartTab(tester);
      await tester.pump(
        ProductDetailScreen.addedSnackBarDuration + const Duration(seconds: 1),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // TC-CHK-04: thông báo hết hạn, nút thanh toán nhận được thao tác.
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text('Thanh toán (${cart.selectedCount})').hitTestable(),
        findsOneWidget,
      );
    } finally {
      await _teardown(tester);
      auth.dispose();
    }
  });

  testWidgets('BUG-01: nút Xem giỏ vẫn chuyển sang tab Giỏ', (tester) async {
    final auth = await _loginAsCustomer(tester);
    try {
      await _pumpApp(tester, auth);
      await _openDetail(tester, find.text(_grip));
      await _addToCart(tester);

      // TC-PROD-08: action vẫn đóng chi tiết và chuyển đúng tab Giỏ.
      await tester.tap(find.text('Xem giỏ'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      _expectOnCartTab(tester);
      expect(find.byType(SnackBar), findsNothing);
    } finally {
      await _teardown(tester);
      auth.dispose();
    }
  });
}
