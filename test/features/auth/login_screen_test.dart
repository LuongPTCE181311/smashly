import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/features/auth/login_screen.dart';
import 'package:smashly/features/auth/widgets/auth_error_banner.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_page_route.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/shared/widgets/buttons/primary_button.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';

import 'fake_auth_repository.dart';

const _customer = User(
  id: 2,
  fullName: 'Smashly Customer',
  email: 'customer@smashly.com',
  phone: '0900000001',
  role: UserRole.customer,
);
const _admin = User(
  id: 1,
  fullName: 'Smashly Admin',
  email: 'admin@smashly.com',
  phone: '0900000000',
  role: UserRole.admin,
);

const _validEmail = 'customer@smashly.com';
const _validPassword = 'Customer@123';
const _wrongCredentials = 'Email hoặc mật khẩu chưa đúng';
const _emailTaken = 'Email này đã được đăng ký';
const _registeredEmail = 'new@x.com';

const _homeMarker = 'Màn Home (giả)';
const _adminMarker = 'Màn Admin (giả)';

/// Hợp đồng với code: Key này đặt trên chính card trắng, BÊN TRONG
/// SlideTransition và Transform rung, để vị trí đo được phản ánh cả hai.
const _cardKey = Key('login_card');

final _emailField = find.widgetWithText(AppTextField, 'Email');
final _passwordField = find.widgetWithText(AppTextField, 'Mật khẩu');
final _submitButton = find.byType(PrimaryButton);
final _registerLink = find.widgetWithText(TextButton, 'Đăng ký');
final _card = find.byKey(_cardKey);

/// Gọi trong thân test: tạo repo giả và kiểm trong tearDown rằng không có lần
/// `login` nào ngoài dự tính (provider nuốt lỗi đó thành banner, test không tự đỏ).
FakeAuthRepository _newRepo() {
  final repo = FakeAuthRepository();
  addTearDown(
    () => expect(repo.unexpectedCalls, 0, reason: 'login bị gọi ngoài dự tính'),
  );
  return repo;
}

/// Bảng route riêng cho test (mọi test trừ test 7). Dùng `AppPageRoute` như
/// app thật: route có kiểu `<dynamic>`, nên `pushNamed<String>` sẽ lỗi ở đây
/// giống hệt khi chạy app.
Route<dynamic> _testRoute(RouteSettings settings) => AppPageRoute(
  settings: settings,
  builder: (_) => switch (settings.name) {
    AppRoutes.login => LoginScreen(initialEmail: settings.arguments as String?),
    AppRoutes.register => const _FakeRegisterScreen(),
    AppRoutes.home => const Scaffold(body: Text(_homeMarker)),
    AppRoutes.adminDashboard => const Scaffold(body: Text(_adminMarker)),
    _ => throw StateError('Route không có trong bảng test: ${settings.name}'),
  },
);

Widget _app(
  FakeAuthRepository repo, {
  required RouteFactory onGenerateRoute,
  required Route<dynamic> initialRoute,
  bool disableAnimations = false,
}) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(repo),
    child: MaterialApp(
      theme: AppTheme.light,
      builder: disableAnimations
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      onGenerateRoute: onGenerateRoute,
      onGenerateInitialRoutes: (_) => [initialRoute],
    ),
  );
}

Future<void> _pumpLogin(
  WidgetTester tester,
  FakeAuthRepository repo, {
  String? initialEmail,
  bool disableAnimations = false,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    _app(
      repo,
      onGenerateRoute: _testRoute,
      initialRoute: _testRoute(
        RouteSettings(name: AppRoutes.login, arguments: initialEmail),
      ),
      disableAnimations: disableAnimations,
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  String email = _validEmail,
  String password = _validPassword,
}) async {
  await tester.enterText(_emailField, email);
  await tester.enterText(_passwordField, password);
  await tester.pump();
}

bool _buttonEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(
          find.descendant(
            of: _submitButton,
            matching: find.byType(FilledButton),
          ),
        )
        .onPressed !=
    null;

TextField _textFieldOf(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(
      find.descendant(of: field, matching: find.byType(TextField)),
    );

/// Lấy mẫu vị trí ngang của card qua 20 frame (320 ms > 250 ms thời lượng rung),
/// trả độ lệch lớn nhất so với [restX].
Future<double> _maxShakeOffset(WidgetTester tester, double restX) async {
  var maxOffset = 0.0;
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    maxOffset = max(maxOffset, (tester.getTopLeft(_card).dx - restX).abs());
  }
  return maxOffset;
}

void main() {
  testWidgets('1. email sai định dạng → rời ô → hiện lỗi', (tester) async {
    await _pumpLogin(tester, _newRepo());

    await tester.enterText(_emailField, 'abc');
    await tester.tap(_passwordField);
    await tester.pump();

    expect(
      find.descendant(
        of: _emailField,
        matching: find.text('Email không đúng định dạng'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('2. form chưa hợp lệ → nút disable, bấm không gọi login', (
    tester,
  ) async {
    final repo = _newRepo();
    await _pumpLogin(tester, repo);

    expect(_buttonEnabled(tester), isFalse);
    await tester.tap(_submitButton, warnIfMissed: false);
    await tester.pump();
    expect(repo.loginCalls, 0);
  });

  testWidgets(
    '3. lỗi field email từ provider hiện dưới ô email, không có banner',
    (tester) async {
      const serverEmailError = 'Lỗi email từ server';
      final repo = _newRepo()
        ..willFailLogin(const AppException(serverEmailError, field: 'email'));
      await _pumpLogin(tester, repo);

      await _fillForm(tester);
      await tester.tap(_submitButton);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: _emailField, matching: find.text(serverEmailError)),
        findsOneWidget,
      );
      expect(find.byType(AuthErrorBanner), findsNothing);
    },
  );

  testWidgets('4. lỗi chung → banner', (tester) async {
    final repo = _newRepo()
      ..willFailLogin(const AppException(_wrongCredentials));
    await _pumpLogin(tester, repo);

    await _fillForm(tester);
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(AuthErrorBanner, _wrongCredentials),
      findsOneWidget,
    );
  });

  testWidgets('5. bấm 2 lần chỉ gọi login 1 lần', (tester) async {
    final repo = _newRepo();
    final pending = repo.holdLogin();
    await _pumpLogin(tester, repo);
    await _fillForm(tester);

    // Lần 2: cùng frame, nút chưa rebuild sang loading → kiểm hành vi tổng
    // (chặn ở _submit + chặn ở provider). Bỏ dòng chặn ở _submit thì provider vẫn
    // chặn nên test vẫn xanh: lớp provider có unit test riêng
    // (auth_provider_test.dart:57), lớp _submit không có test cô lập.
    // Lần 3: sau khi rebuild → nút đã IgnorePointer.
    await tester.tap(_submitButton);
    await tester.tap(_submitButton);
    await tester.pump();
    await tester.tap(_submitButton, warnIfMissed: false);
    await tester.pump();

    expect(repo.loginCalls, 1);

    pending.complete(_customer);
    await tester.pumpAndSettle();
  });

  for (final (user, marker) in [
    (_admin, _adminMarker),
    (_customer, _homeMarker),
  ]) {
    testWidgets(
      '6. login ${user.role.dbValue} → $marker, không Back về Login',
      (tester) async {
        final repo = _newRepo()..willLogin(user);
        await _pumpLogin(tester, repo);

        await _fillForm(tester, email: user.email);
        await tester.tap(_submitButton);
        await tester.pumpAndSettle();

        expect(find.text(marker), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(
          tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
          isFalse,
        );
      },
    );
  }

  group('7. email điền sẵn qua route thật (AppRoutes.onGenerateRoute)', () {
    Future<void> pumpRealRoute(WidgetTester tester, Object? arguments) async {
      await tester.pumpWidget(
        _app(
          _newRepo(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.onGenerateRoute(
            RouteSettings(name: AppRoutes.login, arguments: arguments),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("argument 'a@b.com' → ô email có sẵn", (tester) async {
      await pumpRealRoute(tester, 'a@b.com');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(_textFieldOf(tester, _emailField).controller!.text, 'a@b.com');
    });

    testWidgets('argument sai kiểu (42) → ô rỗng, không lỗi', (tester) async {
      await pumpRealRoute(tester, 42);

      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(_textFieldOf(tester, _emailField).controller!.text, isEmpty);
    });
  });

  testWidgets('8. nút bật/tắt theo nội dung ô', (tester) async {
    await _pumpLogin(tester, _newRepo());

    await _fillForm(tester);
    expect(_buttonEnabled(tester), isTrue);

    await tester.enterText(_passwordField, '');
    await tester.pump();
    expect(_buttonEnabled(tester), isFalse);

    // Cùng luật với validator của ô (validateRequired có trim).
    await tester.enterText(_passwordField, ' ');
    await tester.pump();
    expect(_buttonEnabled(tester), isFalse);
  });

  testWidgets('9. email điền sẵn + gõ password → nút bật', (tester) async {
    await _pumpLogin(tester, _newRepo(), initialEmail: 'a@b.com');

    expect(_textFieldOf(tester, _emailField).controller!.text, 'a@b.com');
    expect(_buttonEnabled(tester), isFalse);

    await tester.enterText(_passwordField, _validPassword);
    await tester.pump();
    expect(_buttonEnabled(tester), isTrue);
  });

  testWidgets('10. đang loading → khóa 2 ô và link Đăng ký', (tester) async {
    final repo = _newRepo();
    final pending = repo.holdLogin();
    await _pumpLogin(tester, repo);
    await _fillForm(tester);

    await tester.tap(_submitButton);
    await tester.pump();

    expect(_textFieldOf(tester, _emailField).enabled, isFalse);
    expect(_textFieldOf(tester, _passwordField).enabled, isFalse);

    await tester.tap(_registerLink, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(_FakeRegisterScreen), findsNothing);

    pending.complete(_customer);
    await tester.pumpAndSettle();
  });

  testWidgets("11. Back từ Register xóa lỗi 'email' Register để lại", (
    tester,
  ) async {
    final repo = _newRepo()
      ..registerError = const AppException(_emailTaken, field: 'email');
    await _pumpLogin(tester, repo);

    await tester.tap(_registerLink);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gọi register'));
    await tester.pumpAndSettle();

    // Điều kiện đầu đạt qua đường thật: Login (đang bị che) hiện lỗi của Register.
    expect(repo.registerCalls, 1);
    expect(find.text(_emailTaken, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(_emailTaken), findsNothing);
  });

  testWidgets('12. Register trả email → điền email, xóa password, SnackBar', (
    tester,
  ) async {
    await _pumpLogin(tester, _newRepo());
    await _fillForm(tester, email: 'old@x.com');

    await tester.tap(_registerLink);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      _textFieldOf(tester, _emailField).controller!.text,
      _registeredEmail,
    );
    expect(_textFieldOf(tester, _passwordField).controller!.text, isEmpty);
    expect(find.text('Tạo tài khoản thành công'), findsOneWidget);
    // _password.clear() không được coi là người dùng gõ: chưa có lỗi thì không báo.
    // Cần bản fix AppTextField (onUserInteractionIfError) — đỏ nếu thiếu bản fix.
    expect(find.text('Mật khẩu không được để trống'), findsNothing);

    // Cho SnackBar tự đóng để không còn Timer treo khi test kết thúc.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('13. lỗi chung → card rung ngang', (tester) async {
    final repo = _newRepo()
      ..willFailLogin(const AppException(_wrongCredentials));
    await _pumpLogin(tester, repo);
    await _fillForm(tester);
    final restX = tester.getTopLeft(_card).dx;

    await tester.tap(_submitButton);

    expect(await _maxShakeOffset(tester, restX), greaterThan(3));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card).dx, restX);
  });

  testWidgets('14. thất bại 2 lần liên tiếp → rung cả 2 lần', (tester) async {
    final repo = _newRepo()
      ..willFailLogin(const AppException(_wrongCredentials))
      ..willFailLogin(const AppException(_wrongCredentials));
    await _pumpLogin(tester, repo);
    await _fillForm(tester);
    final restX = tester.getTopLeft(_card).dx;

    for (var attempt = 1; attempt <= 2; attempt++) {
      await tester.tap(_submitButton);
      expect(
        await _maxShakeOffset(tester, restX),
        greaterThan(3),
        reason: 'lần thất bại thứ $attempt',
      );
      await tester.pumpAndSettle();
    }
    expect(repo.loginCalls, 2);
  });

  testWidgets(
    '15. màn nhỏ, chữ to, bàn phím mở → không overflow, vẫn bấm được nút',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final repo = _newRepo()..willLogin(_customer);
      await _pumpLogin(tester, repo);
      expect(tester.takeException(), isNull);

      await _fillForm(tester);
      await tester.scrollUntilVisible(
        _submitButton,
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(_submitButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repo.loginCalls, 1);
    },
  );

  testWidgets(
    '16. tắt animation → card đứng yên từ frame đầu, lỗi không rung',
    (tester) async {
      final repo = _newRepo()
        ..willFailLogin(const AppException(_wrongCredentials));
      await _pumpLogin(tester, repo, disableAnimations: true, settle: false);

      final firstFrame = tester.getTopLeft(_card);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_card), firstFrame);

      await _fillForm(tester);
      await tester.tap(_submitButton);
      expect(await _maxShakeOffset(tester, firstFrame.dx), lessThan(0.5));
      // Lỗi thật đã xảy ra (không phải đứng yên vì không submit).
      expect(
        find.widgetWithText(AuthErrorBanner, _wrongCredentials),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '17. mật khẩu trống, bấm Enter ở ô mật khẩu → hiện lỗi, không gọi login',
    (tester) async {
      final repo = _newRepo();
      await _pumpLogin(tester, repo);

      // Ô email để trống và CHƯA chạm: lỗi dưới ô email chỉ có thể đến từ
      // Form.validate() trong _submit. Lỗi dưới ô mật khẩu thì xuất hiện cả khi
      // không có validate(), vì Enter (done) tự bỏ focus → AppTextField validate khi rời ô.
      await tester.tap(_passwordField);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.descendant(
          of: _emailField,
          matching: find.text('Email không được để trống'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _passwordField,
          matching: find.text('Mật khẩu không được để trống'),
        ),
        findsOneWidget,
      );
      expect(repo.loginCalls, 0);
    },
  );
}

/// Register giả: Back (pop null), OK (pop email), và gọi `register` thật của provider.
class _FakeRegisterScreen extends StatelessWidget {
  const _FakeRegisterScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_registeredEmail),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => context.read<AuthProvider>().register(
              fullName: 'Người Mới',
              email: _validEmail,
              phone: '0912345678',
              password: 'Newbie@123',
              confirmPassword: 'Newbie@123',
            ),
            child: const Text('Gọi register'),
          ),
        ],
      ),
    );
  }
}
