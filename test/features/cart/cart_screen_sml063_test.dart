import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/features/cart/widgets/cart_item_tile.dart';
import 'package:smashly/features/cart/widgets/cart_summary_bar.dart';
import 'package:smashly/features/cart/widgets/quantity_stepper.dart';

import 'cart_screen_test.dart' show FakeCartRepository, item, pumpCart;

/// SML-063 · UC11 · Màn Cart (S07): chọn tất cả, stepper, vuốt xóa + Undo,
/// item hết hàng mờ, thanh tổng tiền, empty state.
/// Tiêu chí: tổng tiền chỉ tính món được chọn; thoát app mở lại giỏ vẫn còn
/// (phần này nằm ở test/integration/cart_screen_sml063_test.dart).
void main() {
  Finder tile(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(CartItemTile));

  Finder inBar(String text) => find.descendant(
    of: find.byType(CartSummaryBar),
    matching: find.text(text),
  );

  Finder checkboxOf(String name) =>
      find.descendant(of: tile(name), matching: find.byType(Checkbox));

  Finder buttonOf(String name, IconData icon) => find.descendant(
    of: tile(name),
    matching: find.widgetWithIcon(IconButton, icon),
  );

  bool enabled(WidgetTester tester, Finder button) =>
      tester.widget<IconButton>(button).onPressed != null;

  bool? ticked(WidgetTester tester, Finder checkbox) =>
      tester.widget<Checkbox>(checkbox).value;

  /// Nút "Thanh toán (n)" có bấm được không.
  bool canPay(WidgetTester tester, int count) {
    final pay = find.widgetWithText(FilledButton, 'Thanh toán ($count)');
    expect(pay, findsOneWidget);
    return tester.widget<FilledButton>(pay).onPressed != null;
  }

  Future<void> swipe(WidgetTester tester, String name) async {
    await tester.drag(find.text(name), const Offset(-600, 0));
    await tester.pumpAndSettle();
  }

  group('chọn tất cả', () {
    testWidgets(
      'bỏ chọn rồi chọn lại tất cả: tổng tiền và nút Thanh toán theo',
      (tester) async {
        final cart = await pumpCart(
          tester,
          FakeCartRepository([item(1), item(2, price: 250000, quantity: 2)]),
        );
        final selectAll = find.byType(Checkbox).first;
        expect(ticked(tester, selectAll), isTrue);
        expect(inBar('600.000₫'), findsOneWidget);

        await tester.tap(selectAll);
        await tester.pumpAndSettle();

        expect(cart.selectedCount, 0);
        expect(ticked(tester, selectAll), isFalse);
        expect(inBar('0₫'), findsOneWidget);
        expect(canPay(tester, 0), isFalse, reason: 'chưa chọn món nào');

        await tester.tap(selectAll);
        await tester.pumpAndSettle();

        expect(cart.selectedCount, 2);
        expect(inBar('600.000₫'), findsOneWidget);
        expect(canPay(tester, 2), isTrue);
      },
    );

    testWidgets('bỏ một món thì ô chọn tất cả tự bỏ tick, đủ lại thì tự tick', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository([item(1), item(2)]));
      final selectAll = find.byType(Checkbox).first;

      await tester.tap(checkboxOf('Vợt 2'));
      await tester.pumpAndSettle();
      expect(ticked(tester, selectAll), isFalse);

      await tester.tap(checkboxOf('Vợt 2'));
      await tester.pumpAndSettle();
      expect(ticked(tester, selectAll), isTrue);
    });

    testWidgets('bỏ hết rồi chọn riêng một món: tổng chỉ tính món đó', (
      tester,
    ) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(1), item(2, price: 250000, quantity: 2)]),
      );
      await tester.tap(find.byType(Checkbox).first); // bỏ tất cả
      await tester.pumpAndSettle();

      await tester.tap(checkboxOf('Vợt 2'));
      await tester.pumpAndSettle();

      expect(inBar('500.000₫'), findsOneWidget);
      expect(canPay(tester, 1), isTrue);
    });

    testWidgets('có món hết hàng: khóa Thanh toán, bỏ chọn món đó thì mở lại', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository([item(1), item(2, stock: 0)]));

      expect(canPay(tester, 2), isFalse);
      expect(
        find.text('Bỏ chọn hoặc giảm số lượng món hết hàng để thanh toán.'),
        findsOneWidget,
      );

      await tester.tap(checkboxOf('Vợt 2'));
      await tester.pumpAndSettle();

      expect(canPay(tester, 1), isTrue);
      expect(
        inBar('100.000₫'),
        findsOneWidget,
        reason: 'không tính món hết hàng',
      );
      expect(
        find.text('Bỏ chọn hoặc giảm số lượng món hết hàng để thanh toán.'),
        findsNothing,
      );
    });
  });

  group('tổng tiền chỉ tính món được chọn', () {
    testWidgets('đổi số lượng món chưa chọn không làm đổi tổng', (
      tester,
    ) async {
      await pumpCart(
        tester,
        FakeCartRepository([
          item(1, price: 100000),
          item(2, price: 250000, quantity: 2),
          item(3, price: 40000, quantity: 3),
        ]),
      );
      expect(inBar('720.000₫'), findsOneWidget); // 100k + 500k + 120k

      await tester.tap(checkboxOf('Vợt 2'));
      await tester.pumpAndSettle();
      expect(inBar('220.000₫'), findsOneWidget);

      await tester.tap(buttonOf('Vợt 1', Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(inBar('320.000₫'), findsOneWidget, reason: 'món đã chọn tăng');

      await tester.tap(buttonOf('Vợt 2', Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(inBar('320.000₫'), findsOneWidget, reason: 'món chưa chọn: giữ');
    });

    testWidgets('xóa món chưa chọn không đổi tổng, xóa món đã chọn thì giảm', (
      tester,
    ) async {
      await pumpCart(
        tester,
        FakeCartRepository([
          item(1, price: 100000),
          item(2, price: 250000),
          item(3, price: 40000, quantity: 3),
        ]),
      );
      await tester.tap(checkboxOf('Vợt 2'));
      await tester.pumpAndSettle();
      expect(inBar('220.000₫'), findsOneWidget);

      await swipe(tester, 'Vợt 2');
      expect(inBar('220.000₫'), findsOneWidget, reason: 'xóa món chưa chọn');

      await swipe(tester, 'Vợt 3');
      expect(inBar('100.000₫'), findsOneWidget, reason: 'xóa món đã chọn');
    });

    testWidgets('số lớn hiển thị đúng định dạng nghìn', (tester) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(1, price: 2890000, quantity: 3)]),
      );

      expect(inBar('8.670.000₫'), findsOneWidget);
    });
  });

  group('stepper', () {
    testWidgets('− khóa ở 1, + khóa khi chạm tồn kho', (tester) async {
      await pumpCart(tester, FakeCartRepository([item(1, stock: 3)]));
      final minus = buttonOf('Vợt 1', Icons.remove_rounded);
      final plus = buttonOf('Vợt 1', Icons.add_rounded);
      expect(enabled(tester, minus), isFalse, reason: 'đang là 1');
      expect(enabled(tester, plus), isTrue);

      await tester.tap(plus);
      await tester.pumpAndSettle();
      await tester.tap(plus);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: tile('Vợt 1'), matching: find.text('3')),
        findsOneWidget,
      );
      expect(enabled(tester, plus), isFalse, reason: 'đã bằng tồn kho 3');
      expect(enabled(tester, minus), isTrue);
    });

    testWidgets('kho lớn hơn 99 vẫn dừng ở 99 mỗi dòng', (tester) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(1, stock: 500, quantity: 98)]),
      );
      final plus = buttonOf('Vợt 1', Icons.add_rounded);

      await tester.tap(plus);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: tile('Vợt 1'), matching: find.text('99')),
        findsOneWidget,
      );
      expect(enabled(tester, plus), isFalse);
    });

    testWidgets('bấm − giảm số lượng và cập nhật tổng', (tester) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(1, price: 100000, quantity: 3)]),
      );
      expect(inBar('300.000₫'), findsOneWidget);

      await tester.tap(buttonOf('Vợt 1', Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(inBar('200.000₫'), findsOneWidget);
    });
  });

  group('vuốt xóa + Hoàn tác', () {
    testWidgets(
      'xóa món cuối: hiện trạng thái rỗng, Hoàn tác đưa giỏ trở lại',
      (tester) async {
        await pumpCart(tester, FakeCartRepository([item(1)]));

        await swipe(tester, 'Vợt 1');
        expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
        expect(find.byType(CartSummaryBar), findsNothing);

        await tester.tap(find.text('Hoàn tác'));
        await tester.pumpAndSettle();

        expect(find.text('Giỏ hàng đang trống'), findsNothing);
        expect(find.text('Vợt 1'), findsOneWidget);
        expect(find.byType(CartSummaryBar), findsOneWidget);
      },
    );

    // Trạng thái chọn sau Hoàn tác cần DB thật (bản giả không lưu is_selected):
    // xem test/integration/cart_screen_sml063_test.dart.
    testWidgets('Hoàn tác giữ nguyên số lượng và tổng tiền', (tester) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(1, quantity: 3), item(2)]),
      );
      expect(inBar('400.000₫'), findsOneWidget);

      await swipe(tester, 'Vợt 1');
      expect(inBar('100.000₫'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: tile('Vợt 1'), matching: find.text('3')),
        findsOneWidget,
      );
      expect(inBar('400.000₫'), findsOneWidget);
    });

    testWidgets(
      'xóa hai món liên tiếp: Hoàn tác chỉ khôi phục món xóa sau cùng',
      (tester) async {
        // Giới hạn hiện tại: CartProvider chỉ nhớ MỘT món vừa xóa (_lastRemoved).
        await pumpCart(tester, FakeCartRepository([item(1), item(2), item(3)]));

        await swipe(tester, 'Vợt 1');
        await swipe(tester, 'Vợt 2');
        await tester.tap(find.text('Hoàn tác'));
        await tester.pumpAndSettle();

        expect(find.text('Vợt 2'), findsOneWidget);
        expect(find.text('Vợt 3'), findsOneWidget);
        expect(
          find.text('Vợt 1'),
          findsNothing,
          reason: 'không còn hoàn tác được',
        );
      },
    );

    testWidgets('xóa rồi không hoàn tác: SnackBar tự tắt, món vẫn mất', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository([item(1), item(2)]));

      await swipe(tester, 'Vợt 1');
      expect(find.text('Hoàn tác'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Hoàn tác'), findsNothing);
      expect(find.text('Vợt 1'), findsNothing);
      expect(find.text('Vợt 2'), findsOneWidget);
    });
  });

  group('trạng thái rỗng', () {
    testWidgets('giỏ trống: có lời mời mua sắm, không có thanh tổng tiền', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository([]));

      expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
      expect(find.text('Khám phá sản phẩm'), findsOneWidget);
      expect(find.byType(CartSummaryBar), findsNothing);
      expect(find.byType(CartItemTile), findsNothing);
    });
  });

  group('món hết hàng', () {
    /// Độ trong suốt tích lũy của mọi Opacity / AnimatedOpacity bao quanh [target].
    double opacityOf(Finder target) {
      var value = 1.0;
      final wrappers = find.ancestor(
        of: target,
        matching: find.byWidgetPredicate(
          (w) => w is Opacity || w is AnimatedOpacity,
        ),
      );
      for (final element in wrappers.evaluate()) {
        final w = element.widget;
        value *= w is Opacity ? w.opacity : (w as AnimatedOpacity).opacity;
      }
      return value;
    }

    testWidgets('món hết hàng hiển thị mờ, món còn hàng rõ nét', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository([item(1), item(2, stock: 0)]));

      expect(opacityOf(find.text('Vợt 1')), 1.0);
      expect(opacityOf(find.text('Vợt 2')), lessThan(1.0));
    });

    testWidgets('mờ cả ảnh, tên, giá và stepper; ô chọn và cảnh báo giữ rõ', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository([item(1, stock: 0)]));
      final inTile = find.byType(CartItemTile);

      for (final dimmed in [
        find.descendant(of: inTile, matching: find.byType(CartThumbnail)),
        find.descendant(of: inTile, matching: find.text('Vợt 1')),
        find.descendant(of: inTile, matching: find.text('100.000₫')),
        find.descendant(of: inTile, matching: find.byType(QuantityStepper)),
      ]) {
        expect(opacityOf(dimmed), lessThan(1.0));
      }
      expect(opacityOf(find.byType(Checkbox).last), 1.0);
      expect(opacityOf(find.text('Đã hết hàng')), 1.0);
    });

    testWidgets('món hết hàng vẫn bỏ chọn được dù đang mờ', (tester) async {
      final cart = await pumpCart(
        tester,
        FakeCartRepository([item(1), item(2, stock: 0)]),
      );
      expect(cart.hasUnavailableSelected, isTrue);

      await tester.tap(checkboxOf('Vợt 2'));
      await tester.pumpAndSettle();

      expect(cart.hasUnavailableSelected, isFalse);
      expect(opacityOf(find.text('Vợt 2')), lessThan(1.0));
    });

    testWidgets('chỉ còn ít hàng (chưa hết) thì không bị mờ', (tester) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(1, stock: 2, quantity: 3)]),
      );

      expect(find.text('Chỉ còn 2 sản phẩm'), findsOneWidget);
      expect(opacityOf(find.text('Vợt 1')), 1.0);
    });

    testWidgets('sản phẩm nhiều size hết hàng: đầu thẻ và từng size đều mờ', (
      tester,
    ) async {
      await pumpCart(
        tester,
        FakeCartRepository([
          item(1, productId: 5, size: '41', stock: 0),
          item(2, productId: 5, size: '42', stock: 0),
        ]),
      );

      expect(opacityOf(find.text('Vợt 1')), lessThan(1.0)); // tên sản phẩm
      expect(opacityOf(find.byType(CartThumbnail)), lessThan(1.0));
      for (final size in ['Size: 41', 'Size: 42']) {
        expect(opacityOf(find.text(size)), lessThan(1.0));
      }
      for (final stepper in find.byType(QuantityStepper).evaluate()) {
        expect(opacityOf(find.byWidget(stepper.widget)), lessThan(1.0));
      }
      expect(find.text('Đã hết hàng'), findsNWidgets(2));
      expect(opacityOf(find.text('Đã hết hàng').first), 1.0);
    });

    testWidgets('sản phẩm nhiều size còn hàng: không mờ chỗ nào', (
      tester,
    ) async {
      await pumpCart(
        tester,
        FakeCartRepository([
          item(1, productId: 5, size: '41'),
          item(2, productId: 5, size: '42'),
        ]),
      );

      expect(opacityOf(find.text('Vợt 1')), 1.0);
      expect(opacityOf(find.text('Size: 41')), 1.0);
      expect(opacityOf(find.byType(QuantityStepper).first), 1.0);
    });

    testWidgets('món hết hàng có cảnh báo chữ, không chỉ dựa vào màu', (
      tester,
    ) async {
      await pumpCart(tester, FakeCartRepository([item(1, stock: 0)]));

      expect(find.text('Đã hết hàng'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
