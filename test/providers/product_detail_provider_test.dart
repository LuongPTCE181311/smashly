import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/data/repositories/product_repository.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:smashly/providers/product_detail_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late ProductRepository repository;

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
    repository = ProductRepository(
      database: () async => db,
      productDao: const ProductDao(),
    );
  });

  tearDown(() => db.close());

  Future<ProductDetailProvider> loaded(int? productId) async {
    final provider = ProductDetailProvider(repository, productId);
    await provider.load();
    return provider;
  }

  test('vợt: tải sản phẩm kèm thông số, không cần size', () async {
    final provider = await loaded(1);

    expect(provider.status, ViewStatus.success);
    expect(provider.product?.name, 'Yonex Astrox 99 Pro');
    expect(provider.racketSpec, isNotNull);
    expect(provider.needsSize, isFalse);
    expect(provider.canAddToCart, isTrue);
  });

  test('giày: có size, phải chọn size mới thêm được vào giỏ', () async {
    final provider = await loaded(10);

    expect(provider.racketSpec, isNull);
    expect(provider.sizes, contains('42'));
    expect(provider.canAddToCart, isFalse);

    provider.selectSize('42');
    expect(provider.canAddToCart, isTrue);
  });

  test('hết hàng: không cho thêm vào giỏ', () async {
    final provider = await loaded(8);

    expect(provider.isOutOfStock, isTrue);
    expect(provider.canAddToCart, isFalse);
  });

  test('không tìm thấy hoặc ngừng bán: trạng thái empty', () async {
    expect((await loaded(9999)).status, ViewStatus.empty);
    expect((await loaded(null)).status, ViewStatus.empty);

    await db.update(DbSchema.products, {'is_active': 0}, where: 'id = 1');
    expect((await loaded(1)).status, ViewStatus.empty);
  });

  test('số lượng không vượt tồn kho và không nhỏ hơn 1', () async {
    final provider = await loaded(3);

    provider.decrease();
    expect(provider.quantity, 1);
    for (var i = 0; i < 10; i++) {
      provider.increase();
    }
    expect(provider.quantity, provider.stock);
  });

  test('thêm vào giỏ ghi xuống cart_items với đúng size', () async {
    final cart = CartProvider(
      CartRepository(database: () async => db, cartDao: const CartDao()),
    )..updateUser(3);
    final provider = await loaded(10);
    provider
      ..selectSize('42')
      ..increase();

    final error = await provider.addToCart(cart);

    expect(error, isNull);
    expect(provider.quantity, 1);
    final rows = await db.query(
      DbSchema.cartItems,
      where: 'product_id = ? AND size = ?',
      whereArgs: [10, '42'],
    );
    expect(rows.single['quantity'], 2);
  });
}
