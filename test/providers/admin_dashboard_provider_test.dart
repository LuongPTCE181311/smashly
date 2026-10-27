import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/admin_dashboard_dao.dart';
import 'package:smashly/data/repositories/admin_dashboard_repository.dart';
import 'package:smashly/providers/admin_dashboard_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late AdminDashboardRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbSchema.version,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: DatabaseHelper.onCreate,
      ),
    );
    repository = AdminDashboardRepository(
      database: () async => db,
      dashboardDao: const AdminDashboardDao(),
    );
  });

  tearDown(() => db.close());

  test('load: success, đủ 3 phần dữ liệu', () async {
    final provider = AdminDashboardProvider(repository);
    await provider.load();

    expect(provider.status, ViewStatus.success);
    expect(provider.dashboard!.stats.totalProducts, 22);
    expect(provider.hasLowStock, isTrue);
    expect(provider.dashboard!.recentOrders, hasLength(4));
  });

  test('refresh sau khi nhập thêm hàng: số liệu cập nhật', () async {
    final provider = AdminDashboardProvider(repository);
    await provider.load();

    // Giống admin sửa tồn kho Nanoflare 800 Pro trong Form rồi quay lại.
    await db.update(DbSchema.products, {'stock': 20}, where: 'id = 3');
    await provider.refresh();

    expect(provider.dashboard!.stats.lowStockCount, 2);
    expect(provider.dashboard!.lowStockProducts, hasLength(2));
  });

  test('DB lỗi: status error + câu thông báo, retry tải lại được', () async {
    var fail = true;
    final provider = AdminDashboardProvider(
      AdminDashboardRepository(
        database: () async => fail ? throw Exception('DB closed') : db,
        dashboardDao: const AdminDashboardDao(),
      ),
    );

    await provider.load();
    expect(provider.status, ViewStatus.error);
    expect(provider.errorMessage, isNotNull);

    fail = false;
    await provider.retry();
    expect(provider.status, ViewStatus.success);
  });
}
