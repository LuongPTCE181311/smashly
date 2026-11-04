import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/database/seed/seed_users.dart';
import 'package:smashly/data/repositories/wishlist_repository.dart';
import 'package:smashly/providers/wishlist_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late WishlistProvider provider;

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
    provider = WishlistProvider(WishlistRepository(database: () async => db));
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

  test('chưa đăng nhập: empty, count 0', () {
    expect(provider.status, ViewStatus.empty);
    expect(provider.count, 0);
  });

  test('updateUser không notify đồng bộ, tải ở microtask', () async {
    var calls = 0;
    provider.addListener(() => calls++);

    provider.updateUser(SeedUserIds.customer);

    expect(calls, 0);
    expect(provider.status, ViewStatus.initial);

    await settle();

    expect(provider.status, ViewStatus.empty);
    expect(provider.count, 0);
    expect(calls, greaterThan(0));
  });
}
