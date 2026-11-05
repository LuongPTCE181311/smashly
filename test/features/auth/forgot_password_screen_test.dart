import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/features/auth/forgot_password_screen.dart';
import 'package:smashly/features/auth/widgets/auth_error_banner.dart';
import 'package:smashly/features/auth/widgets/password_strength_bar.dart';
import 'package:smashly/providers/forgot_password_provider.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';

import 'fake_auth_repository.dart';

Finder _field(String label) => find.widgetWithText(AppTextField, label);
TextField _input(WidgetTester tester, String label) => tester.widget<TextField>(
  find.descendant(of: _field(label), matching: find.byType(TextField)),
);

void main() {
  late FakeAuthRepository repository;
  Object? result;
  var returned = false;

  setUp(() {
    repository = FakeAuthRepository();
    result = null;
    returned = false;
  });

  Future<void> pump(WidgetTester tester, {String? initialEmail}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<dynamic>(
                  MaterialPageRoute<dynamic>(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => ForgotPasswordProvider(repository),
                      child: ForgotPasswordScreen(initialEmail: initialEmail),
                    ),
                  ),
                );
                returned = true;
              },
              child: const Text('Mở quên mật khẩu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở quên mật khẩu'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    for (final (label, value) in [
      ('Email', ' Customer@Smashly.COM '),
      ('Số điện thoại', '0901234567'),
      ('Mật khẩu mới', 'NewPass123'),
      ('Nhập lại mật khẩu mới', 'NewPass123'),
    ]) {
      await tester.enterText(_field(label), value);
    }
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Đặt lại mật khẩu'));
    await tester.tap(find.text('Đặt lại mật khẩu'));
    await tester.pump();
  }

  testWidgets('W1. trống báo lỗi dưới đủ 4 ô, không gọi repo', (tester) async {
    await pump(tester);
    await submit(tester);
    for (final (label, message) in [
      ('Email', 'Email không được để trống'),
      ('Số điện thoại', 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0'),
      ('Mật khẩu mới', 'Mật khẩu phải có ít nhất 8 ký tự'),
      ('Nhập lại mật khẩu mới', 'Vui lòng nhập lại mật khẩu'),
    ]) {
      expect(
        find.descendant(of: _field(label), matching: find.text(message)),
        findsOneWidget,
      );
    }
    expect(repository.resetPasswordCalls, 0);
  });

  testWidgets('W2. thành công đóng màn trả email chuẩn hóa', (tester) async {
    await pump(tester);
    await fill(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(repository.resetPasswordCalls, 1);
    expect(returned, isTrue);
    expect(result, 'customer@smashly.com');
    expect(find.byType(ForgotPasswordScreen), findsNothing);
  });

  testWidgets('W3. lỗi chung hiện banner và giữ màn', (tester) async {
    repository.resetPasswordError = const AppException(
      AuthRepository.resetMismatchMessage,
    );
    await pump(tester);
    await fill(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AuthErrorBanner, AuthRepository.resetMismatchMessage),
      findsOneWidget,
    );
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(returned, isFalse);
  });

  testWidgets('W4. lỗi phone nằm dưới ô và mất khi gõ lại', (tester) async {
    repository.resetPasswordError = const AppException(
      'Lỗi số điện thoại',
      field: 'phone',
    );
    await pump(tester);
    await fill(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: _field('Số điện thoại'),
        matching: find.text('Lỗi số điện thoại'),
      ),
      findsOneWidget,
    );
    await tester.enterText(_field('Số điện thoại'), '0912345678');
    await tester.pump();
    expect(find.text('Lỗi số điện thoại'), findsNothing);
  });

  testWidgets('W5. đang lưu khóa 4 ô và cả hai cách Back', (tester) async {
    final hold = Completer<String>();
    repository.resetPasswordHold = hold;
    await pump(tester);
    await fill(tester);
    await submit(tester);
    try {
      for (final label in [
        'Email',
        'Số điện thoại',
        'Mật khẩu mới',
        'Nhập lại mật khẩu mới',
      ]) {
        expect(_input(tester, label).enabled, isFalse);
      }
      final back = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Quay lại',
      );
      expect(tester.widget<IconButton>(back).onPressed, isNull);
      await tester.tap(back, warnIfMissed: false);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(returned, isFalse);
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    } finally {
      hold.complete('customer@smashly.com');
      await tester.pumpAndSettle();
    }
  });

  testWidgets('W6. initialEmail điền sẵn', (tester) async {
    await pump(tester, initialEmail: 'hello@example.com');
    expect(_input(tester, 'Email').controller!.text, 'hello@example.com');
  });

  testWidgets('W7. thanh độ mạnh hiện khi gõ và ẩn khi xóa', (tester) async {
    await pump(tester);
    expect(find.byType(PasswordStrengthBar), findsNothing);
    await tester.enterText(_field('Mật khẩu mới'), 'NewPass123');
    await tester.pump();
    expect(find.byType(PasswordStrengthBar), findsOneWidget);
    await tester.enterText(_field('Mật khẩu mới'), '');
    await tester.pump();
    expect(find.byType(PasswordStrengthBar), findsNothing);
  });

  testWidgets('W8. số điện thoại chỉ nhận tối đa 10 chữ số', (tester) async {
    await pump(tester);
    await tester.enterText(_field('Số điện thoại'), '0a901b23456789');
    await tester.pump();
    expect(_input(tester, 'Số điện thoại').controller!.text, '0901234567');
  });
}
