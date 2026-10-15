import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/database/seed/seed_users.dart';
import 'package:smashly/data/daos/order_dao.dart';
import 'package:smashly/data/models/order.dart';
import 'package:smashly/data/repositories/order_repository.dart';
import 'package:smashly/features/orders/widgets/order_timeline.dart';
import 'package:smashly/providers/order_detail_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late OrderRepository repository;

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
    repository = OrderRepository(
      database: () async => db,
      orderDao: const OrderDao(),
    );
  });

  tearDown(() => db.close());

  Future<int> orderIdWith(OrderStatus status) async {
    final rows = await db.query(
      DbSchema.orders,
      columns: ['id'],
      where: 'status = ?',
      whereArgs: [status.dbValue],
    );
    return rows.first['id'] as int;
  }

  Future<OrderDetailProvider> loaded(int? orderId, int? userId) async {
    final provider = OrderDetailProvider(
      repository,
      orderId: orderId,
      userId: userId,
    );
    await provider.load();
    return provider;
  }

  Future<Order> orderWith(OrderStatus status) async {
    final provider = await loaded(
      await orderIdWith(status),
      SeedUserIds.customer,
    );
    return provider.order!;
  }

  test('chủ đơn xem được đơn kèm đủ món từ snapshot', () async {
    final provider = await loaded(
      await orderIdWith(OrderStatus.delivered),
      SeedUserIds.customer,
    );

    expect(provider.status, ViewStatus.success);
    expect(provider.order?.items, hasLength(2));
    expect(provider.order?.items.first.productName, 'Yonex Astrox 77 Pro');
  });

  test('người khác không xem được đơn không phải của mình', () async {
    final provider = await loaded(
      await orderIdWith(OrderStatus.delivered),
      SeedUserIds.newbie,
    );

    expect(provider.status, ViewStatus.empty);
    expect(provider.order, isNull);
  });

  test('id sai, không có id hoặc chưa đăng nhập: empty', () async {
    expect((await loaded(9999, SeedUserIds.customer)).status, ViewStatus.empty);
    expect((await loaded(null, SeedUserIds.customer)).status, ViewStatus.empty);
    expect((await loaded(1, null)).status, ViewStatus.empty);
  });

  test('timeline đơn đã giao: 4 bước đều xong', () async {
    final steps = TimelineStep.fromOrder(
      await orderWith(OrderStatus.delivered),
    );

    expect(steps.map((s) => s.state), everyElement(TimelineStepState.done));
    expect(steps, hasLength(4));
  });

  test(
    'timeline đơn đang giao: 2 bước xong, bước 3 hiện tại, bước 4 chưa tới',
    () async {
      final steps = TimelineStep.fromOrder(
        await orderWith(OrderStatus.shipping),
      );

      expect(steps.map((s) => s.state), [
        TimelineStepState.done,
        TimelineStepState.done,
        TimelineStepState.current,
        TimelineStepState.upcoming,
      ]);
    },
  );

  test('timeline đơn đã hủy: dừng ở bước đã đạt và thêm bước Đã hủy', () async {
    final steps = TimelineStep.fromOrder(
      await orderWith(OrderStatus.cancelled),
    );

    expect(steps.last.status, OrderStatus.cancelled);
    expect(steps.last.state, TimelineStepState.cancelled);
    expect(steps.where((s) => s.status == OrderStatus.delivered), isEmpty);
  });
}
