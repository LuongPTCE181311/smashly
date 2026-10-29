import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/models/cart_item.dart';
import 'package:smashly/features/cart/widgets/cart_item_tile.dart';
import 'package:smashly/features/cart/widgets/cart_product_group.dart';
import 'package:smashly/features/cart/widgets/cart_summary_bar.dart';
import 'package:smashly/features/cart/widgets/quantity_stepper.dart';

import 'cart_screen_test.dart' show FakeCartRepository, item, pumpCart;

/// Vuốt thẻ sản phẩm nhiều size: vuốt phần đầu thẻ xóa cả sản phẩm (mọi size),
/// vuốt một dòng size chỉ xóa size đó; Hoàn tác khôi phục trọn nhóm.
void main() {
  Finder inBar(String text) => find.descendant(
    of: find.byType(CartSummaryBar),
    matching: find.text(text),
  );

  Future<void> swipeLeft(WidgetTester tester, Finder target) async {
    await tester.drag(target, const Offset(-700, 0));
    await tester.pumpAndSettle();
  }

  // Sản phẩm 5 có 3 size trong giỏ, mỗi size 100.000₫ x số lượng.
  List<CartItem> shoes({int stock = 10}) => [
    item(1, productId: 5, size: '41', quantity: 1, stock: stock),
    item(2, productId: 5, size: '42', quantity: 2, stock: stock),
    item(3, productId: 5, size: '43', quantity: 3, stock: stock),
  ];

  final header = find.text('3 size trong giỏ');

  group('vuốt phần đầu thẻ: xóa cả sản phẩm', () {
    testWidgets('mọi size biến mất, sản phẩm khác giữ nguyên', (tester) async {
      final cart = await pumpCart(
        tester,
        FakeCartRepository([item(9, productId: 9), ...shoes()]),
      );
      expect(find.byType(CartProductGroup), findsOneWidget);

      await swipeLeft(tester, header);

      expect(find.byType(CartProductGroup), findsNothing);
      expect(find.text('Size: 41'), findsNothing);
      expect(find.text('Size: 42'), findsNothing);
      expect(find.text('Size: 43'), findsNothing);
      expect(find.text('Vợt 9'), findsOneWidget, reason: 'sản phẩm khác còn');
      expect(cart.items.map((i) => i.id), [9]);
    });

    testWidgets('tổng tiền chỉ còn các món còn lại', (tester) async {
      await pumpCart(
        tester,
        FakeCartRepository([item(9, productId: 9, price: 50000), ...shoes()]),
      );
      // 50.000 + 100.000 x (1 + 2 + 3)
      expect(inBar('650.000₫'), findsOneWidget);

      await swipeLeft(tester, header);

      expect(inBar('50.000₫'), findsOneWidget);
    });

    testWidgets(
      'xóa hết giỏ khi đó là sản phẩm duy nhất: hiện trạng thái rỗng',
      (tester) async {
        await pumpCart(tester, FakeCartRepository(shoes()));

        await swipeLeft(tester, header);

        expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
        expect(find.byType(CartSummaryBar), findsNothing);
      },
    );

    testWidgets('SnackBar nêu tên sản phẩm và số size đã xóa', (tester) async {
      await pumpCart(tester, FakeCartRepository(shoes()));

      await swipeLeft(tester, header);

      expect(find.text('Đã xóa "Vợt 1" (3 size)'), findsOneWidget);
      expect(find.text('Hoàn tác'), findsOneWidget);
    });

    testWidgets('Hoàn tác khôi phục đủ mọi size với đúng số lượng', (
      tester,
    ) async {
      final cart = await pumpCart(tester, FakeCartRepository(shoes()));

      await swipeLeft(tester, header);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();

      expect(find.byType(CartProductGroup), findsOneWidget);
      expect(cart.items.map((i) => i.size).toSet(), {'41', '42', '43'});
      expect(cart.items.map((i) => i.quantity).toList()..sort(), [1, 2, 3]);
      expect(inBar('600.000₫'), findsOneWidget);
    });

    testWidgets(
      'xóa nhóm rồi xóa một món khác: Hoàn tác chỉ lấy lại lần xóa cuối',
      (tester) async {
        // Giữ hành vi cũ: mỗi lần chỉ hoàn tác được lần xóa gần nhất.
        final cart = await pumpCart(
          tester,
          FakeCartRepository([item(9, productId: 9), ...shoes()]),
        );

        await swipeLeft(tester, header);
        await swipeLeft(tester, find.text('Vợt 9'));
        await tester.tap(find.text('Hoàn tác'));
        await tester.pumpAndSettle();

        expect(cart.items.map((i) => i.id), [9]);
        expect(find.byType(CartProductGroup), findsNothing);
      },
    );

    testWidgets('lỗi ghi DB: cả nhóm quay lại đúng vị trí và có báo lỗi', (
      tester,
    ) async {
      final repo = FakeCartRepository([
        item(9, productId: 9),
        ...shoes(),
        item(8, productId: 8),
      ])..removeError = const AppException('Không thể xóa sản phẩm');
      final cart = await pumpCart(tester, repo);
      final before = cart.items.map((i) => i.id).toList();

      await tester.drag(header, const Offset(-700, 0));
      await tester.pumpAndSettle();

      expect(
        cart.items.map((i) => i.id).toList(),
        before,
        reason: 'đủ 5 dòng, đúng thứ tự cũ',
      );
      expect(find.byType(CartProductGroup), findsOneWidget);
      expect(find.text('Không thể xóa sản phẩm'), findsOneWidget);
      expect(find.text('Hoàn tác'), findsNothing);
    });

    testWidgets(
      'vuốt qua trái ít (chưa đủ ngưỡng) thì thẻ trượt về, không xóa',
      (tester) async {
        await pumpCart(tester, FakeCartRepository(shoes()));

        await tester.drag(header, const Offset(-40, 0));
        await tester.pumpAndSettle();

        expect(find.byType(CartProductGroup), findsOneWidget);
        expect(find.text('Hoàn tác'), findsNothing);
      },
    );

    testWidgets('vuốt sang phải không xóa', (tester) async {
      await pumpCart(tester, FakeCartRepository(shoes()));

      await tester.drag(header, const Offset(700, 0));
      await tester.pumpAndSettle();

      expect(find.byType(CartProductGroup), findsOneWidget);
    });
  });

  group('vẫn giữ vuốt từng dòng size', () {
    testWidgets('vuốt một dòng size chỉ xóa size đó, các size khác còn', (
      tester,
    ) async {
      final cart = await pumpCart(tester, FakeCartRepository(shoes()));

      await swipeLeft(tester, find.text('Size: 42'));

      expect(cart.items.map((i) => i.size), ['41', '43']);
      expect(find.text('Size: 42'), findsNothing);
      expect(find.byType(CartProductGroup), findsOneWidget);
      expect(find.text('2 size trong giỏ'), findsOneWidget);
      expect(
        find.text('Đã xóa "Vợt 2"'),
        findsOneWidget,
        reason: 'tên dòng vừa xóa, không có hậu tố (n size)',
      );
    });

    testWidgets('vuốt dòng size cuối cùng còn lại: thẻ về dạng thẻ đơn', (
      tester,
    ) async {
      final cart = await pumpCart(tester, FakeCartRepository(shoes()));

      await swipeLeft(tester, find.text('Size: 41'));
      await swipeLeft(tester, find.text('Size: 42'));

      expect(cart.items.map((i) => i.size), ['43']);
      expect(find.byType(CartProductGroup), findsNothing);
      expect(find.byType(CartItemTile), findsOneWidget);
    });

    testWidgets('Hoàn tác sau khi xóa một size chỉ lấy lại size đó', (
      tester,
    ) async {
      final cart = await pumpCart(tester, FakeCartRepository(shoes()));

      await swipeLeft(tester, find.text('Size: 43'));
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();

      expect(cart.items.map((i) => i.size).toSet(), {'41', '42', '43'});
    });

    testWidgets('vuốt bắt đầu trên ô số lượng của một size chỉ xóa size đó', (
      tester,
    ) async {
      final cart = await pumpCart(tester, FakeCartRepository(shoes()));
      final secondStepper = find.byType(QuantityStepper).at(1); // size 42

      await swipeLeft(tester, secondStepper);

      expect(cart.items.map((i) => i.size), ['41', '43']);
    });
  });
}
