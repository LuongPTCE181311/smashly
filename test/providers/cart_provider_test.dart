import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late CartProvider cart;
  const newbie = 3;
  const customer = 2;

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
    cart = CartProvider(
      CartRepository(database: () async => db, cartDao: const CartDao()),
    );
  });

  // updateUser tải ở microtask, sqflite_ffi trả kết quả bất đồng bộ thật.
  Future<void> settle() async {
    await pumpEventQueue();
    while (cart.status == ViewStatus.loading) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  tearDown(() async {
    cart.dispose();
    await db.close();
  });

  test('updateUser clears the previous cart, then loads the new one', () async {
    cart.updateUser(customer);
    await settle();
    expect(cart.status, ViewStatus.success);
    expect(cart.items, hasLength(1));

    cart.updateUser(newbie);
    expect(cart.items, isEmpty, reason: 'giỏ cũ phải biến mất ngay');
    await settle();
    expect(cart.status, ViewStatus.empty);

    cart.updateUser(customer);
    cart.updateUser(null);
    await settle();
    expect(cart.items, isEmpty);
    expect(cart.status, ViewStatus.empty);
  });

  test('addToCart, totals, badge count and stock error message', () async {
    cart.updateUser(newbie);
    await settle();

    expect(await cart.addToCart(productId: 2, quantity: 2), isNull);
    expect(cart.itemCount, 1, reason: "badge đếm mặt hàng, không đếm số lượng");
    expect(cart.items.single.quantity, 2);
    expect(cart.selectedTotal, cart.items.single.price * 2);

    await db.update(
      DbSchema.products,
      {'stock': 2},
      where: 'id = ?',
      whereArgs: [2],
    );
    expect(await cart.addToCart(productId: 2), 'Chỉ còn 2 sản phẩm trong kho');
    expect(cart.itemCount, 1);
    expect(cart.items.single.quantity, 2);
  });

  test('toggle, select all and unavailable guard', () async {
    cart.updateUser(customer);
    await settle();
    final item = cart.items.single;

    await cart.toggleSelected(item);
    expect(cart.selectedCount, 0);
    expect(cart.selectedTotal, 0);

    await cart.setAllSelected(true);
    expect(cart.allSelected, isTrue);

    await db.update(
      DbSchema.products,
      {'stock': 0},
      where: 'id = ?',
      whereArgs: [item.productId],
    );
    await cart.load();
    expect(cart.hasUnavailableSelected, isTrue);
  });

  test('remove is immediate and undoRemove brings the item back', () async {
    cart.updateUser(customer);
    await settle();
    final item = cart.items.single;

    final removing = cart.remove(item);
    expect(cart.items, isEmpty);
    expect(cart.status, ViewStatus.empty);
    expect(await removing, isNull);

    expect(await cart.undoRemove(), isNull);
    expect(cart.items.single.productId, item.productId);
    expect(cart.status, ViewStatus.success);
  });
}
