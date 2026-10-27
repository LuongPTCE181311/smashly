import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/services/session_service.dart';
import 'package:smashly/data/daos/admin_dashboard_dao.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/daos/user_dao.dart';
import 'package:smashly/data/repositories/admin_dashboard_repository.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/features/admin/admin_dashboard_screen.dart';
import 'package:smashly/providers/admin_dashboard_provider.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/routes/app_routes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Số trên màn S13 khớp seed; tap sản phẩm sắp hết mở đúng route Form.
void main() {
  late Database db;

  setUpAll(sqfliteFfiInit);

  tearDown(() => db.close());

  testWidgets('hiển thị số liệu seed và mở Form khi tap', (tester) async {
    late AdminDashboardProvider provider;
    Object? formArgument;

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
            create: (_) => AuthProvider(
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
            if (settings.name == AppRoutes.adminProductForm) {
              formArgument = settings.arguments;
            }
            return MaterialPageRoute(builder: (_) => const Scaffold());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

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
    expect(formArgument, 3);
  });
}
