import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/models/cart_item.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/features/cart/cart_screen.dart';
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

CartItem item(int id, {int price = 100000, int quantity = 1, int stock = 5}) =>
    CartItem(
      id: id,
      productId: id,
      name: 'Vợt $id',
      imagePath: 'assets/none.png',
      price: price,
      stock: stock,
      quantity: quantity,
      size: '',
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
    // Thu gọn dần chứ không nhảy: có ít nhất một khung nằm giữa hai đầu.
    expect(samples.any((y) => y < before && y > after), isTrue);

    // Đang animate vẫn bấm được món khác.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(find.text('Vợt 1'), findsNothing);
  });

  testWidgets('undo snackbar counts down and disappears after 4 seconds', (
    tester,
  ) async {
    await pumpCart(tester, FakeCartRepository([item(1), item(2)]));

    await tester.drag(find.text('Vợt 1'), const Offset(-600, 0));
    // Chờ dòng trượt + thu gọn xong thì SnackBar mới hiện.
    for (var i = 0; i < 30 && find.text('Hoàn tác').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hoàn tác'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, lessThan(1)); // đang chạy
    expect(bar.value, greaterThan(0));

    await tester.pump(const Duration(seconds: 3)); // ~3,5 s: còn
    expect(find.text('Hoàn tác'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2)); // quá 4 s: tắt
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
}
