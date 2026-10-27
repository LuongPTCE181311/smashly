import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/features/auth/login_screen.dart';
import 'package:smashly/features/auth/register_screen.dart';
import 'package:smashly/features/auth/widgets/auth_error_banner.dart';
import 'package:smashly/features/auth/widgets/password_strength_bar.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/shared/widgets/buttons/primary_button.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';

import 'fake_auth_repository.dart';

const _labels = [
  'Họ tên',
  'Email',
  'Số điện thoại',
  'Mật khẩu',
  'Nhập lại mật khẩu',
];
const _values = [
  'Người Mới',
  'newbie@example.com',
  '0912345678',
  'Newbie@123',
  'Newbie@123',
];
const _mismatch = 'Mật khẩu xác nhận không khớp';

Finder _field(String label) => find.widgetWithText(AppTextField, label);
final _submit = find.widgetWithText(PrimaryButton, 'Tạo tài khoản');
final _back = find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == 'Quay lại',
);
final _loginLink = find.widgetWithText(TextButton, 'Đăng nhập');

TextField _textField(WidgetTester tester, String label) =>
    tester.widget<TextField>(
      find.descendant(of: _field(label), matching: find.byType(TextField)),
    );

Finder _errorUnder(String label, String message) =>
    find.descendant(of: _field(label), matching: find.text(message));

FakeAuthRepository _newRepo() {
  final repo = FakeAuthRepository();
  addTearDown(() => expect(repo.unexpectedCalls, 0));
  return repo;
}

void _setTestView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), value);
  await tester.pump();
}

Future<void> _fill(WidgetTester tester, {List<String> values = _values}) async {
  for (var index = 0; index < _labels.length; index++) {
    await _enter(tester, _labels[index], values[index]);
  }
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(_submit);
  await tester.tap(_submit);
}

class _RouteResult {
  bool returned = false;
  Object? value;
}

/// Host thật sự await route để phân biệt chưa pop với pop(null).
Future<_RouteResult> _pumpRegister(
  WidgetTester tester,
  FakeAuthRepository repo, {
  bool root = false,
}) async {
  _setTestView(tester);
  final result = _RouteResult();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(repo),
      child: MaterialApp(
        theme: AppTheme.light,
        home: root
            ? const RegisterScreen()
            : Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result.value = await Navigator.of(context).push<dynamic>(
                        MaterialPageRoute<dynamic>(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                      result.returned = true;
                    },
                    child: const Text('Mở Register'),
                  ),
                ),
              ),
      ),
    ),
  );
  if (!root) await tester.tap(find.text('Mở Register'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  test('fake register dùng FIFO rồi trở lại registerError cũ', () async {
    final repo = _newRepo()
      ..registerError = const AppException('Lỗi dự phòng cũ');
    final first = repo.holdRegister();
    final second = repo.holdRegister();
    Future<String> register() => repo.register(
      fullName: _values[0],
      email: _values[1],
      phone: _values[2],
      password: _values[3],
      confirmPassword: _values[4],
    );

    first.complete('first@example.com');
    second.complete('second@example.com');
    expect(await register(), 'first@example.com');
    expect(await register(), 'second@example.com');
    await expectLater(register(), throwsA(isA<AppException>()));
    repo.registerError = null;
    expect(await register(), _values[1]);
    expect(repo.registerCalls, 4);
  });

  testWidgets('W1. tiêu đề, năm ô và cấu hình nhập liệu', (tester) async {
    await _pumpRegister(tester, _newRepo());

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(5));
    expect(find.byType(AutofillGroup), findsOneWidget);
    final nodes = <FocusNode>{};
    for (var index = 0; index < _labels.length; index++) {
      final field = tester.widget<AppTextField>(_field(_labels[index]));
      expect(field.showValidCheck, isTrue);
      expect(field.enabled, isTrue);
      expect(field.focusNode, isNotNull);
      nodes.add(field.focusNode!);
      expect(
        field.textInputAction,
        index == 4 ? TextInputAction.done : TextInputAction.next,
      );
    }
    expect(nodes.length, 5);
    expect(_textField(tester, 'Họ tên').keyboardType, TextInputType.name);
    expect(
      _textField(tester, 'Họ tên').textCapitalization,
      TextCapitalization.words,
    );
    expect(
      _textField(tester, 'Email').keyboardType,
      TextInputType.emailAddress,
    );
    expect(
      _textField(tester, 'Số điện thoại').keyboardType,
      TextInputType.phone,
    );
    for (final (label, hint) in [
      ('Họ tên', AutofillHints.name),
      ('Email', AutofillHints.email),
      ('Số điện thoại', AutofillHints.telephoneNumber),
    ]) {
      expect(
        tester.widget<AppTextField>(_field(label)).autofillHints,
        contains(hint),
      );
    }
    expect(
      tester.widget<AppTextField>(_field('Nhập lại mật khẩu')).fieldKey,
      isNotNull,
    );
    for (final label in ['Mật khẩu', 'Nhập lại mật khẩu']) {
      final field = tester.widget<AppTextField>(_field(label));
      expect(field.isPassword, isTrue);
      expect(field.autofillHints, contains(AutofillHints.newPassword));
    }
    expect(tester.widget<PrimaryButton>(_submit).onPressed, isNotNull);
  });

  testWidgets('W2. submit trống báo năm lỗi, focus Họ tên, không gọi repo', (
    tester,
  ) async {
    final repo = _newRepo();
    await _pumpRegister(tester, repo);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    const errors = [
      'Họ tên phải có ít nhất 2 ký tự',
      'Email không được để trống',
      'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0',
      'Mật khẩu phải có ít nhất 8 ký tự',
      'Vui lòng nhập lại mật khẩu',
    ];
    for (var index = 0; index < _labels.length; index++) {
      expect(_errorUnder(_labels[index], errors[index]), findsOneWidget);
    }
    expect(_textField(tester, 'Họ tên').focusNode!.hasFocus, isTrue);
    expect(repo.registerCalls, 0);
  });

  testWidgets('W3. truyền năm giá trị thô, pop email chuẩn hóa, không login', (
    tester,
  ) async {
    final repo = _newRepo();
    final result = await _pumpRegister(tester, repo);
    const raw = [
      '  Người Mới  ',
      '  Newbie@Example.COM  ',
      '0912345678',
      ' Newbie@123 ',
      ' Newbie@123 ',
    ];
    await _fill(tester, values: raw);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(repo.registerCalls, 1);
    expect(repo.lastRegister, (
      fullName: raw[0],
      email: raw[1],
      phone: raw[2],
      password: raw[3],
      confirmPassword: raw[4],
    ));
    expect(result.returned, isTrue);
    expect(result.value, 'newbie@example.com');
    expect(find.byType(RegisterScreen), findsNothing);
    expect(repo.loginCalls, 0);
    final auth = tester.element(find.text('Mở Register')).read<AuthProvider>();
    expect(auth.currentUser, isNull);
  });

  for (final (key, label, replacement) in [
    ('fullName', 'Họ tên', 'Tên Mới'),
    ('email', 'Email', 'other@example.com'),
    ('phone', 'Số điện thoại', '0987654321'),
    ('password', 'Mật khẩu', 'Other@123'),
    ('confirmPassword', 'Nhập lại mật khẩu', 'Other@123'),
  ]) {
    testWidgets('W4. lỗi $key đúng ô, focus ô lỗi, gõ xóa lỗi server', (
      tester,
    ) async {
      final message = key == 'email'
          ? 'Email này đã được đăng ký'
          : 'Lỗi server cho $key';
      final repo = _newRepo()
        ..registerError = AppException(message, field: key);
      final result = await _pumpRegister(tester, repo);
      await _fill(tester);
      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(_errorUnder(label, message), findsOneWidget);
      expect(find.byType(AuthErrorBanner), findsNothing);
      expect(_textField(tester, label).focusNode!.hasFocus, isTrue);
      expect(result.returned, isFalse);
      await _enter(tester, label, replacement);
      await tester.pumpAndSettle();
      expect(find.text(message), findsNothing);
      expect(repo.registerCalls, 1);
    });
  }

  testWidgets('W4b. gõ ô khác cũng xóa lỗi email', (tester) async {
    final repo = _newRepo()
      ..registerError = const AppException('Email bị trùng', field: 'email');
    await _pumpRegister(tester, repo);
    await _fill(tester);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(_errorUnder('Email', 'Email bị trùng'), findsOneWidget);

    await _enter(tester, 'Họ tên', 'Tên khác');
    await tester.pumpAndSettle();
    expect(find.text('Email bị trùng'), findsNothing);
  });

  testWidgets('W5. lỗi chung hiện banner, giữ năm giá trị, không pop', (
    tester,
  ) async {
    final repo = _newRepo()..registerError = const AppException('Lỗi dữ liệu');
    final result = await _pumpRegister(tester, repo);
    await _fill(tester);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AuthErrorBanner, 'Lỗi dữ liệu'), findsOneWidget);
    for (var index = 0; index < _labels.length; index++) {
      expect(
        _textField(tester, _labels[index]).controller!.text,
        _values[index],
      );
    }
    expect(result.returned, isFalse);
    expect(tester.widget<PrimaryButton>(_submit).isLoading, isFalse);
  });

  testWidgets('W6. StateError hiện câu dự phòng, nút dùng lại được', (
    tester,
  ) async {
    final repo = _newRepo()..registerError = StateError('Lỗi bất ngờ');
    final result = await _pumpRegister(tester, repo);
    await _fill(tester);
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(AuthErrorBanner, 'Không thể tạo tài khoản lúc này'),
      findsOneWidget,
    );
    expect(result.returned, isFalse);
    final button = tester.widget<PrimaryButton>(_submit);
    expect(button.isLoading, isFalse);
    expect(button.onPressed, isNotNull);
    expect(tester.takeException(), isNull);

    repo.registerError = null;
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(repo.registerCalls, 2);
    expect(result.returned, isTrue);
    expect(result.value, _values[1]);
  });

  testWidgets('W7. bấm hai lần và Enter khi loading chỉ gọi register một lần', (
    tester,
  ) async {
    final repo = _newRepo();
    final pending = repo.holdRegister();
    final result = await _pumpRegister(tester, repo);
    await _fill(tester);
    await tester.ensureVisible(_submit);
    // Hai lần cùng frame, trước khi nút rebuild sang loading.
    await tester.tap(_submit);
    await tester.tap(_submit);
    await tester.pump();
    await tester.tap(_submit, warnIfMissed: false);
    tester.widget<AppTextField>(_field('Nhập lại mật khẩu')).onFieldSubmitted!(
      _values[4],
    );
    await tester.pump();

    expect(repo.registerCalls, 1);
    expect(result.returned, isFalse);
    pending.complete(_values[1]);
    await tester.pumpAndSettle();
    expect(result.value, _values[1]);
  });

  testWidgets('W8. loading khóa năm ô, spinner, hai lối Back và route pop', (
    tester,
  ) async {
    final repo = _newRepo();
    final pending = repo.holdRegister();
    final result = await _pumpRegister(tester, repo);
    await _fill(tester);
    await _tapSubmit(tester);
    await tester.pump();

    for (final label in _labels) {
      expect(_textField(tester, label).enabled, isFalse);
    }
    expect(tester.widget<PrimaryButton>(_submit).isLoading, isTrue);
    expect(
      find.descendant(
        of: _submit,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<IconButton>(_back).onPressed, isNull);
    expect(tester.widget<TextButton>(_loginLink).onPressed, isNull);
    final route = ModalRoute.of(tester.element(find.byType(RegisterScreen)))!;
    expect(route.popDisposition, RoutePopDisposition.doNotPop);
    await tester.ensureVisible(_back);
    await tester.tap(_back, warnIfMissed: false);
    await tester.ensureVisible(_loginLink);
    await tester.tap(_loginLink, warnIfMissed: false);
    await tester.pump();
    expect(result.returned, isFalse);

    pending.completeError(const AppException('Thử lại sau'));
    await tester.pumpAndSettle();
    expect(route.popDisposition, RoutePopDisposition.pop);
    for (final label in _labels) {
      expect(_textField(tester, label).enabled, isTrue);
    }
  });

  testWidgets('W9. sửa Password làm Confirm báo lệch ngay rồi hết khi khớp', (
    tester,
  ) async {
    await _pumpRegister(tester, _newRepo());
    await _enter(tester, 'Mật khẩu', 'Newbie@123');
    await _enter(tester, 'Nhập lại mật khẩu', 'Newbie@123');
    await _enter(tester, 'Mật khẩu', 'Other@123');
    expect(_textField(tester, 'Mật khẩu').focusNode!.hasFocus, isTrue);
    expect(_errorUnder('Nhập lại mật khẩu', _mismatch), findsOneWidget);

    await _enter(tester, 'Mật khẩu', 'Newbie@123');
    expect(_errorUnder('Nhập lại mật khẩu', _mismatch), findsNothing);
  });

  testWidgets(
    'W10. gõ Password khi Confirm chưa chạm và còn trống không báo lỗi',
    (tester) async {
      await _pumpRegister(tester, _newRepo());
      await _enter(tester, 'Mật khẩu', 'Newbie@123');
      expect(
        _errorUnder('Nhập lại mật khẩu', 'Vui lòng nhập lại mật khẩu'),
        findsNothing,
      );
      expect(_errorUnder('Nhập lại mật khẩu', _mismatch), findsNothing);
    },
  );

  testWidgets('W11. SĐT lọc chữ, tối đa mười số, kiểm số đầu', (tester) async {
    final repo = _newRepo();
    await _pumpRegister(tester, repo);
    await _enter(tester, 'Số điện thoại', '09a1234567890');
    expect(_textField(tester, 'Số điện thoại').controller!.text, '0912345678');
    await _enter(tester, 'Số điện thoại', '');
    await _enter(tester, 'Số điện thoại', '1234567890');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    expect(
      _errorUnder(
        'Số điện thoại',
        'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0',
      ),
      findsOneWidget,
    );
    expect(repo.registerCalls, 0);
  });

  testWidgets('W12. thanh ẩn khi trống, abcd1234 hiện Trung bình', (
    tester,
  ) async {
    await _pumpRegister(tester, _newRepo());
    expect(find.byType(PasswordStrengthBar), findsNothing);
    await _enter(tester, 'Mật khẩu', 'abcd1234');
    expect(find.byType(PasswordStrengthBar), findsOneWidget);
    expect(find.text('Trung bình'), findsOneWidget);
  });

  testWidgets('W13. hai lối Back pop null và không gọi register', (
    tester,
  ) async {
    final repo = _newRepo();
    for (final useArrow in [true, false]) {
      final result = await _pumpRegister(tester, repo);
      final control = useArrow ? _back : _loginLink;
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(result.returned, isTrue);
      expect(result.value, isNull);
      expect(find.byType(RegisterScreen), findsNothing);
    }
    expect(repo.registerCalls, 0);
  });

  testWidgets('W13b. nút ← ở route gốc không ném lỗi', (tester) async {
    final repo = _newRepo();
    await _pumpRegister(tester, repo, root: true);
    await tester.tap(_back);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(repo.registerCalls, 0);
  });

  for (final valid in [true, false]) {
    testWidgets('W14. done ô cuối ${valid ? 'submit' : 'validate form sai'}', (
      tester,
    ) async {
      final repo = _newRepo();
      final result = await _pumpRegister(tester, repo);
      if (valid) await _fill(tester);
      await tester.ensureVisible(_field('Nhập lại mật khẩu'));
      await tester.tap(_field('Nhập lại mật khẩu'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.registerCalls, valid ? 1 : 0);
      expect(result.returned, valid);
      if (!valid) {
        expect(
          _errorUnder('Email', 'Email không được để trống'),
          findsOneWidget,
        );
      }
    });
  }

  testWidgets('W15. Next chuyển focus theo thứ tự năm ô', (tester) async {
    await _pumpRegister(tester, _newRepo());
    await _enter(tester, 'Họ tên', _values[0]);
    for (var index = 0; index < _labels.length - 1; index++) {
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        _textField(tester, _labels[index + 1]).focusNode!.hasFocus,
        isTrue,
      );
    }
  });

  for (final fieldError in [false, true]) {
    testWidgets(
      'W18. tháo màn lúc chờ ${fieldError ? 'lỗi field' : 'thành công'}',
      (tester) async {
        _setTestView(tester);
        final repo = _newRepo();
        final pending = repo.holdRegister();
        final auth = AuthProvider(repo);
        final visible = ValueNotifier(true);
        addTearDown(auth.dispose);
        addTearDown(visible.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: auth,
            child: MaterialApp(
              theme: AppTheme.light,
              home: ValueListenableBuilder<bool>(
                valueListenable: visible,
                builder: (_, show, _) => show
                    ? const RegisterScreen()
                    : const Scaffold(body: Text('Màn thay thế')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _fill(tester);
        await _tapSubmit(tester);
        await tester.pump();
        expect(repo.registerCalls, 1);
        visible.value = false;
        await tester.pump();
        expect(find.byType(RegisterScreen), findsNothing);

        if (fieldError) {
          pending.completeError(
            const AppException('Email trùng', field: 'email'),
          );
        } else {
          pending.complete(_values[1]);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Màn thay thế'), findsOneWidget);
        expect(auth.isLoading, isFalse);
      },
    );
  }

  // Cần bước 4 gắn RegisterScreen vào AppRoutes để luồng này chạy xanh.
  testWidgets('F1. route thật Login → Register → Login có email và SnackBar', (
    tester,
  ) async {
    _setTestView(tester);
    final repo = _newRepo();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(repo),
        child: MaterialApp(
          theme: AppTheme.light,
          onGenerateInitialRoutes: (_) => [
            AppRoutes.onGenerateRoute(
              const RouteSettings(name: AppRoutes.login),
            ),
          ],
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _enter(tester, 'Mật khẩu', 'OldPassword123');
    final registerLink = find.widgetWithText(TextButton, 'Đăng ký');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    await _fill(
      tester,
      values: [
        _values[0],
        '  Newbie@Example.COM  ',
        _values[2],
        _values[3],
        _values[4],
      ],
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
    expect(_textField(tester, 'Email').controller!.text, 'newbie@example.com');
    expect(_textField(tester, 'Mật khẩu').controller!.text, isEmpty);
    expect(
      find.widgetWithText(SnackBar, 'Tạo tài khoản thành công'),
      findsOneWidget,
    );
    expect(repo.registerCalls, 1);
    expect(repo.loginCalls, 0);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
