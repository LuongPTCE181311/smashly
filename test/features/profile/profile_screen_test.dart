import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/features/auth/widgets/auth_error_banner.dart';
import 'package:smashly/features/profile/profile_screen.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_page_route.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/shared/widgets/app_dialog.dart';
import 'package:smashly/shared/widgets/buttons/primary_button.dart';
import 'package:smashly/shared/widgets/inputs/app_text_field.dart';

import '../auth/fake_auth_repository.dart';

// 12:00 UTC cho cùng ngày ở UTC−12…UTC+11.
final _joined = DateTime.utc(2026, 10, 5, 12);

final _customer = User(
  id: 2,
  fullName: 'Nguyễn Văn An',
  email: 'an@smashly.com',
  phone: '0901234567',
  role: UserRole.customer,
  address: '12 Lê Lợi, Quận 1',
  createdAt: _joined,
);
final _admin = User(
  id: 1,
  fullName: 'Smashly Admin',
  email: 'admin@smashly.com',
  phone: '0900000000',
  role: UserRole.admin,
  createdAt: _joined,
);

const _loginMarker = 'Màn Login (giả)';
const _splashMarker = 'Màn Splash (giả)';
const _devMarker = 'Menu dev (giả)';
const _adminMarker = 'Màn Admin (giả)';

const _sheetTitle = 'Sửa thông tin cá nhân';
const _nameField = 'Họ và tên';
const _phoneField = 'Số điện thoại';
const _addressField = 'Địa chỉ';

final _editButton = find.widgetWithText(TextButton, 'Sửa');
final _saveButton = find.widgetWithText(PrimaryButton, 'Lưu');
final _logoutTile = find.widgetWithText(ListTile, 'Đăng xuất');

Finder _field(String label) => find.widgetWithText(AppTextField, label);

FakeAuthRepository _newRepo() {
  final repo = FakeAuthRepository();
  addTearDown(
    () => expect(repo.unexpectedCalls, 0, reason: 'repo bị gọi ngoài dự tính'),
  );
  return repo;
}

/// Provider thật đã đăng nhập (qua repo giả) — không tự gán state.
Future<AuthProvider> _signedIn(FakeAuthRepository repo, User user) async {
  repo.willLogin(user);
  final auth = AuthProvider(repo);
  await auth.login(user.email, 'Password123');
  return auth;
}

Route<dynamic> _route(RouteSettings settings, {bool showDevTools = true}) =>
    AppPageRoute(
      settings: settings,
      builder: (_) => switch (settings.name) {
        AppRoutes.profile ||
        AppRoutes.adminProfile => ProfileScreen(showDevTools: showDevTools),
        AppRoutes.login => const Scaffold(body: Text(_loginMarker)),
        AppRoutes.splash => const Scaffold(body: Text(_splashMarker)),
        AppRoutes.devMenu => const Scaffold(body: Text(_devMarker)),
        AppRoutes.adminDashboard => const Scaffold(body: Text(_adminMarker)),
        _ => throw StateError(
          'Route không có trong bảng test: ${settings.name}',
        ),
      },
    );

Future<void> _pump(
  WidgetTester tester,
  AuthProvider auth, {
  String initialRoute = AppRoutes.profile,
  bool showDevTools = true,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: (settings) =>
            _route(settings, showDevTools: showDevTools),
        onGenerateInitialRoutes: (_) => [
          _route(RouteSettings(name: initialRoute), showDevTools: showDevTools),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(_editButton);
  await tester.pumpAndSettle();
  expect(find.text(_sheetTitle), findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

bool _saveEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(
          find.descendant(of: _saveButton, matching: find.byType(FilledButton)),
        )
        .onPressed !=
    null;

/// Đóng SnackBar để không còn Timer treo khi test kết thúc.
Future<void> _flushSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '1. header + thông tin: tên, email, vai trò, avatar, ngày tham gia, SĐT, địa chỉ; tab không có Back',
    (tester) async {
      final auth = await _signedIn(_newRepo(), _customer);
      await _pump(tester, auth);

      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('an@smashly.com'), findsOneWidget);
      expect(find.text('Khách hàng'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
      expect(find.text('Thành viên từ 05/10/2026'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(find.text('12 Lê Lợi, Quận 1'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    },
  );

  testWidgets('2. chưa đăng nhập → "Chưa đăng nhập" + nút Đăng nhập', (
    tester,
  ) async {
    await _pump(tester, AuthProvider(_newRepo()));

    expect(find.text('Chưa đăng nhập'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text(_loginMarker), findsOneWidget);
  });

  testWidgets(
    '3. sửa → Lưu → sheet đóng, SnackBar "Đã lưu", Profile hiện giá trị mới',
    (tester) async {
      final repo = _newRepo();
      final auth = await _signedIn(repo, _customer);
      repo.willUpdate(
        User(
          id: 2,
          fullName: 'Nguyễn Văn Bình',
          email: 'an@smashly.com',
          phone: '0901234567',
          role: UserRole.customer,
          address: '12 Lê Lợi, Quận 1',
          createdAt: _joined,
        ),
      );
      await _pump(tester, auth);

      await _openSheet(tester);
      await tester.enterText(_field(_nameField), 'Nguyễn Văn Bình');
      await tester.pump();
      await _tapVisible(tester, _saveButton);

      expect(find.text(_sheetTitle), findsNothing);
      expect(find.text('Đã lưu'), findsOneWidget);
      expect(find.text('Nguyễn Văn Bình'), findsOneWidget);
      expect(repo.lastUpdate?.fullName, 'Nguyễn Văn Bình');
      expect(repo.lastUpdate?.phone, '0901234567');
      expect(repo.lastUpdate?.address, '12 Lê Lợi, Quận 1');
      await _flushSnackBars(tester);
    },
  );

  testWidgets('4. SĐT sai → lỗi dưới ô, không gọi repo', (tester) async {
    final repo = _newRepo();
    final auth = await _signedIn(repo, _customer);
    await _pump(tester, auth);

    await _openSheet(tester);
    await tester.enterText(_field(_phoneField), '123');
    await tester.pump();
    await _tapVisible(tester, _saveButton);

    expect(
      find.descendant(
        of: _field(_phoneField),
        matching: find.text(
          'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0',
        ),
      ),
      findsOneWidget,
    );
    expect(repo.updateCalls, 0);
  });

  testWidgets(
    '5 + 6. lỗi khi lưu → banner trong sheet, giữ chữ; đóng sheet → Profile nguyên vẹn, mở lại không còn banner',
    (tester) async {
      final repo = _newRepo();
      final auth = await _signedIn(repo, _customer);
      repo.willFailUpdate(const AppException('Không thể lưu lúc này'));
      await _pump(tester, auth);

      await _openSheet(tester);
      await tester.enterText(_field(_nameField), 'Nguyễn Văn Bình');
      await tester.pump();
      await _tapVisible(tester, _saveButton);

      // 5: sheet vẫn mở, có banner, giữ chữ đã nhập.
      expect(find.text(_sheetTitle), findsOneWidget);
      expect(
        find.widgetWithText(AuthErrorBanner, 'Không thể lưu lúc này'),
        findsOneWidget,
      );
      expect(find.text('Nguyễn Văn Bình'), findsOneWidget);

      // 6: đóng sheet (Back) → Profile vẫn hiện user cũ, không có banner lỗi.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_sheetTitle), findsNothing);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.byType(AuthErrorBanner), findsNothing);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.status, ViewStatus.success);

      await _openSheet(tester);
      expect(find.byType(AuthErrorBanner), findsNothing);
    },
  );

  testWidgets('7. đang lưu → Back không đóng được sheet', (tester) async {
    final repo = _newRepo();
    final auth = await _signedIn(repo, _customer);
    final pending = repo.holdUpdate();
    await _pump(tester, auth);

    await _openSheet(tester);
    await tester.enterText(_field(_nameField), 'Nguyễn Văn Bình');
    await tester.pump();
    await tester.ensureVisible(_saveButton);
    await tester.tap(_saveButton);
    await tester.pump();
    expect(auth.isSaving, isTrue);
    final route = ModalRoute.of(
      tester.element(find.text('Sửa thông tin cá nhân')),
    )!;
    expect(route.isCurrent, isTrue);
    expect(route.popDisposition, RoutePopDisposition.doNotPop);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(_sheetTitle), findsOneWidget);

    pending.complete(_customer);
    await tester.pumpAndSettle();
    expect(find.text(_sheetTitle), findsNothing);
    await _flushSnackBars(tester);
  });

  testWidgets('8. nút Lưu chỉ bật khi có thay đổi', (tester) async {
    final auth = await _signedIn(_newRepo(), _customer);
    await _pump(tester, auth);

    await _openSheet(tester);
    expect(_saveEnabled(tester), isFalse);

    await tester.enterText(_field(_addressField), '34 Hai Bà Trưng');
    await tester.pump();
    expect(_saveEnabled(tester), isTrue);

    await tester.enterText(_field(_addressField), '12 Lê Lợi, Quận 1');
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets(
    '9. đăng xuất: Hủy / bấm ngoài → không; xác nhận → Login, không Back được',
    (tester) async {
      final repo = _newRepo();
      final auth = await _signedIn(repo, _customer);
      await _pump(tester, auth);

      await _tapVisible(tester, _logoutTile);
      expect(find.byType(AppDialog), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(repo.logoutCalls, 0);

      await _tapVisible(tester, _logoutTile);
      await tester.tapAt(const Offset(5, 5)); // bấm ra ngoài dialog
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsNothing);
      expect(repo.logoutCalls, 0);

      await _tapVisible(tester, _logoutTile);
      await tester.tap(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.logoutCalls, 1);
      expect(find.text(_loginMarker), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    },
  );

  testWidgets('10. đăng xuất lỗi → SnackBar, ở lại Profile', (tester) async {
    final repo = _newRepo()..logoutError = StateError('prefs hỏng');
    final auth = await _signedIn(repo, _customer);
    await _pump(tester, auth);

    await _tapVisible(tester, _logoutTile);
    await tester.tap(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text('Đăng xuất'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không thể đăng xuất lúc này'), findsOneWidget);
    expect(find.text(_loginMarker), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    await _flushSnackBars(tester);
  });

  testWidgets('11a. debug: "Menu dev" → menu dev', (tester) async {
    final auth = await _signedIn(_newRepo(), _customer);
    await _pump(tester, auth);

    await _tapVisible(tester, find.widgetWithText(ListTile, 'Menu dev'));

    expect(find.text(_devMarker), findsOneWidget);
  });

  testWidgets(
    '11b. debug: "Reset demo data" → xác nhận → Splash, không Back được',
    (tester) async {
      final repo = _newRepo();
      final auth = await _signedIn(repo, _customer);
      await _pump(tester, auth);

      await _tapVisible(
        tester,
        find.widgetWithText(ListTile, 'Reset demo data'),
      );
      expect(find.text('Reset dữ liệu demo?'), findsOneWidget);
      expect(find.byType(AppDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.text('Reset'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.resetCalls, 1);
      expect(find.text(_splashMarker), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    '12. adminProfile (đẩy từ Admin) có nút Back; nhãn Admin, chưa có địa chỉ',
    (tester) async {
      final auth = await _signedIn(_newRepo(), _admin);
      await _pump(tester, auth, initialRoute: AppRoutes.adminDashboard);

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed(AppRoutes.adminProfile);
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Chưa có địa chỉ'), findsOneWidget);
    },
  );

  testWidgets('13. màn nhỏ, chữ to, bàn phím mở trong sheet → không tràn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final auth = await _signedIn(_newRepo(), _customer);
    await _pump(tester, auth);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(_editButton);
    await tester.pumpAndSettle();
    await _openSheet(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_saveButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '14. tài khoản không còn tồn tại khi lưu (P10) → báo lỗi → Login',
    (tester) async {
      final repo = _newRepo();
      final auth = await _signedIn(repo, _customer);
      repo.willFailUpdate(
        const AppException(
          AuthRepository.accountGoneMessage,
          field: AuthRepository.accountGoneField,
        ),
      );
      await _pump(tester, auth);

      await _openSheet(tester);
      await tester.enterText(_field(_nameField), 'Nguyễn Văn Bình');
      await tester.pump();
      await _tapVisible(tester, _saveButton);

      expect(find.text(_loginMarker), findsOneWidget);
      expect(find.text(AuthRepository.accountGoneMessage), findsOneWidget);
      expect(repo.logoutCalls, 1);
      await _flushSnackBars(tester);
    },
  );

  testWidgets('15. showDevTools false ẩn cả hai công cụ dev', (tester) async {
    final auth = await _signedIn(_newRepo(), _customer);
    await _pump(tester, auth, showDevTools: false);

    expect(find.text('Menu dev'), findsNothing);
    expect(find.text('Reset demo data'), findsNothing);
  });

  testWidgets('16. createdAt null không hiện ngày tham gia', (tester) async {
    const user = User(
      id: 2,
      fullName: 'Nguyễn Văn An',
      email: 'an@smashly.com',
      phone: '0901234567',
      role: UserRole.customer,
    );
    final auth = await _signedIn(_newRepo(), user);
    await _pump(tester, auth);

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.textContaining('Thành viên từ'), findsNothing);
  });

  testWidgets('17. SĐT lọc chữ và giới hạn mười chữ số', (tester) async {
    final auth = await _signedIn(_newRepo(), _customer);
    await _pump(tester, auth);
    await _openSheet(tester);

    await tester.enterText(_field(_phoneField), '');
    await tester.pump();
    await tester.enterText(_field(_phoneField), '0a91234567899');
    await tester.pump();

    final input = tester.widget<TextFormField>(
      find.descendant(
        of: _field(_phoneField),
        matching: find.byType(TextFormField),
      ),
    );
    expect(input.controller!.text, '0912345678');
  });

  testWidgets('18. địa chỉ nhập tối đa 200 ký tự', (tester) async {
    final auth = await _signedIn(_newRepo(), _customer);
    await _pump(tester, auth);
    await _openSheet(tester);

    await tester.enterText(_field(_addressField), 'x' * 201);
    await tester.pump();

    final input = tester.widget<TextFormField>(
      find.descendant(
        of: _field(_addressField),
        matching: find.byType(TextFormField),
      ),
    );
    expect(input.controller!.text, 'x' * 200);
  });

  testWidgets('19. Hủy hoặc bấm ngoài dialog không reset', (tester) async {
    final repo = _newRepo();
    final auth = await _signedIn(repo, _customer);
    await _pump(tester, auth);
    final resetTile = find.widgetWithText(ListTile, 'Reset demo data');

    await _tapVisible(tester, resetTile);
    expect(find.byType(AppDialog), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(AppDialog), matching: find.text('Hủy')),
    );
    await tester.pumpAndSettle();
    expect(repo.resetCalls, 0);

    await _tapVisible(tester, resetTile);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byType(AppDialog), findsNothing);
    expect(repo.resetCalls, 0);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('20. reset lỗi vẫn về Splash kèm SnackBar báo lỗi', (
    tester,
  ) async {
    final repo = _ResetFailingRepository();
    final auth = await _signedIn(repo, _customer);
    await _pump(tester, auth);

    await _tapVisible(tester, find.widgetWithText(ListTile, 'Reset demo data'));
    await tester.tap(
      find.descendant(of: find.byType(AppDialog), matching: find.text('Reset')),
    );
    await tester.pumpAndSettle();

    expect(repo.resetCalls, 1);
    expect(repo.unexpectedCalls, 0);
    expect(auth.currentUser, isNull);
    expect(auth.status, ViewStatus.error);
    expect(auth.errorMessage, isNotNull);
    expect(find.text(_splashMarker), findsOneWidget);
    expect(find.widgetWithText(SnackBar, auth.errorMessage!), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    await _flushSnackBars(tester);
  });

  testWidgets('21. lỗi phone từ repo hiện dưới ô và sheet vẫn mở', (
    tester,
  ) async {
    final repo = _newRepo();
    final auth = await _signedIn(repo, _customer);
    repo.willFailUpdate(
      const AppException('Số điện thoại đã bị khóa', field: 'phone'),
    );
    await _pump(tester, auth);

    await _openSheet(tester);
    await tester.enterText(_field(_phoneField), '0912345678');
    await tester.pump();
    await _tapVisible(tester, _saveButton);

    expect(repo.updateCalls, 1);
    expect(find.text(_sheetTitle), findsOneWidget);
    expect(
      find.descendant(
        of: _field(_phoneField),
        matching: find.text('Số điện thoại đã bị khóa'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AuthErrorBanner), findsNothing);
  });
}

class _ResetFailingRepository extends FakeAuthRepository {
  @override
  Future<void> resetDemoData() async {
    resetCalls++;
    throw StateError('reset failure');
  }
}
