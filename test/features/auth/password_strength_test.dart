import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_colors.dart';
import 'package:smashly/core/theme/app_text_styles.dart';
import 'package:smashly/features/auth/widgets/password_strength_bar.dart';

void main() {
  group('passwordStrength', () {
    test('U1. rỗng không có độ mạnh', () {
      expect(passwordStrength(''), isNull);
    });

    test('U2. ngắn hoặc thiếu chữ/số là yếu dù có tiêu chí bổ sung', () {
      for (final password in [
        'abc1234',
        'abcdefgh',
        '12345678',
        'Ab1!',
        'Abcdefghijkl!',
        'é1234567',
      ]) {
        expect(
          passwordStrength(password),
          PasswordStrength.weak,
          reason: password,
        );
      }
    });

    test('U3. abcd1234 là trung bình', () {
      expect(passwordStrength('abcd1234'), PasswordStrength.medium);
    });

    test('U4. đạt ít nhất hai tiêu chí bổ sung là mạnh', () {
      for (final password in ['Newbie@123', 'abcdefgh1234!']) {
        expect(
          passwordStrength(password),
          PasswordStrength.strong,
          reason: password,
        );
      }
    });

    test('U5. biên đúng 12 ký tự và chỉ một tiêu chí bổ sung', () {
      expect(passwordStrength('Abcdef12345'), PasswordStrength.medium);
      expect(passwordStrength('Abcdef123456'), PasswordStrength.strong);
      expect(passwordStrength('abcdefgh1234'), PasswordStrength.medium);
      expect(passwordStrength('abcd123!'), PasswordStrength.medium);
    });

    test('dùng regex ASCII và không trim mật khẩu', () {
      expect(passwordStrength('Abcd123é'), PasswordStrength.strong);
      expect(passwordStrength('Abcd123 '), PasswordStrength.strong);
    });
  });

  Future<void> pumpBar(WidgetTester tester, String password) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PasswordStrengthBar(password: password)),
      ),
    );
  }

  testWidgets('thanh ẩn hoàn toàn khi mật khẩu trống', (tester) async {
    await pumpBar(tester, '');

    final bar = find.byType(PasswordStrengthBar);
    expect(
      find.descendant(of: bar, matching: find.byType(ColoredBox)),
      findsNothing,
    );
    expect(find.descendant(of: bar, matching: find.byType(Text)), findsNothing);
    expect(tester.getSize(bar).height, 0);
  });

  for (final (password, label, colors) in <(String, String, List<Color>)>[
    ('abc', 'Yếu', [AppColors.error, AppColors.border, AppColors.border]),
    (
      'abcd1234',
      'Trung bình',
      [AppColors.error, AppColors.warning, AppColors.border],
    ),
    (
      'Newbie@123',
      'Mạnh',
      [AppColors.error, AppColors.warning, AppColors.success],
    ),
  ]) {
    testWidgets('$label có nhãn và đúng màu ba đoạn', (tester) async {
      await pumpBar(tester, password);

      final bar = find.byType(PasswordStrengthBar);
      final segments = tester.widgetList<ColoredBox>(
        find.descendant(of: bar, matching: find.byType(ColoredBox)),
      );
      expect(segments.map((segment) => segment.color), orderedEquals(colors));
      final text = tester.widget<Text>(find.text(label));
      expect(text.style, AppTextStyles.caption);
      expect(
        find.descendant(
          of: bar,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Độ mạnh mật khẩu: $label',
          ),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('đổi mật khẩu cập nhật nhãn rồi ẩn thanh', (tester) async {
    await pumpBar(tester, 'abc');
    expect(find.text('Yếu'), findsOneWidget);

    await pumpBar(tester, 'abcd1234');
    expect(find.text('Yếu'), findsNothing);
    expect(find.text('Trung bình'), findsOneWidget);

    await pumpBar(tester, 'Newbie@123');
    expect(find.text('Trung bình'), findsNothing);
    expect(find.text('Mạnh'), findsOneWidget);

    await pumpBar(tester, '');
    expect(find.text('Mạnh'), findsNothing);
  });
}
