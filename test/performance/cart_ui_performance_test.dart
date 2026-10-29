import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/models/cart_item.dart';
import 'package:smashly/features/cart/cart_screen.dart';
import 'package:smashly/features/cart/widgets/cart_item_tile.dart';
import 'package:smashly/providers/cart_provider.dart';

import '../features/cart/cart_screen_test.dart' show FakeCartRepository, item;

/// Hiệu năng giao diện giỏ hàng với danh sách lớn: ListView phải dựng lười,
/// và mở / đóng chi tiết sản phẩm không được làm dựng lại cả danh sách.
void main() {
  const total = 400;

  List<CartItem> items() => [
    for (var i = 1; i <= total; i++) item(i, productId: i),
  ];

  Future<CartProvider> pumpCart(WidgetTester tester) async {
    final cart = CartProvider(FakeCartRepository(items()))..updateUser(2);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: cart,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CartScreen(),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                Scaffold(appBar: AppBar(), body: const Text('chi tiết')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cart;
  }

  testWidgets('$total món: chỉ dựng phần đang nhìn thấy (ListView lười)', (
    tester,
  ) async {
    final watch = Stopwatch()..start();
    await pumpCart(tester);
    watch.stop();

    final built = find.byType(CartItemTile).evaluate().length;
    debugPrint(
      '[perf] dựng giỏ $total món: ${watch.elapsedMilliseconds} ms, '
      '$built thẻ được dựng',
    );

    expect(built, greaterThan(0));
    expect(built, lessThan(30), reason: 'không dựng cả $total thẻ');
    expect(watch.elapsedMilliseconds, lessThan(5000));
  });

  testWidgets('cuộn tới cuối danh sách vẫn chỉ giữ một ít thẻ trong bộ nhớ', (
    tester,
  ) async {
    await pumpCart(tester);

    for (var i = 0; i < 12; i++) {
      await tester.fling(find.byType(Scrollable), const Offset(0, -2500), 4000);
      await tester.pumpAndSettle();
    }

    final built = find.byType(CartItemTile).evaluate().length;
    debugPrint('[perf] sau khi cuộn sâu: $built thẻ được dựng');
    expect(built, lessThan(30));
  });

  testWidgets('mở/đóng chi tiết: số thẻ dựng lại không tăng theo độ dài giỏ', (
    tester,
  ) async {
    // Bấm vào thẻ (ink/focus) và đóng màn làm dựng lại các thẻ đang hiển thị;
    // điều cần giữ là con số này chỉ phụ thuộc phần nhìn thấy, không phụ thuộc N.
    Future<({int rebuilds, int notifications})> measure(int count) async {
      final cart = CartProvider(
        FakeCartRepository([
          for (var i = 1; i <= count; i++) item(i, productId: i),
        ]),
      )..updateUser(2);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          key: UniqueKey(),
          value: cart,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CartScreen(),
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(appBar: AppBar()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var notifications = 0;
      cart.addListener(() => notifications++);
      var rebuilds = 0;
      debugOnRebuildDirtyWidget = (element, builtOnce) {
        if (element.widget is CartItemTile) rebuilds++;
      };
      await tester.tap(find.byType(CartItemTile).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      debugOnRebuildDirtyWidget = null;
      return (rebuilds: rebuilds, notifications: notifications);
    }

    addTearDown(() => debugOnRebuildDirtyWidget = null);
    final small = await measure(40);
    final large = await measure(total);

    debugPrint(
      '[perf] dựng lại thẻ khi mở/đóng chi tiết: '
      '40 món -> ${small.rebuilds}, $total món -> ${large.rebuilds}',
    );
    expect(large.notifications, 0, reason: 'mở/đóng không làm giỏ thông báo');
    expect(large.rebuilds, small.rebuilds, reason: 'không tỉ lệ với số món');
    expect(large.rebuilds, lessThan(30));
  });

  testWidgets('mở / đóng chi tiết 30 lần liên tiếp vẫn nhanh và ổn định', (
    tester,
  ) async {
    await pumpCart(tester);

    final watch = Stopwatch()..start();
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.byType(CartItemTile).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    watch.stop();

    debugPrint(
      '[perf] 30 vòng mở/đóng: ${watch.elapsedMilliseconds} ms '
      '(${(watch.elapsedMilliseconds / 30).toStringAsFixed(0)} ms/vòng)',
    );
    expect(find.byType(CartItemTile), findsWidgets);
    expect(find.text('chi tiết'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(watch.elapsedMilliseconds, lessThan(20000));
  });
}
