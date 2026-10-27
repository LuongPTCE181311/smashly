import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/features/cart/widgets/cart_badge_icon.dart';

void main() {
  testWidgets('badge bounces when count goes up without throwing', (
    tester,
  ) async {
    Widget app(int count) => MaterialApp(
      home: Scaffold(
        body: CartBadgeIcon(icon: Icons.shopping_bag, count: count),
      ),
    );

    await tester.pumpWidget(app(1));
    await tester.pumpWidget(app(2));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(tester.takeException(), isNull);
    expect(find.text('2'), findsOneWidget);
  });
}
