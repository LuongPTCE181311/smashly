import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/admin_dashboard_dao.dart';
import 'package:smashly/data/models/order.dart';
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

  group('updateOrderStatus (UC19)', () {
    // Đơn 3 trong seed đang CONFIRMED, tổng tiền không tính vào doanh thu.
    Order orderThree(AdminDashboardProvider provider) => provider
        .dashboard!
        .recentOrders
        .firstWhere((recent) => recent.order.id == 3)
        .order;

    test('thành công: danh sách và thẻ số liệu được tải lại', () async {
      final provider = AdminDashboardProvider(repository);
      await provider.load();
      final order = orderThree(provider);
      final revenue = provider.dashboard!.stats.deliveredRevenue;

      expect(
        await provider.updateOrderStatus(order, OrderStatus.shipping),
        isTrue,
      );
      final shipped = orderThree(provider);
      expect(shipped.status, OrderStatus.shipping);

      await provider.updateOrderStatus(shipped, OrderStatus.delivered);

      final stats = provider.dashboard!.stats;
      expect(stats.deliveredRevenue, revenue + order.total);
      expect(provider.isUpdatingStatus, isFalse);
      expect(provider.statusError, isNull);
    });

    test(
      'đơn đã đổi ở nơi khác: trả false, có lỗi, hết trạng thái lưu',
      () async {
        final provider = AdminDashboardProvider(repository);
        await provider.load();
        final stale = orderThree(provider);
        await db.update(DbSchema.orders, {
          'status': 'SHIPPING',
        }, where: 'id = 3');

        expect(
          await provider.updateOrderStatus(stale, OrderStatus.cancelled),
          isFalse,
        );

        expect(
          provider.statusError,
          'Đơn đã được cập nhật ở nơi khác, vui lòng tải lại',
        );
        expect(provider.isUpdatingStatus, isFalse);

        provider.clearStatusError();
        expect(provider.statusError, isNull);
      },
    );

    test('bấm 2 lần: lần thứ hai bị bỏ qua, chỉ hoàn kho một lần', () async {
      final provider = AdminDashboardProvider(repository);
      await provider.load();
      final order = orderThree(provider);
      Future<int> stock() async =>
          (await db.query(
                DbSchema.products,
                columns: ['stock'],
                where: 'id = 13',
              )).single['stock']
              as int;
      final before = await stock();

      final first = provider.updateOrderStatus(order, OrderStatus.cancelled);
      final second = provider.updateOrderStatus(order, OrderStatus.cancelled);

      expect(provider.isUpdatingStatus, isTrue);
      expect(await second, isFalse);
      expect(await first, isTrue);
      expect(await stock(), before + 1);
      expect(provider.statusError, isNull);
    });

    test(
      'lỗi lạ (không phải AppException): không kẹt trạng thái lưu',
      () async {
        final provider = AdminDashboardProvider(_ThrowingRepository(db));
        await provider.load();
        final order = orderThree(provider);

        expect(
          await provider.updateOrderStatus(order, OrderStatus.shipping),
          isFalse,
        );

        expect(provider.isUpdatingStatus, isFalse);
        expect(
          provider.statusError,
          'Không thể cập nhật trạng thái đơn. Vui lòng thử lại.',
        );
      },
    );
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

/// Ném `Error` (không phải Exception) để kiểm tra khối `catch (error)` cuối.
class _ThrowingRepository extends AdminDashboardRepository {
  _ThrowingRepository(Database db)
    : super(database: () async => db, dashboardDao: const AdminDashboardDao());

  @override
  Future<Order> updateOrderStatus(Order order, OrderStatus to) async =>
      throw StateError('boom');
}
