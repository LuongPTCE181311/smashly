import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/features/auth/widgets/auth_error_banner.dart';
import 'package:smashly/features/profile/widgets/change_password_sheet.dart';
import 'package:smashly/providers/change_password_provider.dart';
import 'package:smashly/shared/widgets/buttons/primary_button.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';

import '../auth/fake_auth_repository.dart';

final _submitButton = find.widgetWithText(PrimaryButton, 'Cập nhật mật khẩu');
final _title = find.text('Đổi mật khẩu');

Finder _field(String label) => find.widgetWithText(AppTextField, label);

void main() {
  late FakeAuthRepository repository;
  ChangePasswordOutcome? outcome;
  var closed = false;

  Future<void> openSheet(WidgetTester tester) async {
    repository = FakeAuthRepository();
    outcome = null;
    closed = false;
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  outcome = await showModalBottomSheet<ChangePasswordOutcome>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) =>
                          ChangePasswordProvider(repository, userId: 2),
                      child: const ChangePasswordSheet(),
                    ),
                  );
                  closed = true;
                },
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String current = 'Customer@123',
    String next = 'NewPass123',
    String confirm = 'NewPass123',
  }) async {
    await tester.enterText(_field('Mật khẩu hiện tại'), current);
    await tester.enterText(_field('Mật khẩu mới'), next);
    await tester.enterText(_field('Nhập lại mật khẩu mới'), confirm);
    await tester.ensureVisible(_submitButton);
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();
  }

  testWidgets('để trống mà bấm thì báo lỗi dưới ô và không gọi repo', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.ensureVisible(_submitButton);
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập mật khẩu hiện tại'), findsOneWidget);
    expect(find.text('Vui lòng nhập lại mật khẩu'), findsOneWidget);
    expect(repository.changePasswordCalls, 0);
    expect(_title, findsOneWidget);
  });

  testWidgets('nhập đúng thì đóng sheet và trả changed', (tester) async {
    await openSheet(tester);

    await fillAndSubmit(tester);

    expect(repository.changePasswordCalls, 1);
    expect(closed, isTrue);
    expect(outcome, ChangePasswordOutcome.changed);
    expect(_title, findsNothing);
  });

  testWidgets('lỗi theo ô từ repo hiện dưới ô đó và mất khi gõ lại', (
    tester,
  ) async {
    await openSheet(tester);
    repository.changePasswordError = const AppException(
      'Mật khẩu hiện tại chưa đúng',
      field: 'currentPassword',
    );

    await fillAndSubmit(tester, current: 'Wrong@123');

    expect(find.text('Mật khẩu hiện tại chưa đúng'), findsOneWidget);
    expect(closed, isFalse);

    await tester.enterText(_field('Mật khẩu hiện tại'), 'Customer@123');
    await tester.pump();

    expect(find.text('Mật khẩu hiện tại chưa đúng'), findsNothing);
  });

  testWidgets('lỗi chung hiện banner, sheet vẫn mở', (tester) async {
    await openSheet(tester);
    repository.changePasswordError = const AppException(
      'Không thể đổi mật khẩu lúc này',
    );

    await fillAndSubmit(tester);

    expect(
      find.widgetWithText(AuthErrorBanner, 'Không thể đổi mật khẩu lúc này'),
      findsOneWidget,
    );
    expect(closed, isFalse);
  });

  testWidgets('tài khoản không còn thì đóng sheet và trả accountGone', (
    tester,
  ) async {
    await openSheet(tester);
    repository.changePasswordError = const AppException(
      AuthRepository.accountGoneMessage,
      field: AuthRepository.accountGoneField,
    );

    await fillAndSubmit(tester);

    expect(closed, isTrue);
    expect(outcome, ChangePasswordOutcome.accountGone);
  });
}
