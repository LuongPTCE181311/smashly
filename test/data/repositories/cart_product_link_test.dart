import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Hợp đồng dữ liệu cho việc bấm sản phẩm trong giỏ để mở Product Detail:
/// mỗi dòng giỏ phải mang `productId` hợp lệ, kể cả khi sản phẩm đổi trạng thái.
void main() {
  late Database db;
  late CartRepository repo;
  const newbie = 3; // giỏ trống
  const customer = 2; // giỏ có sẵn product 19

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
    repo = CartRepository(database: () async => db, cartDao: const CartDao());
  });

  tearDown(() => db.close());

  Future<Set<int>> existingProductIds() async {
    final rows = await db.query(DbSchema.products, columns: ['id']);
    return {for (final r in rows) r['id'] as int};
  }

  test('mỗi dòng giỏ mang đúng productId của sản phẩm đã thêm', () async {
    await repo.addToCart(userId: newbie, productId: 2);
    await repo.addToCart(userId: newbie, productId: 20);
    await repo.addToCart(userId: newbie, productId: 10, size: '41');

    final items = await repo.loadItems(newbie);

    expect(items.map((i) => i.productId).toSet(), {2, 20, 10});
    expect(
      items
          .map((i) => i.productId)
          .toSet()
          .difference(await existingProductIds()),
      isEmpty,
      reason: 'không có productId trỏ vào sản phẩm không tồn tại',
    );
  });

  test('nhiều size của một sản phẩm cùng trỏ về một productId', () async {
    await repo.addToCart(userId: newbie, productId: 10, size: '41');
    await repo.addToCart(userId: newbie, productId: 10, size: '42');

    final items = await repo.loadItems(newbie);

    expect(items, hasLength(2));
    expect(items.map((i) => i.productId).toSet(), {10});
    expect(items.map((i) => i.size).toSet(), {'41', '42'});
  });

  test(
    'sản phẩm ngừng bán vẫn nằm trong giỏ với productId để mở chi tiết',
    () async {
      await db.update(
        DbSchema.products,
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [19],
      );

      final items = await repo.loadItems(customer);

      expect(items.single.productId, 19);
      expect(items.single.name, isNotEmpty);
    },
  );

  test(
    'xóa hẳn sản phẩm thì dòng giỏ biến mất, không để lại productId treo',
    () async {
      await db.delete(DbSchema.products, where: 'id = ?', whereArgs: [19]);

      final items = await repo.loadItems(customer);

      expect(items, isEmpty, reason: 'cart_items.product_id ON DELETE CASCADE');
    },
  );

  test('giỏ của mỗi người chỉ trỏ tới sản phẩm của chính giỏ đó', () async {
    await repo.addToCart(userId: newbie, productId: 5);

    final mine = await repo.loadItems(newbie);
    final theirs = await repo.loadItems(customer);

    expect(mine.map((i) => i.productId), [5]);
    expect(theirs.map((i) => i.productId), [19]);
  });
}
