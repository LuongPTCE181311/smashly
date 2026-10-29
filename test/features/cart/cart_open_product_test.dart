import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/models/cart_item.dart';
import 'package:smashly/features/cart/cart_screen.dart';
import 'package:smashly/features/cart/widgets/cart_item_tile.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:smashly/routes/app_routes.dart';

import 'cart_screen_test.dart' show FakeCartRepository, item;

/// Records the routes pushed onto / popped from the test Navigator.
class _NavSpy extends NavigatorObserver {
  final pushed = <RouteSettings>[];
  int popped = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Skip the first route (the Cart screen is `home`).
    if (previousRoute != null) pushed.add(route.settings);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => popped++;
}

/// Stand-in for Product Detail: an AppBar with a Back button, shows the productId.
class _DetailStub extends StatelessWidget {
  const _DetailStub(this.arguments);

  final Object? arguments;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Chi tiết $arguments')),
    body: const SizedBox.expand(),
  );
}

Future<({CartProvider cart, _NavSpy spy})> _pump(
  WidgetTester tester,
  List<CartItem> items,
) async {
  final spy = _NavSpy();
  final cart = CartProvider(FakeCartRepository(items))..updateUser(2);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      key: UniqueKey(), // a fresh Navigator per pump, no old routes kept
      value: cart,
      child: MaterialApp(
        theme: AppTheme.light,
        navigatorObservers: [spy],
        home: const CartScreen(),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => _DetailStub(settings.arguments),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (cart: cart, spy: spy);
}

/// Taps the AppBar arrow; pageBack() pumps only once, so wait for the animation.
Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

/// The system Back button (Android) or the back gesture.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  group('bấm vào sản phẩm trong giỏ', () {
    testWidgets('bấm tên mở Product Detail đúng productId', (tester) async {
      final env = await _pump(tester, [item(1, productId: 77)]);

      await tester.tap(find.text('Vợt 1'));
      await tester.pumpAndSettle();

      expect(env.spy.pushed, hasLength(1));
      expect(env.spy.pushed.single.name, AppRoutes.productDetail);
      expect(env.spy.pushed.single.arguments, 77);
      expect(find.text('Chi tiết 77'), findsOneWidget);
    });

    testWidgets('bấm ảnh hoặc bấm giá cũng mở chi tiết', (tester) async {
      for (final target in [
        find.byType(CartThumbnail),
        find.descendant(
          of: find.byType(CartItemTile),
          matching: find.text('100.000₫'),
        ),
      ]) {
        final env = await _pump(tester, [item(1, productId: 9)]);

        await tester.tap(target);
        await tester.pumpAndSettle();

        expect(env.spy.pushed.single.arguments, 9);
      }
    });

    testWidgets('ô chọn, nút +/− và vuốt xóa không mở chi tiết', (
      tester,
    ) async {
      final env = await _pump(tester, [item(1), item(2)]);
      final tileCheckbox = find.descendant(
        of: find.byType(CartItemTile).first,
        matching: find.byType(Checkbox),
      );

      await tester.tap(tileCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tăng số lượng').first);
      await tester.pumpAndSettle();
      await tester.drag(find.text('Vợt 2'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(env.spy.pushed, isEmpty);
      expect(find.text('Vợt 2'), findsNothing, reason: 'vuốt vẫn xóa được');
    });

    testWidgets('thẻ nhiều size: bấm phần đầu mở, bấm dòng size thì không', (
      tester,
    ) async {
      final env = await _pump(tester, [
        item(1, productId: 5, size: '41'),
        item(2, productId: 5, size: '42'),
      ]);

      await tester.tap(find.text('Size: 41'));
      await tester.pumpAndSettle();
      expect(env.spy.pushed, isEmpty);

      await tester.tap(find.text('2 size trong giỏ'));
      await tester.pumpAndSettle();
      expect(env.spy.pushed.single.name, AppRoutes.productDetail);
      expect(env.spy.pushed.single.arguments, 5);
    });

    testWidgets('bấm đúp nhanh chỉ mở một màn chi tiết', (tester) async {
      final env = await _pump(tester, [item(1, productId: 3)]);

      await tester.tap(find.text('Vợt 1'));
      await tester.tap(find.text('Vợt 1'));
      await tester.pumpAndSettle();

      expect(env.spy.pushed, hasLength(1));
      await _back(tester);
      expect(find.text('Chi tiết 3'), findsNothing);
      expect(find.text('Vợt 1'), findsOneWidget);
    });

    testWidgets('hai lần mở trong cùng một khung hình chỉ push một lần', (
      tester,
    ) async {
      // Two taps arrive before Flutter can paint the new screen: only the
      // ModalRoute.isCurrent guard in _openProduct stops the second one.
      final env = await _pump(tester, [item(1, productId: 3)]);
      final open = tester
          .widget<CartItemTile>(find.byType(CartItemTile))
          .onOpen!;

      open();
      open();
      await tester.pumpAndSettle();

      expect(env.spy.pushed, hasLength(1));
    });

    testWidgets('CartItemTile không có onOpen: bấm tên không làm gì', (
      tester,
    ) async {
      final spy = _NavSpy();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorObservers: [spy],
          home: Scaffold(
            body: CartItemTile(
              item: item(1),
              onToggle: () {},
              onDecrease: () {},
              onIncrease: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Vợt 1'));
      await tester.pumpAndSettle();

      expect(spy.pushed, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vùng bấm có hành động tap cho trình đọc màn hình', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, [item(1)]);

      final data = tester.getSemantics(find.text('Vợt 1')).getSemanticsData();

      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group('quay lại giỏ hàng', () {
    testWidgets('nút mũi tên trên AppBar quay về giỏ', (tester) async {
      final env = await _pump(tester, [item(1, productId: 4), item(2)]);

      await tester.tap(find.text('Vợt 1'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết 4'), findsOneWidget);

      await _back(tester);

      expect(find.text('Chi tiết 4'), findsNothing);
      expect(find.text('Giỏ hàng'), findsOneWidget);
      expect(find.text('Vợt 1'), findsOneWidget);
      expect(find.text('Vợt 2'), findsOneWidget);
      expect(env.spy.popped, 1);
    });

    testWidgets('nút Back / cử chỉ của hệ thống quay về giỏ', (tester) async {
      await _pump(tester, [item(1, productId: 4)]);

      await tester.tap(find.text('Vợt 1'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết 4'), findsOneWidget);

      await _systemBack(tester);

      expect(find.text('Chi tiết 4'), findsNothing);
      expect(find.text('Vợt 1'), findsOneWidget);
    });

    testWidgets('mở rồi quay lại nhiều lần vẫn ổn định', (tester) async {
      final env = await _pump(tester, [item(1, productId: 4)]);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Vợt 1'));
        await tester.pumpAndSettle();
        i.isEven ? await _back(tester) : await _systemBack(tester);
      }

      expect(env.spy.pushed, hasLength(5));
      expect(env.spy.popped, 5);
      expect(find.text('Vợt 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('giữ vị trí cuộn và món đã bỏ chọn', (tester) async {
      final env = await _pump(tester, [for (var i = 1; i <= 30; i++) item(i)]);
      final list = find.byType(Scrollable).first;

      await tester.tap(
        find.descendant(
          of: find.byType(CartItemTile).first,
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, -900));
      await tester.pumpAndSettle();
      final before = tester.state<ScrollableState>(list).position.pixels;
      expect(before, greaterThan(0));
      final selectedBefore = env.cart.selectedCount;

      await tester.tap(find.byType(CartItemTile).first);
      await tester.pumpAndSettle();
      await _back(tester);

      expect(tester.state<ScrollableState>(list).position.pixels, before);
      expect(env.cart.selectedCount, selectedBefore);
    });

    testWidgets('giỏ đổi lúc đang xem chi tiết thì quay lại thấy dữ liệu mới', (
      tester,
    ) async {
      final env = await _pump(tester, [item(1), item(2)]);

      await tester.tap(find.text('Vợt 1'));
      await tester.pumpAndSettle();
      await env.cart.remove(env.cart.items.first);
      await _back(tester);

      expect(find.text('Vợt 1'), findsNothing);
      expect(find.text('Vợt 2'), findsOneWidget);
    });

    testWidgets('mở và quay lại không làm CartProvider phát thông báo', (
      tester,
    ) async {
      final env = await _pump(tester, [item(1, productId: 4)]);
      var notifications = 0;
      env.cart.addListener(() => notifications++);

      await tester.tap(find.text('Vợt 1'));
      await tester.pumpAndSettle();
      await _back(tester);

      expect(notifications, 0);
    });
  });
}
