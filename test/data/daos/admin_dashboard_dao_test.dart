import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/admin_dashboard_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Đối chiếu số liệu Dashboard (S13 · UC16) với dữ liệu seed.
void main() {
  late Database db;
  const dao = AdminDashboardDao();

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
  });

  tearDown(() => db.close());

  test('4 thẻ số liệu khớp seed', () async {
    final stats = await dao.getStats(db);

    expect(stats.totalProducts, 22);
    expect(stats.lowStockCount, 3);
    expect(stats.pendingOrderCount, 0);
    expect(stats.deliveredRevenue, 4130000);
  });

  test('sắp hết hàng: tồn kho tăng dần, khớp số trên thẻ', () async {
    final products = await dao.getLowStockProducts(db);
    final stats = await dao.getStats(db);

    expect(products.map((p) => (p.name, p.stock)), [
      ('Li-Ning Axforce 80', 0),
      ('Yonex Nanoflare 800 Pro', 3),
      ('Victor Backpack', 4),
    ]);
    expect(products, hasLength(stats.lowStockCount));
  });

  test('sản phẩm đang ẩn không tính là sắp hết', () async {
    await db.update(DbSchema.products, {'is_active': 0}, where: 'id = 3');

    expect((await dao.getStats(db)).lowStockCount, 2);
    expect(await dao.getLowStockProducts(db), hasLength(2));
    expect((await dao.getStats(db)).totalProducts, 22);
  });

  test('đơn gần đây: mới nhất trước, kèm tên khách và tổng tiền', () async {
    final recent = await dao.getRecentOrders(db);

    expect(recent.map((r) => (r.order.status, r.order.total)), [
      (OrderStatus.confirmed, 620000),
      (OrderStatus.shipping, 2590000),
      (OrderStatus.cancelled, 920000),
      (OrderStatus.delivered, 4130000),
    ]);
    expect(recent.map((r) => r.customerName).toSet(), {'Nguyễn Minh Anh'});
  });

  test('chưa có đơn: thẻ đơn và doanh thu bằng 0, danh sách trống', () async {
    await db.delete(DbSchema.orders);

    final stats = await dao.getStats(db);
    expect(stats.pendingOrderCount, 0);
    expect(stats.deliveredRevenue, 0);
    expect(await dao.getRecentOrders(db), isEmpty);
  });
}
