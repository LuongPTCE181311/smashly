import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_colors.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/shared/widgets/app_dialog.dart';
import 'package:smashly/shared/widgets/app_logo.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';
import 'package:smashly/shared/widgets/states/error_state.dart';

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: child,
  ),
);

Color? _textColor(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  return paragraph.text.style?.color;
}

void main() {
  testWidgets('AppBar nền tối: tiêu đề theo foregroundColor', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.midnight,
            foregroundColor: AppColors.onDark,
            title: const Text('SMASHLY Admin'),
          ),
        ),
      ),
    );

    expect(_textColor(tester, 'SMASHLY Admin'), AppColors.onDark);
  });

  testWidgets('AppBar mặc định: tiêu đề màu ink', (tester) async {
    await tester.pumpWidget(
      _wrap(Scaffold(appBar: AppBar(title: const Text('Giỏ hàng')))),
    );

    expect(_textColor(tester, 'Giỏ hàng'), AppColors.ink);
  });

  testWidgets('ErrorState onDark dùng chữ trắng', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Scaffold(
          body: ErrorState(title: 'Lỗi', message: 'Chi tiết', onDark: true),
        ),
      ),
    );

    expect(_textColor(tester, 'Lỗi'), AppColors.onDark);
    expect(_textColor(tester, 'Chi tiết'), AppColors.onDarkMuted);
  });

  testWidgets('AppLogo không co theo cỡ chữ hệ thống', (tester) async {
    await tester.pumpWidget(_wrap(const Center(child: AppLogo(size: 40))));
    final normal = tester.getSize(find.byType(AppLogo));

    await tester.pumpWidget(
      _wrap(const Center(child: AppLogo(size: 40)), textScale: 2),
    );
    expect(tester.getSize(find.byType(AppLogo)), normal);
  });

  testWidgets('ô mật khẩu hiện check xanh khi hợp lệ', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Scaffold(
          body: Column(
            children: [
              AppTextField(
                label: 'Mật khẩu',
                isPassword: true,
                showValidCheck: true,
              ),
              AppTextField(label: 'Khác'),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      'Abcd1234',
    );
    await tester.tap(find.widgetWithText(TextFormField, 'Khác'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
  });

  for (final (label, expected) in [('Đăng xuất', true), ('Hủy', false)]) {
    testWidgets('AppDialog.confirm bấm "$label" trả về $expected', (
      tester,
    ) async {
      bool? result;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await AppDialog.confirm(
                    context,
                    title: 'Đăng xuất?',
                    confirmLabel: 'Đăng xuất',
                    destructive: true,
                  );
                },
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();

      expect(result, expected);
    });
  }
}
