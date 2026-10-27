import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/models/cart_item.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/features/cart/cart_screen.dart';
import 'package:smashly/features/cart/widgets/cart_brand_header.dart';
import 'package:smashly/features/cart/widgets/cart_item_tile.dart';
import 'package:smashly/features/cart/widgets/cart_product_group.dart';
import 'package:smashly/features/cart/widgets/cart_skeleton.dart';
import 'package:smashly/providers/cart_provider.dart';

/// Giỏ trong bộ nhớ; `implements` để thêm method public vào CartRepository
/// thì file này lỗi biên dịch.
class FakeCartRepository implements CartRepository {
  FakeCartRepository(this.items);

  List<CartItem> items;
  Object? loadError;

  /// Có giá trị: loadItems treo tới khi test gọi complete.
  Completer<void>? hold;

  @override
  Future<List<CartItem>> loadItems(int userId) async {
    await hold?.future;
    await hold?.future;
    if (loadError != null) throw loadError!;
    return [...items];
  }

  @override
  Future<void> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
    String size = '',
  }) async {}

  @override
  Future<void> setQuantity(CartItem item, int quantity) async {}

  @override
  Future<void> setSelected(CartItem item, bool selected) async {}

  @override
  Future<void> setAllSelected(int userId, bool selected) async {}

  @override
  Future<void> remove(CartItem item) async => items.remove(item);

  @override
  Future<void> restore(int userId, CartItem item) async => items.add(item);
}

CartItem item(
  int id, {
  int price = 100000,
  int quantity = 1,
  int stock = 5,
  int? productId,
  String size = '',
  String brand = '',
}) => CartItem(
  id: id,
  productId: productId ?? id,
  brand: brand,
  name: 'Vợt $id',
  imagePath: 'assets/none.png',
  price: price,
  stock: stock,
  quantity: quantity,
  size: size,
  isSelected: true,
);

Future<CartProvider> pumpCart(
  WidgetTester tester,
  FakeCartRepository repo,
) async {
  final cart = CartProvider(repo)..updateUser(2);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: cart,
      child: MaterialApp(theme: AppTheme.light, home: const CartScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return cart;
}

void main() {
  testWidgets('loading shows skeleton, then the items', (tester) async {
    final repo = FakeCartRepository([item(1)])..hold = Completer<void>();
    final cart = CartProvider(repo)..updateUser(2);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(theme: AppTheme.light, home: const CartScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CartSkeleton), findsOneWidget);
    expect(find.text('Vợt 1'), findsNothing);

    repo.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CartSkeleton), findsNothing);
    expect(find.text('Vợt 1'), findsOneWidget);
  });

  testWidgets('empty cart shows empty state', (tester) async {
    await pumpCart(tester, FakeCartRepository([]));
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
    expect(find.textContaining('Thanh toán'), findsNothing);
  });

  testWidgets('load error shows error state with retry', (tester) async {
    final repo = FakeCartRepository([])..loadError = Exception('boom');
    await pumpCart(tester, repo);
    expect(find.text('Thử lại'), findsOneWidget);

    repo
      ..loadError = null
      ..items = [item(1)];
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Vợt 1'), findsOneWidget);
  });

  testWidgets('shows items, total and updates on stepper/select', (
    tester,
  ) async {
    await pumpCart(
      tester,
      FakeCartRepository([item(1), item(2, price: 250000, quantity: 2)]),
    );
    expect(find.text('Vợt 1'), findsOneWidget);
    expect(find.text('Thanh toán (2)'), findsOneWidget);
    expect(find.text('600.000₫'), findsOneWidget);

    await tester.tap(find.byTooltip('Tăng số lượng').first);
    await tester.pumpAndSettle();
    expect(find.text('700.000₫'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first); // chọn tất cả -> bỏ chọn
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán (0)'), findsOneWidget);
    final pay = find.widgetWithText(FilledButton, 'Thanh toán (0)');
    expect(tester.widget<FilledButton>(pay).onPressed, isNull);
  });

  testWidgets('sold out selected item blocks checkout', (tester) async {
    await pumpCart(tester, FakeCartRepository([item(1, stock: 0)]));
    expect(find.text('Đã hết hàng'), findsOneWidget);
    final pay = find.widgetWithText(FilledButton, 'Thanh toán (1)');
    expect(tester.widget<FilledButton>(pay).onPressed, isNull);
  });

  testWidgets('swipe deletes with undo snackbar', (tester) async {
    await pumpCart(tester, FakeCartRepository([item(1), item(2)]));

    await tester.drag(find.text('Vợt 1'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Vợt 1'), findsNothing);
    expect(find.text('Hoàn tác'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('Vợt 1'), findsOneWidget);
  });

  testWidgets('removed row collapses and the list stays tappable', (
    tester,
  ) async {
    await pumpCart(tester, FakeCartRepository([item(1), item(2)]));
    double lowerRowY() => tester.getTopLeft(find.text('Vợt 2')).dy;
    final before = lowerRowY();

    await tester.drag(find.text('Vợt 1'), const Offset(-600, 0));
    final samples = <double>[];
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      samples.add(lowerRowY());
    }
    final after = samples.last;

    expect(after, lessThan(before));
    expect(samples.any((y) => y < before && y > after), isTrue);

    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(find.text('Vợt 1'), findsNothing);
  });

  testWidgets('undo snackbar counts down and disappears after 4 seconds', (
    tester,
  ) async {
    await pumpCart(tester, FakeCartRepository([item(1), item(2)]));

    await tester.drag(find.text('Vợt 1'), const Offset(-600, 0));
    for (var i = 0; i < 30 && find.text('Hoàn tác').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hoàn tác'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, lessThan(1));
    expect(bar.value, greaterThan(0));

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Hoàn tác'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Hoàn tác'), findsNothing);
  });

  testWidgets('typing a quantity updates the total, capped by stock', (
    tester,
  ) async {
    await pumpCart(
      tester,
      FakeCartRepository([item(1, price: 100000, stock: 5)]),
    );
    expect(find.text('100.000₫'), findsWidgets);

    await tester.tap(find.byTooltip('Nhập số lượng'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '99');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '5',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('500.000₫'), findsOneWidget);
  });

  group('same product in several sizes', () {
    List<CartItem> shoes() => [
      item(1, productId: 10, size: '42'),
      item(2, productId: 10, size: '43'),
    ];

    testWidgets('shows one card with a row per size', (tester) async {
      await pumpCart(tester, FakeCartRepository([...shoes(), item(3)]));

      expect(find.text('Vợt 1'), findsOneWidget);
      expect(find.text('2 size trong giỏ'), findsOneWidget);
      expect(find.text('Size: 42'), findsOneWidget);
      expect(find.text('Size: 43'), findsOneWidget);
      expect(find.text('Vợt 3'), findsOneWidget);
      expect(find.byType(CartProductGroup), findsOneWidget);
      expect(find.byType(CartItemTile), findsOneWidget);
    });

    testWidgets('a single size keeps the plain card', (tester) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(1, productId: 10, size: '42')]),
      );

      expect(find.byType(CartProductGroup), findsNothing);
      expect(find.byType(CartItemTile), findsOneWidget);
    });

    testWidgets('group checkbox selects and clears every size', (tester) async {
      await pumpCart(tester, FakeCartRepository(shoes()));
      expect(find.text('Thanh toán (2)'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Thanh toán (0)'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Thanh toán (2)'), findsOneWidget);
    });

    testWidgets('one size unticked makes the group checkbox mixed', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository(shoes()));

      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isNull,
      );
      expect(find.text('Thanh toán (1)'), findsOneWidget);
    });

    testWidgets('quantity changes only the size that was tapped', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository(shoes()));

      await tester.tap(find.byTooltip('Tăng số lượng').first);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('300.000₫'), findsOneWidget);
    });

    testWidgets('swiping a size removes only that size', (tester) async {
      await pumpCart(tester, FakeCartRepository(shoes()));

      await tester.drag(find.text('Size: 42'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(find.text('Size: 42'), findsNothing);
      expect(find.text('Vợt 2'), findsOneWidget);
      expect(find.byType(CartProductGroup), findsNothing);
      expect(find.byType(CartItemTile), findsOneWidget);
      expect(find.text('Hoàn tác'), findsOneWidget);
    });
  });

  group('brand sections', () {
    List<CartItem> mixed() => [
      item(1, brand: 'Yonex'),
      item(2, brand: 'Victor'),
      item(3, brand: 'Yonex'),
    ];

    testWidgets('one header per brand, products listed under it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpCart(tester, FakeCartRepository(mixed()));

      expect(find.byType(CartBrandHeader), findsNWidgets(2));
      expect(find.text('Yonex'), findsOneWidget);
      expect(find.text('Victor'), findsOneWidget);

      final yonexHeader = tester.getTopLeft(find.text('Yonex')).dy;
      final victorHeader = tester.getTopLeft(find.text('Victor')).dy;
      final racket1 = tester.getTopLeft(find.text('Vợt 1')).dy;
      final racket3 = tester.getTopLeft(find.text('Vợt 3')).dy;
      final racket2 = tester.getTopLeft(find.text('Vợt 2')).dy;
      expect(yonexHeader, lessThan(racket1));
      expect(racket1, lessThan(racket3));
      expect(racket3, lessThan(victorHeader));
      expect(victorHeader, lessThan(racket2));
    });

    testWidgets('items without a brand get no header', (tester) async {
      await pumpCart(tester, FakeCartRepository([item(1), item(2)]));

      expect(find.byType(CartBrandHeader), findsNothing);
    });

    testWidgets('brand checkbox selects and clears only that brand', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository(mixed()));
      expect(find.text('Thanh toán (3)'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('brand-Yonex')),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thanh toán (1)'), findsOneWidget);
    });

    testWidgets('one product unticked makes the brand checkbox mixed', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository(mixed()));

      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      final header = find.descendant(
        of: find.byKey(const ValueKey('brand-Yonex')),
        matching: find.byType(Checkbox),
      );
      expect(tester.widget<Checkbox>(header).value, isNull);
    });

    testWidgets('sizes of one product stay together under the brand', (
      tester,
    ) async {
      await pumpCart(
        tester,
        FakeCartRepository([
          item(1, productId: 10, size: '42', brand: 'Yonex'),
          item(2, productId: 10, size: '43', brand: 'Yonex'),
          item(3, brand: 'Yonex'),
        ]),
      );

      expect(find.byType(CartBrandHeader), findsOneWidget);
      expect(find.byType(CartProductGroup), findsOneWidget);
      expect(find.byType(CartItemTile), findsOneWidget);
    });
  });
}
