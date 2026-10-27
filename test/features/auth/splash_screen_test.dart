import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/app.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/features/auth/login_screen.dart';
import 'package:smashly/features/auth/splash_screen.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_page_route.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/routes/dev_menu_screen.dart';
import 'package:smashly/shared/widgets/app_logo.dart';

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

const _initError = 'Không khởi tạo được dữ liệu';
const _retry = 'Thử lại';

const _loginMarker = 'Màn Login (giả)';
const _homeMarker = 'Màn Home (giả)';
const _adminMarker = 'Màn Admin (giả)';
const _otherMarker = 'Màn khác (giả)';
const _otherRoute = '/test-other';

const _justBefore = Duration(milliseconds: 1199);

/// "Chưa điều hướng" phải kiểm cả offstage: route mới đẩy vào được dựng
/// offstage ở frame đầu (HeroController), nên `find.text` mặc định không thấy.
final _loginBuilt = find.text(_loginMarker, skipOffstage: false);
const _oneMs = Duration(milliseconds: 1);

FakeAuthRepository _newRepo() {
  final repo = FakeAuthRepository();
  addTearDown(
    () => expect(
      repo.unexpectedCalls,
      0,
      reason: 'login/getCurrentUser bị gọi ngoài dự tính',
    ),
  );
  return repo;
}

/// Bảng route riêng (mọi test trừ 10): Splash thật, các màn đích là chữ đánh dấu.
Route<dynamic> _testRoute(RouteSettings settings) => AppPageRoute(
  settings: settings,
  builder: (_) => switch (settings.name) {
    AppRoutes.splash => const SplashScreen(),
    AppRoutes.login => const Scaffold(body: Text(_loginMarker)),
    AppRoutes.home => const Scaffold(body: Text(_homeMarker)),
    AppRoutes.adminDashboard => const Scaffold(body: Text(_adminMarker)),
    _otherRoute => const Scaffold(body: Text(_otherMarker)),
    _ => throw StateError('Route không có trong bảng test: ${settings.name}'),
  },
);

/// Không `pumpAndSettle` khi còn Splash: thanh tiến trình chạy mãi.
Future<void> _pumpSplash(
  WidgetTester tester,
  FakeAuthRepository repo, {
  bool disableAnimations = false,
}) {
  return tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(repo),
      child: MaterialApp(
        theme: AppTheme.light,
        builder: disableAnimations
            ? (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              )
            : null,
        onGenerateRoute: _testRoute,
        onGenerateInitialRoutes: (_) => [
          _testRoute(const RouteSettings(name: AppRoutes.splash)),
        ],
      ),
    ),
  );
}

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator));

void main() {
  testWidgets('1. không có session: 1199 ms vẫn Splash, 1200 ms → Login', (
    tester,
  ) async {
    final repo = _newRepo()..willRestore(null);
    await _pumpSplash(tester, repo);

    await tester.pump(_justBefore);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(_loginBuilt, findsNothing);

    await tester.pump(_oneMs);
    await tester.pump();
    expect(find.text(_loginMarker), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
  });

  for (final (user, marker) in [
    (_admin, _adminMarker),
    (_customer, _homeMarker),
  ]) {
    testWidgets(
      '2. session ${user.role.dbValue} → $marker, không Back về Splash',
      (tester) async {
        final repo = _newRepo()..willRestore(user);
        await _pumpSplash(tester, repo);

        await tester.pump(SplashScreen.minDuration);
        await tester.pumpAndSettle();

        expect(find.text(marker), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);
        expect(_navigator(tester).canPop(), isFalse);
      },
    );
  }

  testWidgets('3. DB chậm: chờ tới khi xong, không cộng thêm 1,2 s', (
    tester,
  ) async {
    final repo = _newRepo();
    final pending = repo.holdRestore();
    await _pumpSplash(tester, repo);

    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(_loginBuilt, findsNothing);

    pending.complete(null);
    await tester.pump();
    await tester.pump();
    expect(find.text(_loginMarker), findsOneWidget);

    await tester.pumpAndSettle();
  });

  for (final (name, error) in <(String, Object)>[
    (
      '4. AppException',
      const AppException('Không thể khôi phục phiên đăng nhập'),
    ),
    ('5. StateError (Error, không phải Exception)', StateError('hỏng')),
  ]) {
    testWidgets('$name → sau 1,2 s báo lỗi + Thử lại, không điều hướng', (
      tester,
    ) async {
      final repo = _newRepo()..willFailRestore(error);
      await _pumpSplash(tester, repo);

      await tester.pump(_justBefore);
      expect(find.text(_initError), findsNothing);

      await tester.pump(_oneMs);
      expect(find.text(_initError), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
      expect(_loginBuilt, findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  }

  testWidgets(
    '6. bấm Thử lại 2 lần liền: không báo lỗi giả khi lần thử lại còn đang chạy',
    (tester) async {
      final repo = _newRepo()
        ..willFailRestore(
          const AppException('Không thể khôi phục phiên đăng nhập'),
        );
      final pending = repo.holdRestore();
      await _pumpSplash(tester, repo);
      await tester.pump(SplashScreen.minDuration);
      expect(find.text(_initError), findsOneWidget);

      // 2 lần bấm trong cùng frame (nút chưa kịp ẩn).
      await tester.tap(find.text(_retry));
      await tester.tap(find.text(_retry), warnIfMissed: false);
      await tester.pump();
      expect(find.text(_initError), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Lần thử lại treo quá 1,2 s: vẫn phải là "đang tải", không được báo lỗi.
      await tester.pump(SplashScreen.minDuration);
      expect(find.text(_initError), findsNothing);

      pending.complete(_customer);
      await tester.pump();
      await tester.pump();
      expect(find.text(_homeMarker), findsOneWidget);
      expect(repo.restoreCalls, 2);

      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    '7. Splash bị thay trước khi xong → không exception, không điều hướng',
    (tester) async {
      final repo = _newRepo();
      final pending = repo.holdRestore();
      await _pumpSplash(tester, repo);

      _navigator(tester)
          .pushReplacement(_testRoute(const RouteSettings(name: _otherRoute)));
      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);

      pending.complete(_customer);
      await tester.pump(SplashScreen.minDuration);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(_otherMarker), findsOneWidget);
      expect(find.text(_homeMarker), findsNothing);
    },
  );

  testWidgets('8. có route đè lên Splash → Splash không thay route trên cùng', (
    tester,
  ) async {
    final repo = _newRepo()..willRestore(null);
    await _pumpSplash(tester, repo);

    _navigator(tester).pushNamed(_otherRoute);
    await tester.pump(SplashScreen.minDuration);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(_otherMarker), findsOneWidget);
    expect(find.text(_loginMarker, skipOffstage: false), findsNothing);
    expect(_navigator(tester).canPop(), isTrue, reason: 'Splash vẫn nằm dưới');
  });

  testWidgets('9. tắt animation → logo ở trạng thái cuối ngay frame đầu', (
    tester,
  ) async {
    final repo = _newRepo()..willRestore(null);
    await _pumpSplash(tester, repo, disableAnimations: true);

    final logo = find.byType(AppLogo);
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: logo, matching: find.byType(FadeTransition)).first,
    );
    final scale = tester.widget<ScaleTransition>(
      find.ancestor(of: logo, matching: find.byType(ScaleTransition)).first,
    );
    expect(fade.opacity.value, 1);
    expect(scale.scale.value, 1);

    await tester.pump(SplashScreen.minDuration);
    await tester.pumpAndSettle();
  });

  group('10. route thật', () {
    testWidgets('AppRoutes.splash dựng SplashScreen rồi vào LoginScreen thật', (
      tester,
    ) async {
      final repo = _newRepo()..willRestore(null);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repo),
          child: MaterialApp(
            onGenerateRoute: AppRoutes.onGenerateRoute,
            onGenerateInitialRoutes: (_) => [
              AppRoutes.onGenerateRoute(
                const RouteSettings(name: AppRoutes.splash),
              ),
            ],
          ),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(SplashScreen.minDuration);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets(
      "SmashlyApp(startRoute: '/dev') chỉ dựng menu dev, không có Splash ngầm",
      (tester) async {
        // Không lập trình getCurrentUser: nếu Splash chạy ngầm, tearDown đỏ.
        final repo = _newRepo();
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AuthProvider(repo),
            child: const SmashlyApp(startRoute: AppRoutes.devMenu),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DevMenuScreen), findsOneWidget);
        expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
        expect(_navigator(tester).canPop(), isFalse);

        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(DevMenuScreen), findsOneWidget);
        expect(repo.restoreCalls, 0);
      },
    );
  });

  testWidgets(
    '11. màn nhỏ, chữ to, trạng thái lỗi → không tràn, bấm được Thử lại',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final repo = _newRepo()
        ..willFailRestore(
          const AppException('Không thể khôi phục phiên đăng nhập'),
        )
        ..willRestore(null);
      await _pumpSplash(tester, repo);
      await tester.pump(SplashScreen.minDuration);

      expect(tester.takeException(), isNull);
      expect(find.text(_initError), findsOneWidget);

      await tester.ensureVisible(find.text(_retry));
      await tester.tap(find.text(_retry));
      await tester.pump(SplashScreen.minDuration);
      await tester.pump();

      expect(find.text(_loginMarker), findsOneWidget);
      expect(repo.restoreCalls, 2);
      await tester.pumpAndSettle();
    },
  );
}
