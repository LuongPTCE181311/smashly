import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/models/cart_item.dart';
import 'package:smashly/data/models/order.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/data/repositories/order_repository.dart';
import 'package:smashly/features/checkout/checkout_screen.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:smashly/providers/checkout_provider.dart';
import 'package:smashly/routes/app_routes.dart';

import '../auth/fake_auth_repository.dart';

class _SignedInAuth extends AuthProvider {
  _SignedInAuth() : super(FakeAuthRepository());

  @override
  User get currentUser => const User(
    id: 2,
    fullName: 'Nguyen Minh Anh',
    email: 'anh@smashly.com',
    phone: '0901234567',
    role: UserRole.customer,
    address: '12 Le Loi, Quan 1',
  );
}

class _FakeCartRepository implements CartRepository {
  _FakeCartRepository(this.items);

  final List<CartItem> items;

  @override
  Future<List<CartItem>> loadItems(int userId) async => [...items];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Chỉ giả `placeOrder`; `Completer` cho test giữ lệnh đặt hàng đang chạy dở.
class _FakeOrderRepository implements OrderRepository {
  int calls = 0;
  Object? error;
  Completer<Order>? hold;

  @override
  Future<Order> placeOrder({
    required int userId,
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    PaymentMethod paymentMethod = PaymentMethod.cod,
    String? note,
  }) async {
    calls++;
    if (hold != null) return hold!.future;
    if (error != null) throw error!;
    return _order;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _order = Order(
  id: 42,
  orderCode: 'SML-20261020-0042',
  userId: 2,
  status: OrderStatus.pending,
  receiverName: 'Nguyen Minh Anh',
  receiverPhone: '0901234567',
  shippingAddress: '12 Le Loi, Quan 1',
  paymentMethod: PaymentMethod.cod,
  note: null,
  subtotal: 100000,
  shippingFee: 30000,
  total: 130000,
  createdAt: DateTime(2026, 10, 20),
);

CartItem _item({int price = 100000, int quantity = 1, bool selected = true}) =>
    CartItem(
      id: 1,
      productId: 1,
      name: 'Vot Astrox',
      imagePath: 'assets/none.png',
      price: price,
      stock: 10,
      quantity: quantity,
      size: '',
      isSelected: selected,
    );

Future<_FakeOrderRepository> _pump(
  WidgetTester tester,
  List<CartItem> items, {
  List<String>? pushed,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final orders = _FakeOrderRepository();
  final cart = CartProvider(_FakeCartRepository(items))..updateUser(2);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => _SignedInAuth()),
        ChangeNotifierProvider<CartProvider>.value(value: cart),
        ChangeNotifierProvider(create: (_) => CheckoutProvider(orders)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const CheckoutScreen(),
        onGenerateRoute: (settings) {
          pushed?.add('${settings.name}:${settings.arguments}');
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('next screen')),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return orders;
}

Finder _orderButton() => find.textContaining('Đặt hàng ·');

void main() {
  testWidgets('prefills receiver info and shows total on the button', (
    tester,
  ) async {
    await _pump(tester, [_item(price: 100000, quantity: 2)]);

    expect(find.text('Nguyen Minh Anh'), findsOneWidget);
    expect(find.text('0901234567'), findsOneWidget);
    expect(find.text('12 Le Loi, Quan 1'), findsOneWidget);
    // 200.000 + ship 30.000
    expect(find.text('Đặt hàng · 230.000₫'), findsOneWidget);
    expect(find.text('30.000₫'), findsOneWidget);
    expect(find.text('Miễn phí'), findsNothing);
  });

  testWidgets('free shipping from 1.000.000', (tester) async {
    await _pump(tester, [_item(price: 1200000)]);

    expect(find.text('Miễn phí'), findsOneWidget);
    expect(find.text('Đặt hàng · 1.200.000₫'), findsOneWidget);
  });

  testWidgets('three payment methods, COD selected by default', (tester) async {
    await _pump(tester, [_item()]);

    expect(find.text('Thanh toán khi nhận hàng'), findsOneWidget);
    expect(find.text('Chuyển khoản ngân hàng'), findsOneWidget);
    expect(find.text('Ví điện tử'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

    await tester.tap(find.text('Ví điện tử'));
    await tester.pump();
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(2));
  });

  testWidgets('tapping twice places only one order', (tester) async {
    final orders = await _pump(tester, [_item()]);
    orders.hold = Completer<Order>();

    await tester.tap(_orderButton());
    await tester.pump();
    await tester.tap(_orderButton(), warnIfMissed: false);
    await tester.pump();

    expect(orders.calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('success opens the success screen with the order id', (
    tester,
  ) async {
    final pushed = <String>[];
    await _pump(tester, [_item()], pushed: pushed);

    await tester.tap(_orderButton());
    await tester.pumpAndSettle();

    expect(pushed, contains('${AppRoutes.orderSuccess}:42'));
    expect(find.text('next screen'), findsOneWidget);
  });

  testWidgets('out of stock shows the product name and stays on screen', (
    tester,
  ) async {
    final orders = await _pump(tester, [_item()]);
    orders.error = const AppException('"Vot Astrox" đã hết hàng');

    await tester.tap(_orderButton());
    await tester.pumpAndSettle();

    expect(find.text('"Vot Astrox" đã hết hàng'), findsOneWidget);
    expect(find.text('next screen'), findsNothing);
    // Lỗi xong thì đặt lại được.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('blank address blocks submit', (tester) async {
    final orders = await _pump(tester, [_item()]);

    await tester.enterText(
      find.widgetWithText(TextFormField, '12 Le Loi, Quan 1'),
      '',
    );
    await tester.tap(_orderButton());
    await tester.pumpAndSettle();

    expect(find.text('Địa chỉ không được để trống'), findsOneWidget);
    expect(orders.calls, 0);
  });

  testWidgets('nothing selected shows an empty state, no form', (tester) async {
    await _pump(tester, [_item(selected: false)]);

    expect(find.text('Chưa có sản phẩm để thanh toán'), findsOneWidget);
    expect(_orderButton(), findsNothing);
  });
}
