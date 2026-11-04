import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/features/auth/logout_action.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:smashly/shared/widgets/app_dialog.dart';

import 'fake_auth_repository.dart';

const _customer = User(
  id: 2,
  fullName: 'Nguyễn Văn An',
  email: 'customer@smashly.com',
  phone: '0901234567',
  role: UserRole.customer,
);
const _currentMarker = 'Màn hiện tại';
const _loginMarker = 'Màn Login (giả)';

Future<void> _pump(WidgetTester tester, AuthProvider auth) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text(_loginMarker)),
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Text(_currentMarker),
                TextButton(
                  onPressed: () => confirmAndLogout(context),
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openConfirmation(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Đăng xuất'));
  await tester.pumpAndSettle();

  expect(find.byType(AppDialog), findsOneWidget);
  final dialog = tester.widget<AppDialog>(find.byType(AppDialog));
  expect(dialog.title, 'Đăng xuất?');
  expect(dialog.message, 'Bạn có muốn đăng xuất khỏi tài khoản này?');
  expect(dialog.confirmLabel, 'Đăng xuất');
  expect(dialog.destructive, isTrue);
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppDialog),
      matching: find.widgetWithText(FilledButton, 'Đăng xuất'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeAuthRepository repo;
  late AuthProvider auth;

  setUp(() async {
    repo = FakeAuthRepository()..willLogin(_customer);
    auth = AuthProvider(repo);
    addTearDown(auth.dispose);
    await auth.login(_customer.email, 'Customer@123');
    expect(auth.currentUser, same(_customer));
    expect(auth.status, ViewStatus.success);
  });

  tearDown(() => expect(repo.unexpectedCalls, 0));

  testWidgets('Hủy → không gọi logout, vẫn ở màn cũ', (tester) async {
    await _pump(tester, auth);
    await _openConfirmation(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();

    expect(repo.logoutCalls, 0);
    expect(find.byType(AppDialog), findsNothing);
    expect(find.text(_currentMarker), findsOneWidget);
    expect(find.text(_loginMarker), findsNothing);
    expect(auth.currentUser, same(_customer));
    expect(auth.status, ViewStatus.success);
  });

  testWidgets('Đồng ý → logout một lần, về Login, không pop được', (
    tester,
  ) async {
    await _pump(tester, auth);
    await _openConfirmation(tester);

    await _confirm(tester);

    expect(repo.logoutCalls, 1);
    expect(auth.currentUser, isNull);
    expect(auth.status, ViewStatus.empty);
    expect(find.text(_loginMarker), findsOneWidget);
    expect(find.text(_currentMarker), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('logout lỗi → SnackBar dự phòng, vẫn ở màn cũ', (tester) async {
    repo.logoutError = StateError('prefs hỏng');
    await _pump(tester, auth);
    await _openConfirmation(tester);

    await _confirm(tester);

    expect(repo.logoutCalls, 1);
    expect(
      find.widgetWithText(SnackBar, 'Không thể đăng xuất lúc này'),
      findsOneWidget,
    );
    expect(find.byType(AppDialog), findsNothing);
    expect(find.text(_currentMarker), findsOneWidget);
    expect(find.text(_loginMarker), findsNothing);
    expect(auth.currentUser, same(_customer));
    expect(auth.status, ViewStatus.error);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
