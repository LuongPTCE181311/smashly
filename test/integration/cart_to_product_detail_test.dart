import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
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

/// End-to-end integration: real SQLite (temp file), real seed, real session
/// (SharedPreferences set up as user 2), real router, real Product Detail.
///
/// The DB and interactions use real I/O, so every wait goes through `runAsync`.
const _grip =
    'Yonex Super Grap (3 cuộn)'; // product 19, the customer's seeded cart
const _gripId = 19;
const _shoeId = 10; // Power Cushion 65 Z3, sizes 39–44

late Directory _tempDir;
late String _originalDbPath;

Future<Database> _db() => DatabaseHelper.instance.database;

/// Waits for real I/O and repaints, up to ~4 seconds, until [done] is true.
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

/// Opens the app straight on the Cart tab with the real router and providers.
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

Future<void> _tapBackArrow(WidgetTester tester) async {
  final circle = find.byTooltip('Quay lại');
  if (circle.evaluate().isNotEmpty) {
    await tester.tap(circle);
  } else {
    await tester.tap(find.byTooltip('Back'));
  }
  await tester.pumpAndSettle();
}

Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// The Cart tab is showing and no screen is on top of it.
void _expectOnCartTab(WidgetTester tester) {
  expect(find.byType(ProductDetailScreen), findsNothing);
  expect(find.byType(CartScreen), findsOneWidget);
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  expect(bar.selectedIndex, AppTab.cart.index);
}

/// Tears the widget tree down so the screens' Timers are cancelled before the test ends.
Future<void> _teardown(WidgetTester tester) async {
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
    _tempDir = await Directory.systemTemp.createTemp('smashly_cart_it_');
    await databaseFactory.setDatabasesPath(_tempDir.path);
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeForTest();
    await databaseFactory.setDatabasesPath(_originalDbPath);
    await _tempDir.delete(recursive: true);
  });

  group('giỏ hàng -> chi tiết sản phẩm -> quay lại (DB và router thật)', () {
    testWidgets('bấm sản phẩm mở đúng Product Detail, nút mũi tên về giỏ', (
      tester,
    ) async {
      final auth = await _loginAsCustomer(tester);
      await _pumpApp(tester, auth);
      expect(find.text(_grip), findsOneWidget);

      await _openDetail(tester, find.text(_grip));

      // The real detail of product 19, read from SQLite.
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text(_grip), findsWidgets);
      expect(find.text('Thêm vào giỏ'), findsOneWidget);

      await _tapBackArrow(tester);

      _expectOnCartTab(tester);
      expect(find.text(_grip), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('nút Back / cử chỉ hệ thống cũng về giỏ', (tester) async {
      final auth = await _loginAsCustomer(tester);
      await _pumpApp(tester, auth);

      await _openDetail(tester, find.text(_grip));
      await _systemBack(tester);

      _expectOnCartTab(tester);
      expect(find.text(_grip), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('thêm vào giỏ ở trang chi tiết rồi quay lại: giỏ cập nhật', (
      tester,
    ) async {
      final auth = await _loginAsCustomer(tester);
      final cart = await _pumpApp(tester, auth);
      expect(cart.items.single.quantity, 1);

      await _openDetail(tester, find.text(_grip));
      await tester.tap(find.text('Thêm vào giỏ'));
      await tester.pump();
      await _until(
        tester,
        () => find.text('Đã thêm vào giỏ hàng').evaluate().isNotEmpty,
        reason: 'chưa thêm được vào giỏ',
      );
      await tester.pump(const Duration(seconds: 2));
      await _tapBackArrow(tester);

      _expectOnCartTab(tester);
      // Same product, no size: accumulated into one line with quantity 2.
      expect(find.byType(CartItemTile), findsOneWidget);
      expect(cart.items.single.quantity, 2);
      expect(
        cart.itemCount,
        1,
        reason: 'badge đếm mặt hàng, không đếm số lượng',
      );
      final rows = await tester.runAsync(() async {
        final db = await _db();
        return db.query(DbSchema.cartItems);
      });
      expect(rows!.single['quantity'], 2, reason: 'đã ghi xuống SQLite');
      await _teardown(tester);
    });

    testWidgets('thẻ nhiều size mở chi tiết của đúng sản phẩm', (tester) async {
      final auth = await _loginAsCustomer(tester);
      await tester.runAsync(() async {
        final db = await _db();
        const dao = CartDao();
        final cartId = await dao.getOrCreateCartId(db, 2);
        for (final size in ['41', '42']) {
          await dao.insertLine(
            db,
            cartId: cartId,
            productId: _shoeId,
            quantity: 1,
            size: size,
          );
        }
      });
      await _pumpApp(tester, auth);
      expect(find.byType(CartProductGroup), findsOneWidget);

      await _openDetail(tester, find.text('2 size trong giỏ'));

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Chọn size'), findsOneWidget, reason: 'giày có size');
      await _tapBackArrow(tester);

      _expectOnCartTab(tester);
      expect(find.byType(CartProductGroup), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets(
      'sản phẩm đã ngừng bán: mở ra trạng thái rỗng, vẫn về được giỏ',
      (tester) async {
        final auth = await _loginAsCustomer(tester);
        await tester.runAsync(() async {
          final db = await _db();
          await db.update(
            DbSchema.products,
            {'is_active': 0},
            where: 'id = ?',
            whereArgs: [_gripId],
          );
        });
        await _pumpApp(tester, auth);

        await _openDetail(tester, find.text(_grip));

        expect(find.text('Sản phẩm không còn bán'), findsOneWidget);
        await _tapBackArrow(tester);

        _expectOnCartTab(tester);
        expect(find.text(_grip), findsOneWidget);
        await _teardown(tester);
      },
    );

    testWidgets('đi - về nhiều lần: DB giữ nguyên, không rò rỉ route', (
      tester,
    ) async {
      final auth = await _loginAsCustomer(tester);
      final cart = await _pumpApp(tester, auth);

      for (var i = 0; i < 4; i++) {
        await _openDetail(tester, find.text(_grip));
        i.isEven ? await _tapBackArrow(tester) : await _systemBack(tester);
        _expectOnCartTab(tester);
      }

      final rows = await tester.runAsync(() async {
        final db = await _db();
        return db.query(DbSchema.cartItems);
      });
      expect(rows, hasLength(1));
      expect(rows!.single['quantity'], 1, reason: 'chỉ xem, không đổi dữ liệu');
      expect(cart.items.single.quantity, 1);
      expect(tester.takeException(), isNull);
      await _teardown(tester);
    });
  });
}
