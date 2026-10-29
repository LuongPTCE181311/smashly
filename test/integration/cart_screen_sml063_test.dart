@Timeout(Duration(seconds: 90))
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/services/session_service.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/currency_formatter.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/daos/user_dao.dart';
import 'package:smashly/data/daos/wishlist_dao.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/data/repositories/wishlist_repository.dart';
import 'package:smashly/features/cart/widgets/cart_item_tile.dart';
import 'package:smashly/features/cart/widgets/cart_summary_bar.dart';
import 'package:smashly/features/shell/app_tab.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:smashly/providers/wishlist_provider.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/shared/widgets/product_card.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SML-063 · criteria "reopening the app keeps the cart" and "the total counts
/// only selected items", checked with real SQLite (temp file), real seed, real
/// session and real router. "Quit the app" = remove the whole widget tree, close
/// the DB, then rebuild the providers and reopen the DB file from scratch.
const _grip = 'Yonex Super Grap (3 cuộn)'; // product 19, 150.000₫, stock 80
const _astrox = 'Yonex Astrox 77 Pro'; // product 2, 3.690.000₫, stock 15
const _string = 'Yonex BG66 Ultimax'; // product 20, 220.000₫, stock 50

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

/// Waits until a condition based on (async) SQLite becomes true.
Future<void> _untilDb(
  WidgetTester tester,
  Future<bool> Function() done, {
  String reason = 'SQLite chưa có dữ liệu mong đợi',
}) async {
  var ok = false;
  for (var i = 0; i < 200 && !ok; i++) {
    ok = (await tester.runAsync(done))!;
    if (!ok) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
  }
  expect(ok, isTrue, reason: reason);
}

AuthProvider _newAuth() => AuthProvider(
  AuthRepository(
    database: _db,
    userDao: const UserDao(),
    cartDao: const CartDao(),
    sessionService: SessionService(),
    resetDatabase: DatabaseHelper.instance.resetDatabase,
  ),
);

Future<AuthProvider> _restoreSession(WidgetTester tester) async {
  // Tall screen so the lazy ListView builds every cart card.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = _newAuth();
  await tester.runAsync(auth.restoreSession);
  expect(auth.currentUser?.id, 2, reason: 'phiên khôi phục đúng customer');
  return auth;
}

final _cartRepository = CartRepository(database: _db, cartDao: const CartDao());

/// Adds an item to [userId]'s cart straight through the repository (test data).
Future<void> _seedLine(
  WidgetTester tester,
  int productId, {
  int quantity = 1,
  String size = '',
  int userId = 2,
}) async {
  await tester.runAsync(
    () => _cartRepository.addToCart(
      userId: userId,
      productId: productId,
      quantity: quantity,
      size: size,
    ),
  );
}

/// Runs inside _untilDb's runAsync, so it must not call runAsync itself.
Future<List<Map<String, Object?>>> _queryLines() async {
  final db = await _db();
  return db.rawQuery(
    'SELECT ci.product_id, ci.size, ci.quantity, ci.is_selected '
    'FROM ${DbSchema.cartItems} ci '
    'JOIN ${DbSchema.carts} c ON c.id = ci.cart_id '
    'WHERE c.user_id = 2 ORDER BY ci.product_id',
  );
}

/// Opens the app straight on the Cart tab, then waits for [ready].
Future<void> _pumpApp(
  WidgetTester tester,
  AuthProvider auth, {
  required bool Function() ready,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(_cartRepository),
          update: (_, auth, cart) => cart!..updateUser(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(
            WishlistRepository(
              database: _db,
              wishlistDao: const WishlistDao(),
              productDao: const ProductDao(),
            ),
          ),
          update: (_, auth, wishlist) =>
              wishlist!..updateUser(auth.currentUser?.id),
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
  await _until(tester, ready, reason: 'giỏ chưa hiển thị xong');
  await tester.pumpAndSettle();
}

bool _hasTiles() => find.byType(CartItemTile).evaluate().isNotEmpty;
bool _isEmptyCart() => find.text('Giỏ hàng đang trống').evaluate().isNotEmpty;

/// Ends a test: waits for in-flight queries to finish, then removes the widget
/// tree, so tearDown never closes the DB midway (which hangs the next test).
Future<void> _finish(WidgetTester tester) async {
  // Wait before removing the tree: a provider disposed mid-load notifies after dispose.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// "Quit the app": removes the tree, closes the DB. Reopen via `_restoreSession` + `_pumpApp`.
Future<void> _quitApp(WidgetTester tester) async {
  await _finish(tester);
  await tester.runAsync(DatabaseHelper.instance.closeForTest);
}

Finder _tile(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(CartItemTile));

Finder _inBar(String text) =>
    find.descendant(of: find.byType(CartSummaryBar), matching: find.text(text));

Future<void> _swipe(WidgetTester tester, String name) async {
  await tester.drag(find.text(name), const Offset(-600, 0));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': true, 'userId': 2});
    _originalDbPath = await databaseFactory.getDatabasesPath();
    _tempDir = await Directory.systemTemp.createTemp('smashly_cart063_');
    await databaseFactory.setDatabasesPath(_tempDir.path);
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeForTest();
    await databaseFactory.setDatabasesPath(_originalDbPath);
    await _tempDir.delete(recursive: true);
  });

  testWidgets(
    'thoát app mở lại: số lượng, trạng thái chọn, món đã xóa và tổng tiền giữ nguyên',
    (tester) async {
      var auth = await _restoreSession(tester);
      await _seedLine(tester, 2, quantity: 2);
      await _seedLine(tester, 20);
      await _pumpApp(tester, auth, ready: _hasTiles);
      expect(find.byType(CartItemTile), findsNWidgets(3));
      // 150.000 + 2 x 3.690.000 + 220.000
      expect(_inBar('7.750.000₫'), findsOneWidget);

      // Untick the string, raise the grip quantity, delete the racket.
      await tester.tap(
        find.descendant(of: _tile(_string), matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: _tile(_grip),
          matching: find.widgetWithIcon(IconButton, Icons.add_rounded),
        ),
      );
      await tester.pumpAndSettle();
      await _swipe(tester, _astrox);
      // Values only change once SQLite has written (real I/O), so wait.
      await _until(
        tester,
        () => _inBar('300.000₫').evaluate().isNotEmpty,
        reason: 'tổng phải còn 2 x 150.000 (chỉ món đang chọn)',
      );

      await _untilDb(tester, () async {
        final rows = await _queryLines();
        return rows.length == 2 &&
            rows.any((r) => r['product_id'] == 19 && r['quantity'] == 2) &&
            rows.any((r) => r['product_id'] == 20 && r['is_selected'] == 0);
      }, reason: 'thay đổi chưa được ghi xuống SQLite');

      // Quit the app, then reopen it from scratch.
      await _quitApp(tester);
      auth = await _restoreSession(tester);
      await _pumpApp(tester, auth, ready: _hasTiles);

      expect(find.byType(CartItemTile), findsNWidgets(2));
      expect(
        find.text(_astrox),
        findsNothing,
        reason: 'đã xóa thì không quay lại',
      );
      expect(
        find.descendant(of: _tile(_grip), matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(
                of: _tile(_grip),
                matching: find.byType(Checkbox),
              ),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(
                of: _tile(_string),
                matching: find.byType(Checkbox),
              ),
            )
            .value,
        isFalse,
        reason: 'món đã bỏ chọn vẫn bỏ chọn',
      );
      expect(
        _inBar('300.000₫'),
        findsOneWidget,
        reason: 'tổng chỉ tính món chọn',
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Thanh toán (1)'),
            )
            .onPressed,
        isNotNull,
      );
      await _finish(tester);
    },
  );

  testWidgets(
    'Hoàn tác ghi lại SQLite: thoát app mở lại món vẫn còn, đúng số lượng và trạng thái chọn',
    (tester) async {
      var auth = await _restoreSession(tester);
      await _seedLine(tester, 20, quantity: 3);
      await _pumpApp(tester, auth, ready: _hasTiles);
      final stringTick = find.descendant(
        of: _tile(_string),
        matching: find.byType(Checkbox),
      );
      await tester.tap(stringTick);
      await _until(
        tester,
        () => tester.widget<Checkbox>(stringTick).value == false,
        reason: 'bỏ chọn phải được ghi xong trước khi xóa',
      );

      await _swipe(tester, _string);
      await _untilDb(
        tester,
        () async => (await _queryLines()).every((r) => r['product_id'] != 20),
        reason: 'món chưa bị xóa khỏi SQLite',
      );
      // The SnackBar only appears after the delete has been written.
      await _until(
        tester,
        () => find.text('Hoàn tác').evaluate().isNotEmpty,
        reason: 'thanh Hoàn tác chưa hiện',
      );
      await tester.pump(
        const Duration(milliseconds: 400),
      ); // SnackBar slides in
      await tester.tap(find.text('Hoàn tác'));
      await tester.pump();
      await _untilDb(
        tester,
        () async => (await _queryLines()).any((r) => r['product_id'] == 20),
        reason: 'Hoàn tác chưa ghi lại SQLite',
      );

      await _quitApp(tester);
      auth = await _restoreSession(tester);
      await _pumpApp(tester, auth, ready: _hasTiles);

      expect(find.text(_string), findsOneWidget);
      expect(
        find.descendant(of: _tile(_string), matching: find.text('3')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(
                of: _tile(_string),
                matching: find.byType(Checkbox),
              ),
            )
            .value,
        isFalse,
        reason: 'Hoàn tác giữ nguyên trạng thái bỏ chọn',
      );
      await _finish(tester);
    },
  );

  testWidgets('xóa hết món rồi thoát app mở lại: vẫn là giỏ trống', (
    tester,
  ) async {
    var auth = await _restoreSession(tester);
    await _pumpApp(tester, auth, ready: _hasTiles);

    await _swipe(tester, _grip);
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
    await tester.pump(
      const Duration(seconds: 5),
    ); // the Undo window has expired
    await _untilDb(
      tester,
      () async => (await _queryLines()).isEmpty,
      reason: 'món chưa bị xóa khỏi SQLite',
    );

    await _quitApp(tester);
    auth = await _restoreSession(tester);
    await _pumpApp(tester, auth, ready: _isEmptyCart);

    expect(find.byType(CartItemTile), findsNothing);
    expect(find.byType(CartSummaryBar), findsNothing);
    await _finish(tester);
  });

  testWidgets('giỏ trống: "Khám phá sản phẩm" chuyển sang tab Cửa hàng', (
    tester,
  ) async {
    final auth = await _restoreSession(tester);
    await tester.runAsync(() async {
      final db = await _db();
      await db.delete(DbSchema.cartItems);
    });
    await _pumpApp(tester, auth, ready: _isEmptyCart);

    await tester.tap(find.text('Khám phá sản phẩm'));
    await tester.pump();
    await _until(
      tester,
      () => find.byType(ProductCard).evaluate().isNotEmpty,
      reason: 'tab Cửa hàng chưa nạp sản phẩm',
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, AppTab.shop.index);
    await _finish(tester);
  });

  group('sản phẩm nhiều size', () {
    const shoeName = 'Yonex Power Cushion 65 Z3'; // product 10, size 39-44
    const header = '3 size trong giỏ';

    Future<void> seedShoes(WidgetTester tester) async {
      await _seedLine(tester, 10, size: '41');
      await _seedLine(tester, 10, size: '42', quantity: 2);
      await _seedLine(tester, 10, size: '43', quantity: 3);
    }

    /// Waits until the shoe's size set in SQLite satisfies [ok].
    Future<void> shoesInDb(
      WidgetTester tester,
      bool Function(Set<String> sizes) ok,
      String reason,
    ) async {
      var good = false;
      for (var i = 0; i < 200 && !good; i++) {
        final sizes = (await tester.runAsync(() async {
          final rows = await _queryLines();
          return {
            for (final r in rows)
              if (r['product_id'] == 10) r['size'] as String,
          };
        }))!;
        good = ok(sizes);
        if (!good) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
        }
      }
      expect(good, isTrue, reason: reason);
    }

    testWidgets(
      'vuốt phần đầu thẻ xóa mọi size; thoát app mở lại vẫn mất hết',
      (tester) async {
        var auth = await _restoreSession(tester);
        await seedShoes(tester);
        await _pumpApp(tester, auth, ready: _hasTiles);
        expect(find.text(header), findsOneWidget);
        final shoePrice = (await tester.runAsync(() async {
          final db = await _db();
          final rows = await db.query(
            DbSchema.products,
            columns: ['price'],
            where: 'id = 10',
          );
          return rows.first['price'] as int;
        }))!;
        // grip 150.000 x 1 + shoe x (1 + 2 + 3)
        expect(
          _inBar(CurrencyFormatter.format(150000 + shoePrice * 6)),
          findsOneWidget,
        );

        await _swipe(tester, header);
        await shoesInDb(
          tester,
          (sizes) => sizes.isEmpty,
          'còn size trong SQLite',
        );
        await _until(
          tester,
          () => find.text('Đã xóa "$shoeName" (3 size)').evaluate().isNotEmpty,
          reason: 'SnackBar nêu tên sản phẩm và số size chưa hiện',
        );
        expect(_inBar('150.000₫'), findsOneWidget, reason: 'chỉ còn grip');

        await _quitApp(tester);
        auth = await _restoreSession(tester);
        await _pumpApp(tester, auth, ready: _hasTiles);

        expect(find.text(shoeName), findsNothing);
        expect(find.text(header), findsNothing);
        expect(find.byType(CartItemTile), findsOneWidget);
        await _finish(tester);
      },
    );

    testWidgets(
      'Hoàn tác cả nhóm: thoát app mở lại đủ size với đúng số lượng',
      (tester) async {
        var auth = await _restoreSession(tester);
        await seedShoes(tester);
        await _pumpApp(tester, auth, ready: _hasTiles);

        await _swipe(tester, header);
        await _until(
          tester,
          () => find.text('Hoàn tác').evaluate().isNotEmpty,
          reason: 'thanh Hoàn tác chưa hiện',
        );
        await tester.pump(
          const Duration(milliseconds: 400),
        ); // SnackBar slides in
        await tester.tap(find.text('Hoàn tác'));
        await tester.pump();
        await shoesInDb(
          tester,
          (sizes) => sizes.length == 3,
          'Hoàn tác chưa ghi đủ 3 size',
        );

        await _quitApp(tester);
        auth = await _restoreSession(tester);
        await _pumpApp(tester, auth, ready: _hasTiles);

        expect(find.text(header), findsOneWidget);
        for (final size in ['41', '42', '43']) {
          expect(find.text('Size: $size'), findsOneWidget);
        }
        final quantities =
            (await tester.runAsync(_queryLines))!
                .where((r) => r['product_id'] == 10)
                .map((r) => r['quantity'] as int)
                .toList()
              ..sort();
        expect(quantities, [1, 2, 3]);
        await _finish(tester);
      },
    );

    testWidgets('vuốt một dòng size chỉ xóa size đó, kể cả sau khi thoát app', (
      tester,
    ) async {
      var auth = await _restoreSession(tester);
      await seedShoes(tester);
      await _pumpApp(tester, auth, ready: _hasTiles);

      await _swipe(tester, 'Size: 42');
      await shoesInDb(
        tester,
        (sizes) => sizes.length == 2 && !sizes.contains('42'),
        'size 42 chưa bị xóa riêng',
      );
      expect(find.text('2 size trong giỏ'), findsOneWidget);

      await _quitApp(tester);
      auth = await _restoreSession(tester);
      await _pumpApp(tester, auth, ready: _hasTiles);

      expect(find.text('2 size trong giỏ'), findsOneWidget);
      expect(find.text('Size: 41'), findsOneWidget);
      expect(find.text('Size: 43'), findsOneWidget);
      expect(find.text('Size: 42'), findsNothing);
      await _finish(tester);
    });
  });

  testWidgets('món hết hàng trong DB hiển thị mờ và khóa nút Thanh toán', (
    tester,
  ) async {
    final auth = await _restoreSession(tester);
    await tester.runAsync(() async {
      final db = await _db();
      await db.update(DbSchema.products, {'stock': 0}, where: 'id = 19');
    });
    await _pumpApp(tester, auth, ready: _hasTiles);

    double opacityOf(Finder target) {
      var value = 1.0;
      final wrappers = find.ancestor(
        of: target,
        matching: find.byWidgetPredicate((w) => w is Opacity),
      );
      for (final element in wrappers.evaluate()) {
        value *= (element.widget as Opacity).opacity;
      }
      return value;
    }

    expect(opacityOf(find.text(_grip)), lessThan(1.0));
    expect(find.text('Đã hết hàng'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Thanh toán (1)'),
          )
          .onPressed,
      isNull,
      reason: 'món hết hàng đang chọn nên chưa cho thanh toán',
    );

    // Untick the sold-out item: still dimmed, but it no longer blocks checkout.
    await tester.tap(
      find.descendant(of: _tile(_grip), matching: find.byType(Checkbox)),
    );
    await _until(
      tester,
      () => find
          .widgetWithText(FilledButton, 'Thanh toán (0)')
          .evaluate()
          .isNotEmpty,
      reason: 'bỏ chọn phải được ghi xong',
    );
    expect(opacityOf(find.text(_grip)), lessThan(1.0));
    await _finish(tester);
  });

  testWidgets(
    'đăng xuất rồi đăng nhập tài khoản khác: không thấy giỏ người trước',
    (tester) async {
      final auth = await _restoreSession(tester);
      await _pumpApp(tester, auth, ready: _hasTiles);
      expect(find.text(_grip), findsOneWidget);

      await tester.runAsync(auth.logout);
      await _until(
        tester,
        _isEmptyCart,
        reason: 'đăng xuất phải xóa giỏ khỏi màn',
      );
      expect(find.text(_grip), findsNothing);

      await tester.runAsync(
        () => auth.login('newbie@smashly.com', 'Newbie@123'),
      );
      await _until(tester, _isEmptyCart, reason: 'giỏ của newbie đang trống');
      expect(find.text(_grip), findsNothing, reason: 'không lẫn giỏ customer');
      expect(find.byType(CartSummaryBar), findsNothing);

      await tester.runAsync(auth.logout);
      await tester.runAsync(
        () => auth.login('customer@smashly.com', 'Customer@123'),
      );
      await _until(tester, _hasTiles, reason: 'giỏ customer phải quay lại');
      expect(find.text(_grip), findsOneWidget);
      await _finish(tester);
    },
  );
}
