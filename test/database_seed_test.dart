import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/password_hasher.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

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

  tearDown(() async {
    await db.close();
  });

  test('seed tạo đúng số dòng cho từng bảng', () async {
    const expectedCounts = {
      DbSchema.users: 3,
      DbSchema.categories: 10,
      DbSchema.products: 22,
      DbSchema.racketSpecs: 9,
      DbSchema.carts: 2,
      DbSchema.cartItems: 1,
      DbSchema.orders: 4,
      DbSchema.orderItems: 5,
      DbSchema.wishlists: 0,
    };

    for (final entry in expectedCounts.entries) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${entry.key}',
      );
      expect(result.single['count'], entry.value, reason: entry.key);
    }
  });

  test('onConfigure bật khóa ngoại SQLite', () async {
    final result = await db.rawQuery('PRAGMA foreign_keys');

    expect(result.single.values.single, 1);
  });

  test('cart_items từ chối size trùng rỗng cho cùng giỏ và sản phẩm', () async {
    final carts = await db.query(
      DbSchema.carts,
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [2],
    );
    final cartId = carts.single['id'] as int;
    final item = {
      'cart_id': cartId,
      'product_id': 18,
      'quantity': 1,
      'size': '',
    };

    await db.insert(DbSchema.cartItems, item);
    await expectLater(
      db.insert(DbSchema.cartItems, item),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('hash mật khẩu customer khớp password_hash trong DB', () async {
    final users = await db.query(
      DbSchema.users,
      columns: ['password_hash'],
      where: 'email = ?',
      whereArgs: ['customer@smashly.com'],
    );

    expect(
      users.single['password_hash'],
      PasswordHasher.hash('customer@smashly.com', 'Customer@123'),
    );
  });
}
