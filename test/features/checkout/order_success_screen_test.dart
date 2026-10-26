import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/models/order.dart';
import 'package:smashly/data/repositories/order_repository.dart';
import 'package:smashly/features/checkout/order_success_screen.dart';
import 'package:smashly/providers/order_detail_provider.dart';
import 'package:smashly/routes/app_routes.dart';

final _order = Order(
  id: 42,
  orderCode: 'SML-20261025-0042',
  userId: 2,
  status: OrderStatus.pending,
  receiverName: 'Nguyen Minh Anh',
  receiverPhone: '0901234567',
  shippingAddress: '12 Le Loi, Quan 1',
  paymentMethod: PaymentMethod.bankTransfer,
  note: null,
  subtotal: 2860000,
  shippingFee: 30000,
  total: 2890000,
  createdAt: DateTime(2026, 10, 25),
);

class _FakeOrderRepository implements OrderRepository {
  Order? order = _order;
  Object? error;

  @override
  Future<Order?> getOrderDetail(int orderId, {required int userId}) async {
    if (error != null) throw error!;
    return order;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Dựng Checkout -> (pushReplacement) -> Success như luồng thật, để kiểm Back.
Future<List<String>> _pump(
  WidgetTester tester,
  _FakeOrderRepository repo,
) async {
  final routes = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: Text('shell')),
      onGenerateRoute: (settings) {
        routes.add('${settings.name}:${settings.arguments}');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => switch (settings.name) {
            '/checkout' => const Scaffold(body: Text('checkout screen')),
            AppRoutes.orderSuccess => ChangeNotifierProvider(
              create: (_) =>
                  OrderDetailProvider(repo, orderId: 42, userId: 2)..load(),
              child: const OrderSuccessScreen(),
            ),
            _ => Scaffold(body: Text('route ${settings.name}')),
          },
        );
      },
    ),
  );
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  navigator.pushNamed('/checkout');
  await tester.pumpAndSettle();
  navigator.pushReplacementNamed(AppRoutes.orderSuccess, arguments: 42);
  await tester.pumpAndSettle();
  return routes;
}

void main() {
  testWidgets('shows order code, total and payment method', (tester) async {
    await _pump(tester, _FakeOrderRepository());

    expect(find.text('Cảm ơn bạn đã đặt hàng!'), findsOneWidget);
    expect(find.text('SML-20261025-0042'), findsOneWidget);
    expect(find.text('2.890.000₫'), findsOneWidget);
    expect(find.text('Chuyển khoản ngân hàng'), findsOneWidget);
    expect(find.text('12 Le Loi, Quan 1'), findsOneWidget);
    expect(find.text('Xem đơn hàng'), findsOneWidget);
    expect(find.text('Tiếp tục mua sắm'), findsOneWidget);
  });

  testWidgets('check badge animates in and ends fully visible', (tester) async {
    await _pump(tester, _FakeOrderRepository());

    final scaled = find.ancestor(
      of: find.byIcon(Icons.check_circle_rounded),
      matching: find.byType(Transform),
    );
    expect(
      tester.widget<Transform>(scaled.first).transform.getMaxScaleOnAxis(),
      closeTo(1, 0.001),
    );
    final opacity = find.ancestor(
      of: find.byIcon(Icons.check_circle_rounded),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(opacity.first).opacity, 1);
  });

  testWidgets('Back does not return to Checkout', (tester) async {
    await _pump(tester, _FakeOrderRepository());
    expect(find.text('checkout screen'), findsNothing);

    // Không có nút Back trên AppBar; Back hệ thống chỉ rút về màn dưới Checkout.
    expect(find.byType(BackButton), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('checkout screen'), findsNothing);
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('"Xem đơn hàng" opens order detail and replaces this screen', (
    tester,
  ) async {
    final routes = await _pump(tester, _FakeOrderRepository());

    await tester.tap(find.text('Xem đơn hàng'));
    await tester.pumpAndSettle();

    expect(routes.last, '${AppRoutes.orderDetail}:42');
    expect(find.byType(OrderSuccessScreen), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('missing order shows an empty state', (tester) async {
    await _pump(tester, _FakeOrderRepository()..order = null);

    expect(find.text('Không tìm thấy đơn hàng'), findsOneWidget);
    expect(find.text('Xem đơn hàng'), findsNothing);
  });

  testWidgets('load error shows retry', (tester) async {
    final repo = _FakeOrderRepository()..error = StateError('boom');
    await _pump(tester, repo);

    expect(find.text('Thử lại'), findsOneWidget);

    repo.error = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('SML-20261025-0042'), findsOneWidget);
  });
}
