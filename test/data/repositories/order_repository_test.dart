import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/daos/order_dao.dart';
import 'package:smashly/data/models/order.dart';
import 'package:smashly/data/repositories/order_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late OrderRepository repo;
  const cartDao = CartDao();
  const newbie = 3; // giỏ trống
  const rackets = 2; // product 2: Astrox 77 Pro
  const string = 20; // product 20: BG66

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

  Future<int> stockOf(int productId) async {
    final rows = await db.query(
      DbSchema.products,
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    return rows.single['stock'] as int;
  }

  Future<void> setStock(int productId, int stock) => db.update(
    DbSchema.products,
    {'stock': stock},
    where: 'id = ?',
    whereArgs: [productId],
  );

  Future<int> addToCart(
    int productId,
    int quantity, {
    bool selected = true,
  }) async {
    final cartId = await cartDao.getOrCreateCartId(db, newbie);
    return cartDao.insertLine(
      db,
      cartId: cartId,
      productId: productId,
      quantity: quantity,
      size: '',
      isSelected: selected,
    );
  }

  Future<int> count(String table) async =>
      (await db.rawQuery('SELECT COUNT(*) AS c FROM $table')).single['c']
          as int;

  Future<Order> place() => repo.placeOrder(
    userId: newbie,
    receiverName: 'An',
    receiverPhone: '0900000000',
    shippingAddress: '1 Le Loi',
  );

  test(
    'places order: snapshot items, decrease stock, remove bought lines',
    () async {
      await setStock(rackets, 10);
      await setStock(string, 10);
      await addToCart(rackets, 2);
      await addToCart(
        string,
        1,
        selected: false,
      ); // không mua, phải còn trong giỏ

      final before = await count(DbSchema.orders);
      final order = await place();

      expect(await count(DbSchema.orders), before + 1);
      expect(order.status, OrderStatus.pending);
      expect(order.paymentMethod, PaymentMethod.cod);
      expect(order.orderCode, startsWith('SML-'));
      expect(order.items, hasLength(1));
      expect(order.items.single.productId, rackets);
      expect(order.items.single.quantity, 2);
      expect(order.subtotal, order.items.single.lineTotal);
      expect(order.total, order.subtotal + order.shippingFee);
      expect(await stockOf(rackets), 8);
      expect(await stockOf(string), 10);

      final left = await cartDao.findItems(
        db,
        await cartDao.getOrCreateCartId(db, newbie),
      );
      expect(left.map((i) => i.productId), [string]);
    },
  );

  test('out of stock names the product and rolls everything back', () async {
    await setStock(rackets, 10);
    await setStock(string, 1);
    await addToCart(rackets, 2); // trừ kho trước, rồi mới gặp món hết hàng
    await addToCart(string, 5);

    final orders = await count(DbSchema.orders);
    final items = await count(DbSchema.orderItems);

    await expectLater(
      place(),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('BG66'),
        ),
      ),
    );

    expect(await stockOf(rackets), 10); // kho món đầu được hoàn lại
    expect(await stockOf(string), 1);
    expect(await count(DbSchema.orders), orders);
    expect(await count(DbSchema.orderItems), items);
    final cartId = await cartDao.getOrCreateCartId(db, newbie);
    expect(await cartDao.findItems(db, cartId), hasLength(2));
  });

  test('same product in two sizes cannot exceed stock together', () async {
    await setStock(rackets, 3);
    final cartId = await cartDao.getOrCreateCartId(db, newbie);
    for (final size in ['3U', '4U']) {
      await cartDao.insertLine(
        db,
        cartId: cartId,
        productId: rackets,
        quantity: 2,
        size: size,
      );
    }

    await expectLater(place(), throwsA(isA<AppException>()));
    expect(await stockOf(rackets), 3);
  });

  test('rejects empty selection and blank receiver info', () async {
    await expectLater(place(), throwsA(isA<AppException>()));

    await addToCart(rackets, 1);
    await expectLater(
      repo.placeOrder(
        userId: newbie,
        receiverName: ' ',
        receiverPhone: '0900000000',
        shippingAddress: '1 Le Loi',
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('shipping is free from 1.000.000 and 30.000 below', () async {
    await setStock(string, 10);
    await addToCart(string, 1);
    final cheap = await place();
    expect(cheap.subtotal, lessThan(1000000));
    expect(cheap.shippingFee, 30000);

    await setStock(rackets, 10);
    await addToCart(rackets, 1);
    final big = await place();
    expect(big.subtotal, greaterThanOrEqualTo(1000000));
    expect(big.shippingFee, 0);
  });
}
