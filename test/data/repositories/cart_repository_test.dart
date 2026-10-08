import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late CartRepository repo;
  const newbie = 3; // newbie@smashly.com, giỏ trống
  const customer = 2; // customer@smashly.com, giỏ có sẵn 1 món (product 19)

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

  Future<void> setStock(int productId, int stock) => db.update(
    DbSchema.products,
    {'stock': stock},
    where: 'id = ?',
    whereArgs: [productId],
  );

  test('seeded customer cart loads with price joined from products', () async {
    final items = await repo.loadItems(customer);
    expect(items, hasLength(1));
    expect(items.single.productId, 19);
    expect(items.single.price, greaterThan(0));
  });

  test('addToCart merges same product+size and stops at stock', () async {
    await setStock(2, 3);
    await repo.addToCart(userId: newbie, productId: 2, quantity: 2);
    await repo.addToCart(userId: newbie, productId: 2);

    var items = await repo.loadItems(newbie);
    expect(items, hasLength(1));
    expect(items.single.quantity, 3);

    await expectLater(
      repo.addToCart(userId: newbie, productId: 2),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Chỉ còn 3 sản phẩm trong kho',
        ),
      ),
    );
    items = await repo.loadItems(newbie);
    expect(items.single.quantity, 3);
  });

  test('different size is a separate line', () async {
    await repo.addToCart(userId: newbie, productId: 10, size: '41');
    await repo.addToCart(userId: newbie, productId: 10, size: '42');
    expect(await repo.loadItems(newbie), hasLength(2));
  });

  test('sold out or inactive product is rejected', () async {
    await setStock(2, 0);
    await expectLater(
      repo.addToCart(userId: newbie, productId: 2),
      throwsA(isA<AppException>()),
    );
    await db.update(
      DbSchema.products,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [5],
    );
    await expectLater(
      repo.addToCart(userId: newbie, productId: 5),
      throwsA(isA<AppException>()),
    );
    expect(await repo.loadItems(newbie), isEmpty);
  });

  test('setQuantity respects stock; remove + restore keeps the line', () async {
    await setStock(19, 4);
    final item = (await repo.loadItems(customer)).single;

    await repo.setQuantity(item, 4);
    await expectLater(repo.setQuantity(item, 5), throwsA(isA<AppException>()));

    await repo.setSelected(item, false);
    final updated = (await repo.loadItems(customer)).single;
    expect(updated.quantity, 4);
    expect(updated.isSelected, isFalse);

    await repo.remove(updated);
    expect(await repo.loadItems(customer), isEmpty);

    await repo.restore(customer, updated);
    final restored = (await repo.loadItems(customer)).single;
    expect(restored.quantity, 4);
    expect(restored.isSelected, isFalse);
  });

  test('setAllSelected only touches the given user cart', () async {
    await repo.addToCart(userId: newbie, productId: 2);
    await repo.setAllSelected(newbie, false);

    expect((await repo.loadItems(newbie)).single.isSelected, isFalse);
    expect((await repo.loadItems(customer)).single.isSelected, isTrue);
  });
}
