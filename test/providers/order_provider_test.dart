import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/database/seed/seed_users.dart';
import 'package:smashly/data/daos/order_dao.dart';
import 'package:smashly/data/repositories/order_repository.dart';
import 'package:smashly/providers/order_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late OrderProvider provider;

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
    provider = OrderProvider(
      OrderRepository(database: () async => db, orderDao: const OrderDao()),
    );
  });

  tearDown(() async {
    provider.dispose();
    await db.close();
  });

  Future<void> settle() async {
    await pumpEventQueue();
    while (provider.status == ViewStatus.initial ||
        provider.status == ViewStatus.loading) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test('đăng nhập customer: tải 4 đơn, lọc đúng theo trạng thái', () async {
    provider.updateUser(SeedUserIds.customer);
    await settle();

    expect(provider.status, ViewStatus.success);
    expect(provider.countOf(null), 4);
    expect(provider.countOf(OrderStatus.shipping), 1);
    expect(provider.countOf(OrderStatus.pending), 0);
  });

  test('newbie: trạng thái empty nhưng vẫn là người đã đăng nhập', () async {
    provider.updateUser(SeedUserIds.newbie);
    await settle();

    expect(provider.status, ViewStatus.empty);
    expect(provider.isSignedIn, isTrue);
  });

  test('chưa đăng nhập: empty và không gọi database', () async {
    provider.updateUser(null);
    await pumpEventQueue();

    expect(provider.status, ViewStatus.empty);
    expect(provider.isSignedIn, isFalse);
  });

  test('refresh thấy đơn mới mà không quay lại loading', () async {
    provider.updateUser(SeedUserIds.customer);
    await settle();
    final first = await db.query(DbSchema.orders, limit: 1);
    await db.insert(DbSchema.orders, {
      ...first.single,
      'id': null,
      'order_code': 'SML-TEST-0099',
      'status': 'PENDING',
    });

    final refreshing = provider.refresh();
    expect(provider.status, ViewStatus.success);
    await refreshing;

    expect(provider.countOf(null), 5);
    expect(provider.countOf(OrderStatus.pending), 1);
  });
}
