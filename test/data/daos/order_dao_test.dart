import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/database/seed/seed_users.dart';
import 'package:smashly/data/daos/order_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  const dao = OrderDao();

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

  test('đơn của customer: đủ 4 đơn, mới nhất lên đầu', () async {
    final summaries = await dao.findSummariesByUser(db, SeedUserIds.customer);

    expect(summaries, hasLength(4));
    expect(summaries.map((s) => s.order.status), [
      OrderStatus.confirmed,
      OrderStatus.shipping,
      OrderStatus.cancelled,
      OrderStatus.delivered,
    ]);
    final dates = summaries.map((s) => s.order.createdAt).toList();
    for (var i = 1; i < dates.length; i++) {
      expect(dates[i - 1].isAfter(dates[i]), isTrue);
    }
  });

  test('tóm tắt có món đầu tiên và số món của đơn', () async {
    final summaries = await dao.findSummariesByUser(db, SeedUserIds.customer);
    final delivered = summaries.firstWhere(
      (s) => s.order.status == OrderStatus.delivered,
    );

    expect(delivered.itemCount, 2);
    expect(delivered.otherItemCount, 1);
    expect(delivered.firstItem?.productName, 'Yonex Astrox 77 Pro');
  });

  test('newbie chưa có đơn nào', () async {
    expect(await dao.findSummariesByUser(db, SeedUserIds.newbie), isEmpty);
  });

  test('findById trả đơn kèm đủ món, không có thì null', () async {
    final summaries = await dao.findSummariesByUser(db, SeedUserIds.customer);
    final id = summaries.last.order.id;

    final order = await dao.findById(db, id);
    expect(order?.items, hasLength(summaries.last.itemCount));
    expect(await dao.findById(db, 9999), isNull);
  });
}
