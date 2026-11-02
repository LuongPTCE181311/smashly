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
import 'package:smashly/features/admin/widgets/order_status_sheet.dart';
import 'package:smashly/features/admin/widgets/recent_order_tile.dart';
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

  group('đổi trạng thái đơn (UC19)', () {
    // Mã đơn seed có ngày tương đối nên tìm theo đuôi id.
    Finder orderTile(int id) =>
        find.textContaining(RegExp('-${id.toString().padLeft(4, '0')}\$'));

    Future<void> openSheet(WidgetTester tester, int id) async {
      await tester.tap(orderTile(id));
      await tester.pumpAndSettle();
    }

    /// Transaction thật cần nhiều vòng: mỗi vòng cho SQLite chạy (runAsync) rồi
    /// pump để code phía sau await chạy tiếp. Không dùng pumpAndSettle khi
    /// spinner còn quay.
    Future<void> tapAndWait(WidgetTester tester, Finder button) async {
      await tester.tap(button);
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('đơn CONFIRMED: chỉ hiện đúng 2 nút hợp lệ', (tester) async {
      await pumpDashboard(tester);
      await openSheet(tester, 3);

      expect(find.byType(OrderStatusSheet), findsOneWidget);
      expect(find.text('Bắt đầu giao hàng'), findsOneWidget);
      expect(find.text('Hủy đơn'), findsOneWidget);
      expect(find.text('Xác nhận đơn'), findsNothing);
      expect(find.text('Xác nhận đã giao'), findsNothing);
    });

    testWidgets('đơn SHIPPING không có nút hủy', (tester) async {
      await pumpDashboard(tester);
      await openSheet(tester, 2);

      expect(find.text('Xác nhận đã giao'), findsOneWidget);
      expect(find.text('Hủy đơn'), findsNothing);
    });

    for (final (id, note) in [
      (1, 'Đơn đã hoàn tất, không thể đổi trạng thái'),
      (4, 'Đơn đã hủy, không thể đổi trạng thái'),
    ]) {
      testWidgets('đơn $id ở trạng thái cuối: chỉ có dòng chữ', (tester) async {
        await pumpDashboard(tester);
        await openSheet(tester, id);

        expect(find.text(note), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(OrderStatusSheet),
            matching: find.byWidgetPredicate(
              (w) => w is FilledButton || w is OutlinedButton,
            ),
          ),
          findsNothing,
        );
      });
    }

    testWidgets('đổi thành công: đóng sheet, SnackBar, danh sách cập nhật', (
      tester,
    ) async {
      await pumpDashboard(tester);
      await openSheet(tester, 3);
      await tapAndWait(tester, find.text('Bắt đầu giao hàng'));

      expect(find.byType(OrderStatusSheet), findsNothing);
      expect(find.textContaining('sang Đang giao'), findsOneWidget);
      // Đơn 2 (seed) và đơn 3 (vừa đổi) đều đang giao.
      expect(
        find.descendant(
          of: find.byType(RecentOrderTile),
          matching: find.text('Đang giao'),
        ),
        findsNWidgets(2),
      );

      final rows = await tester.runAsync(
        () => db.query(DbSchema.orders, where: 'id = 3'),
      );
      expect(rows!.single['status'], 'SHIPPING');
      expect(rows.single['shipped_at'], isNotNull);
    });

    testWidgets('hủy đơn: Giữ đơn thì không đổi, đồng ý thì hủy + hoàn kho', (
      tester,
    ) async {
      Future<int> stock() async {
        final rows = await tester.runAsync(
          () => db.query(DbSchema.products, where: 'id = 13'),
        );
        return rows!.single['stock'] as int;
      }

      await pumpDashboard(tester);
      final before = await stock();
      await openSheet(tester, 3);

      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tồn kho của các sản phẩm trong đơn sẽ được hoàn lại.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Giữ đơn'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderStatusSheet), findsOneWidget);
      expect(await stock(), before);

      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      // Nút trong dialog, không phải nút cùng tên trong sheet.
      await tapAndWait(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hủy đơn'),
        ),
      );

      expect(find.byType(OrderStatusSheet), findsNothing);
      expect(find.textContaining('sang Đã hủy'), findsOneWidget);
      expect(await stock(), before + 1);
    });

    testWidgets('lỗi: sheet vẫn mở và hiện câu thông báo', (tester) async {
      await pumpDashboard(tester);
      await openSheet(tester, 3);
      // Đơn đổi ở nơi khác trong lúc sheet đang mở.
      await tester.runAsync(
        () =>
            db.update(DbSchema.orders, {'status': 'SHIPPING'}, where: 'id = 3'),
      );

      await tapAndWait(tester, find.text('Bắt đầu giao hàng'));

      expect(find.byType(OrderStatusSheet), findsOneWidget);
      expect(
        find.text('Đơn đã được cập nhật ở nơi khác, vui lòng tải lại'),
        findsOneWidget,
      );
    });
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
