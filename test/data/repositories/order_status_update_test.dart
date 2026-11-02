import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/daos/order_dao.dart';
import 'package:smashly/data/repositories/order_repository.dart';
import 'package:smashly/features/orders/widgets/order_timeline.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// UC19 trên DB seed. Đơn seed: 1 DELIVERED · 2 SHIPPING (product 10) ·
/// 3 CONFIRMED (product 13) · 4 CANCELLED.
void main() {
  late Database db;
  late OrderRepository repo;
  const delivered = 1;
  const shipping = 2;
  const confirmed = 3;
  const cancelled = 4;
  const shirt = 13; // sản phẩm của đơn 3, số lượng 1
  final timeFormat = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');

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
    repo = OrderRepository(
      database: () async => db,
      orderDao: const OrderDao(),
    );
  });

  tearDown(() => db.close());

  Future<Map<String, Object?>> rowOf(int orderId) async {
    final rows = await db.query(
      DbSchema.orders,
      where: 'id = ?',
      whereArgs: [orderId],
    );
    return rows.single;
  }

  Future<int> stockOf(int productId) async {
    final rows = await db.query(
      DbSchema.products,
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    return rows.single['stock'] as int;
  }

  /// Đưa đơn 3 về PENDING (seed không có đơn PENDING).
  Future<void> makePending(int orderId) => db.update(
    DbSchema.orders,
    {'status': OrderStatus.pending.dbValue, 'confirmed_at': null},
    where: 'id = ?',
    whereArgs: [orderId],
  );

  test('đi hết luồng: mỗi bước ghi đúng cột, đúng định dạng dbTime', () async {
    await makePending(confirmed);

    await repo.updateStatus(
      confirmed,
      from: OrderStatus.pending,
      to: OrderStatus.confirmed,
    );
    var row = await rowOf(confirmed);
    expect(row['status'], 'CONFIRMED');
    expect(row['confirmed_at'] as String, matches(timeFormat));
    expect(row['shipped_at'], isNull);

    await repo.updateStatus(
      confirmed,
      from: OrderStatus.confirmed,
      to: OrderStatus.shipping,
    );
    row = await rowOf(confirmed);
    expect(row['status'], 'SHIPPING');
    expect(row['shipped_at'] as String, matches(timeFormat));
    expect(row['delivered_at'], isNull);

    final order = await repo.updateStatus(
      confirmed,
      from: OrderStatus.shipping,
      to: OrderStatus.delivered,
    );
    row = await rowOf(confirmed);
    expect(row['status'], 'DELIVERED');
    expect(row['delivered_at'] as String, matches(timeFormat));
    expect(row['cancelled_at'], isNull);
    expect(order.status, OrderStatus.delivered);
    expect(order.deliveredAt, isNotNull);
  });

  test('bước thường không đụng tới tồn kho', () async {
    final before = await stockOf(shirt);

    await repo.updateStatus(
      confirmed,
      from: OrderStatus.confirmed,
      to: OrderStatus.shipping,
    );

    expect(await stockOf(shirt), before);
  });

  for (final from in [OrderStatus.pending, OrderStatus.confirmed]) {
    test('hủy từ ${from.name}: ghi cancelled_at và hoàn kho', () async {
      if (from == OrderStatus.pending) await makePending(confirmed);
      final before = await stockOf(shirt);

      final order = await repo.updateStatus(
        confirmed,
        from: from,
        to: OrderStatus.cancelled,
      );

      final row = await rowOf(confirmed);
      expect(row['status'], 'CANCELLED');
      expect(row['cancelled_at'] as String, matches(timeFormat));
      expect(order.cancelledAt, isNotNull);
      expect(await stockOf(shirt), before + 1);
    });
  }

  test('hủy đơn có sản phẩm đã bị xóa: bỏ qua dòng đó, không lỗi', () async {
    await db.update(
      DbSchema.orderItems,
      {'product_id': null},
      where: 'order_id = ?',
      whereArgs: [confirmed],
    );

    await repo.updateStatus(
      confirmed,
      from: OrderStatus.confirmed,
      to: OrderStatus.cancelled,
    );

    expect((await rowOf(confirmed))['status'], 'CANCELLED');
  });

  test('hoàn kho lỗi giữa transaction: rollback, đơn giữ nguyên', () async {
    // Lỗi thật do SQLite sinh ra khi cộng kho, sau khi đơn đã được UPDATE.
    await db.execute(
      'CREATE TRIGGER fail_stock BEFORE UPDATE OF stock ON ${DbSchema.products} '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );

    await expectLater(
      repo.updateStatus(
        confirmed,
        from: OrderStatus.confirmed,
        to: OrderStatus.cancelled,
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Không thể cập nhật trạng thái đơn hàng. Vui lòng thử lại.',
        ),
      ),
    );

    final row = await rowOf(confirmed);
    expect(row['status'], 'CONFIRMED');
    expect(row['cancelled_at'], isNull);
  });

  test(
    'khách mở Order Detail: timeline hiện đúng thời gian admin vừa ghi',
    () async {
      const customer = 2;
      await repo.updateStatus(
        confirmed,
        from: OrderStatus.confirmed,
        to: OrderStatus.shipping,
      );

      var order = (await repo.getOrderDetail(confirmed, userId: customer))!;
      var steps = TimelineStep.fromOrder(order);
      expect(steps[2].status, OrderStatus.shipping);
      expect(steps[2].state, TimelineStepState.current);
      expect(steps[2].time, order.shippedAt);
      expect(steps[2].time, isNotNull);
      expect(steps[3].state, TimelineStepState.upcoming);

      await repo.updateStatus(
        confirmed,
        from: OrderStatus.shipping,
        to: OrderStatus.delivered,
      );
      order = (await repo.getOrderDetail(confirmed, userId: customer))!;
      steps = TimelineStep.fromOrder(order);
      expect(steps.every((s) => s.state == TimelineStepState.done), isTrue);
      expect(steps[3].time, order.deliveredAt);
    },
  );

  test(
    'admin hủy đơn CONFIRMED: timeline giữ bước đã qua + nhánh hủy',
    () async {
      final order = await repo.updateStatus(
        confirmed,
        from: OrderStatus.confirmed,
        to: OrderStatus.cancelled,
      );

      final steps = TimelineStep.fromOrder(order);
      expect(steps.map((s) => s.status), [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.cancelled,
      ]);
      expect(steps.last.time, order.cancelledAt);
    },
  );

  test('chặn sai luật: nhảy bước, lùi bước, hủy khi đang giao', () async {
    final before = await rowOf(shipping);

    for (final to in [OrderStatus.pending, OrderStatus.cancelled]) {
      await expectLater(
        repo.updateStatus(shipping, from: OrderStatus.shipping, to: to),
        throwsA(isA<AppException>()),
      );
    }
    await expectLater(
      repo.updateStatus(
        confirmed,
        from: OrderStatus.pending,
        to: OrderStatus.delivered,
      ),
      throwsA(isA<AppException>()),
    );

    expect(await rowOf(shipping), before);
  });

  test('trạng thái cuối không đổi được nữa', () async {
    for (final to in OrderStatus.values) {
      await expectLater(
        repo.updateStatus(delivered, from: OrderStatus.delivered, to: to),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        repo.updateStatus(cancelled, from: OrderStatus.cancelled, to: to),
        throwsA(isA<AppException>()),
      );
    }
  });

  test('dữ liệu cũ: đơn đã đổi ở nơi khác thì báo lỗi, không ghi đè', () async {
    // Admin đang xem đơn 3 là CONFIRMED, nhưng DB đã sang SHIPPING.
    await repo.updateStatus(
      confirmed,
      from: OrderStatus.confirmed,
      to: OrderStatus.shipping,
    );
    final before = await stockOf(shirt);

    await expectLater(
      repo.updateStatus(
        confirmed,
        from: OrderStatus.confirmed,
        to: OrderStatus.cancelled,
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Đơn đã được cập nhật ở nơi khác, vui lòng tải lại',
        ),
      ),
    );

    final row = await rowOf(confirmed);
    expect(row['status'], 'SHIPPING');
    expect(row['cancelled_at'], isNull);
    expect(await stockOf(shirt), before);
  });

  test(
    'hủy đơn của khách (UC15) vẫn hoàn kho sau khi tách _restoreStock',
    () async {
      await makePending(confirmed);
      final before = await stockOf(shirt);

      await repo.cancelOrder(confirmed, userId: 2);

      expect((await rowOf(confirmed))['status'], 'CANCELLED');
      expect(await stockOf(shirt), before + 1);
    },
  );
}
