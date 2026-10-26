import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/features/cart/widgets/quantity_stepper.dart';

Widget _app(int quantity, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: QuantityStepper(
        quantity: quantity,
        onDecrease: () {},
        onIncrease: () {},
      ),
    ),
  ),
);

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  testWidgets('old and new numbers overlap while sliding, then only new', (
    tester,
  ) async {
    await tester.pumpWidget(_app(1));
    await tester.pumpWidget(_app(2));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets(
    'increase slides up from below, decrease slides down from above',
    (tester) async {
      await tester.pumpWidget(_app(2));
      final rest = _top(tester, '2');

      await tester.pumpWidget(_app(3));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_top(tester, '3'), greaterThan(rest));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_app(2));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_top(tester, '2'), lessThan(rest));
      await tester.pumpAndSettle();
      expect(_top(tester, '2'), rest);
    },
  );

  testWidgets('buttons stay tappable mid-animation', (tester) async {
    var increases = 0;
    Widget app(int q) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: QuantityStepper(
            quantity: q,
            onDecrease: () {},
            onIncrease: () => increases++,
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(1));
    await tester.pumpWidget(app(2));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byTooltip('Tăng số lượng'));

    expect(increases, 1);
  });

  testWidgets('reduce motion swaps the number immediately', (tester) async {
    await tester.pumpWidget(_app(1, reduceMotion: true));
    await tester.pumpWidget(_app(2, reduceMotion: true));
    await tester.pump();

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  group('typing a quantity', () {
    Widget editable(List<int> changes, {int quantity = 3, int max = 10}) =>
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: QuantityStepper(
                quantity: quantity,
                onDecrease: () {},
                onIncrease: () {},
                max: max,
                onQuantityChanged: changes.add,
              ),
            ),
          ),
        );

    Future<void> openField(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Nhập số lượng'));
      await tester.pumpAndSettle();
    }

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('number is not editable without max/onQuantityChanged', (
      tester,
    ) async {
      await tester.pumpWidget(_app(3));
      expect(find.byTooltip('Nhập số lượng'), findsNothing);
    });

    testWidgets('accepts digits only: letters, minus and symbols are dropped', (
      tester,
    ) async {
      final changes = <int>[];
      await tester.pumpWidget(editable(changes));
      await openField(tester);

      await tester.enterText(find.byType(TextField), 'a-b+7.,#');
      expect(fieldText(tester), '7');

      await tester.enterText(find.byType(TextField), '-5');
      expect(fieldText(tester), '5');
    });

    testWidgets('clamps above max and strips leading zeros', (tester) async {
      await tester.pumpWidget(editable([]));
      await openField(tester);

      await tester.enterText(find.byType(TextField), '500');
      expect(fieldText(tester), '10');

      await tester.enterText(find.byType(TextField), '007');
      expect(fieldText(tester), '7');

      await tester.enterText(find.byType(TextField), '9999999999999999999');
      expect(fieldText(tester), '10');
    });

    testWidgets('submit reports the new quantity once', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(editable(changes));
      await openField(tester);

      await tester.enterText(find.byType(TextField), '7');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(changes, [7]);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('empty, zero or unchanged keeps the old quantity', (
      tester,
    ) async {
      final changes = <int>[];
      await tester.pumpWidget(editable(changes));

      for (final typed in ['', '0', '3']) {
        await openField(tester);
        await tester.enterText(find.byType(TextField), typed);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      expect(changes, isEmpty);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('losing focus commits the typed value', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(editable(changes));
      await openField(tester);

      await tester.enterText(find.byType(TextField), '4');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(changes, [4]);
    });

    testWidgets('max below 1 (sold out) is not editable', (tester) async {
      await tester.pumpWidget(editable([], max: 0));
      expect(find.byTooltip('Nhập số lượng'), findsNothing);
    });
  });
}
