import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  const dao = CartDao();
  const userId = 3; // newbie@smashly.com

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

  test('getOrCreateCartId creates once then reuses', () async {
    final first = await dao.getOrCreateCartId(db, userId);
    final second = await dao.getOrCreateCartId(db, userId);
    expect(second, first);
  });

  test('insert, join price from products, select, quantity, delete', () async {
    final cartId = await dao.getOrCreateCartId(db, userId);
    final itemId = await dao.insertLine(
      db,
      cartId: cartId,
      productId: 2,
      quantity: 2,
      size: '',
    );

    var items = await dao.findItems(db, cartId);
    expect(items, hasLength(1));
    expect(items.single.quantity, 2);
    expect(items.single.isSelected, isTrue);
    expect(items.single.lineTotal, items.single.price * 2);

    expect(await dao.findLine(db, cartId, 2, ''), isNotNull);
    expect(await dao.findLine(db, cartId, 2, '42'), isNull);

    await dao.updateQuantity(db, itemId, 3);
    await dao.setSelected(db, itemId, false);
    items = await dao.findItems(db, cartId);
    expect(items.single.quantity, 3);
    expect(items.single.isSelected, isFalse);

    await dao.setAllSelected(db, cartId, true);
    expect(await dao.deleteSelected(db, cartId), 1);
    expect(await dao.findItems(db, cartId), isEmpty);
  });
}
