import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/services/session_service.dart';
import 'package:smashly/data/daos/admin_dashboard_dao.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/daos/user_dao.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/data/repositories/admin_dashboard_repository.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/features/admin/admin_dashboard_screen.dart';
import 'package:smashly/providers/admin_dashboard_provider.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../auth/fake_auth_repository.dart';

/// Số trên màn S13 khớp seed; tap sản phẩm sắp hết mở đúng route Form;
/// menu avatar admin mở đúng route.
void main() {
  late Database db;

  setUpAll(sqfliteFfiInit);

  tearDown(() => db.close());

  /// Dựng Dashboard với DB seed. Trả về danh sách route đã được push
  /// (onGenerateRoute giả chỉ ghi lại rồi dựng một Scaffold trống).
  /// [auth] null → AuthProvider thật trên DB seed (chưa đăng nhập).
  Future<List<RouteSettings>> pumpDashboard(
    WidgetTester tester, {
    AuthProvider? auth,
  }) async {
    late AdminDashboardProvider provider;
    final pushed = <RouteSettings>[];

    await tester.runAsync(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DbSchema.version,
          onConfigure: DatabaseHelper.onConfigure,
          onCreate: DatabaseHelper.onCreate,
        ),
      );
      provider = AdminDashboardProvider(
        AdminDashboardRepository(
          database: () async => db,
          dashboardDao: const AdminDashboardDao(),
        ),
      );
      await provider.load();
    });

    // Màn cao để ListView dựng hết các mục (không cần cuộn).
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                auth ??
                AuthProvider(
                  AuthRepository(
                    database: () async => db,
                    userDao: const UserDao(),
                    cartDao: const CartDao(),
                    sessionService: SessionService(),
                    resetDatabase: () async {},
                  ),
                ),
          ),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          home: const AdminDashboardScreen(),
          onGenerateRoute: (settings) {
            pushed.add(settings);
            return MaterialPageRoute(builder: (_) => const Scaffold());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return pushed;
  }

  /// Một mục trong menu avatar (tránh nhầm với nút "Quản lý sản phẩm").
  Finder menuItem(String label) => find.descendant(
    of: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    matching: find.text(label),
  );

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Menu quản trị'));
    await tester.pumpAndSettle();
  }

  testWidgets('hiển thị số liệu seed và mở Form khi tap', (tester) async {
    final pushed = await pumpDashboard(tester);

    expect(find.text('22'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('4.130.000₫'), findsWidgets);
    expect(find.text('3 sản phẩm'), findsOneWidget);
    expect(find.text('0 · Hết'), findsOneWidget);
    expect(find.text('3 · Sắp hết'), findsOneWidget);
    expect(find.text('4 · Sắp hết'), findsOneWidget);
    expect(find.text('620.000₫'), findsOneWidget);
    expect(find.text('Nguyễn Minh Anh'), findsNWidgets(4));

    await tester.ensureVisible(find.text('Yonex Nanoflare 800 Pro'));
    await tester.tap(find.text('Yonex Nanoflare 800 Pro'));
    await tester.pumpAndSettle();
    expect(pushed.single.name, AppRoutes.adminProductForm);
    expect(pushed.single.arguments, 3);
  });

  testWidgets('bấm avatar hiện đủ 4 mục menu', (tester) async {
    await pumpDashboard(tester);
    await openMenu(tester);

    expect(menuItem('Quản lý sản phẩm'), findsOneWidget);
    expect(menuItem('Thêm sản phẩm'), findsOneWidget);
    expect(menuItem('Hồ sơ'), findsOneWidget);
    expect(menuItem('Đăng xuất'), findsOneWidget);
  });

  // Mục menu → route được push.
  const menuRoutes = {
    'Quản lý sản phẩm': AppRoutes.adminProducts,
    'Thêm sản phẩm': AppRoutes.adminProductForm,
    'Hồ sơ': AppRoutes.adminProfile,
  };

  for (final MapEntry(key: label, value: route) in menuRoutes.entries) {
    testWidgets('menu "$label" mở $route', (tester) async {
      final pushed = await pumpDashboard(tester);
      await openMenu(tester);
      await tester.tap(menuItem(label));
      await tester.pumpAndSettle();

      expect(pushed.single.name, route);
      // Thêm sản phẩm: không truyền id (chế độ thêm mới).
      expect(pushed.single.arguments, isNull);
    });
  }

  testWidgets('Đăng xuất: Hủy ở lại, đồng ý thì logout và về Login', (
    tester,
  ) async {
    final repo = FakeAuthRepository()..willLogin(_admin);
    addTearDown(() => expect(repo.unexpectedCalls, 0));
    final auth = AuthProvider(repo);
    expect(await auth.login(_admin.email, 'Admin@123'), same(_admin));
    final pushed = await pumpDashboard(tester, auth: auth);

    // Hủy → đóng hộp thoại, vẫn ở Dashboard, chưa logout.
    await openMenu(tester);
    await tester.tap(menuItem('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng xuất?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất?'), findsNothing);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(repo.logoutCalls, 0);
    expect(pushed, isEmpty);

    // Đồng ý → logout đúng 1 lần, xóa stack và về Login.
    await openMenu(tester);
    await tester.tap(menuItem('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(repo.logoutCalls, 1);
    expect(auth.isLoggedIn, isFalse);
    expect(pushed.single.name, AppRoutes.login);
    expect(find.byType(AdminDashboardScreen), findsNothing);
  });
}

const _admin = User(
  id: 1,
  fullName: 'Smashly Admin',
  email: 'admin@smashly.com',
  phone: '0900000000',
  role: UserRole.admin,
);
