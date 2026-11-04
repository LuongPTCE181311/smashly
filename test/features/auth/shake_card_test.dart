import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/features/auth/widgets/shake_card.dart';

void main() {
  for (final (name, value) in [
    ('1. giá trị 0 giữ child ở vị trí gốc', 0.0),
    ('2. giá trị 0.125 lệch ngang hơn 3 px và không lệch dọc', 0.125),
    ('3. giá trị 1 đưa child về vị trí gốc', 1.0),
  ]) {
    testWidgets(name, (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ShakeCard(
                controller: controller,
                child: const SizedBox(
                  key: Key('shake_child'),
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ),
        ),
      );

      final child = find.byKey(const Key('shake_child'));
      final origin = tester.getTopLeft(child);
      final centeredOrigin =
          tester.getCenter(find.byType(Center)) - const Offset(25, 25);
      expect(origin.dx, closeTo(centeredOrigin.dx, 0.01));
      expect(origin.dy, closeTo(centeredOrigin.dy, 0.01));

      controller.value = value;
      await tester.pump();

      final position = tester.getTopLeft(child);
      final dx = position.dx - origin.dx;
      if (value == 0.125) {
        expect(dx, greaterThan(3));
      } else {
        expect(dx, closeTo(0, 0.01));
      }
      expect(position.dy, closeTo(origin.dy, 0.01));
    });
  }
}
