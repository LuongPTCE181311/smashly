import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/shared/widgets/buttons/primary_button.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';
import 'package:smashly/shared/widgets/states/error_state.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('PrimaryButton đang loading thì không nhận bấm', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        PrimaryButton(
          label: 'Đăng nhập',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('PrimaryButton bình thường gọi onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(PrimaryButton(label: 'Đăng nhập', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Đăng nhập'));
    expect(taps, 1);
  });

  testWidgets('AppTextField chỉ báo lỗi sau khi rời ô', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: [
            AppTextField(label: 'Email', validator: _required),
            AppTextField(label: 'Khác'),
          ],
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextFormField, 'Email'));
    await tester.pump();
    expect(find.text('Bắt buộc'), findsNothing);

    // Chuyển focus sang ô khác = rời ô Email.
    await tester.tap(find.widgetWithText(TextFormField, 'Khác'));
    await tester.pump();
    expect(find.text('Bắt buộc'), findsOneWidget);
  });

  testWidgets('AppTextField mật khẩu bật/tắt hiện chữ', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppTextField(label: 'Mật khẩu', isPassword: true)),
    );

    EditableText editable() =>
        tester.widget<EditableText>(find.byType(EditableText));

    expect(editable().obscureText, isTrue);
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(editable().obscureText, isFalse);
  });

  testWidgets('ErrorState có nút Thử lại khi truyền onRetry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _wrap(ErrorState(message: 'Mất kết nối', onRetry: () => retries++)),
    );

    await tester.tap(find.text('Thử lại'));
    expect(retries, 1);
  });
}

String? _required(String? value) => (value ?? '').isEmpty ? 'Bắt buộc' : null;
