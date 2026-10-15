import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/models/product.dart';
import 'package:smashly/data/repositories/product_repository.dart';
import 'package:smashly/providers/admin_product_provider.dart';
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

  Future<AdminProductProvider> loaded() async {
    final provider = AdminProductProvider(repository);
    await provider.loadInitial();
    return provider;
  }

  Future<int> totalProducts() async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbSchema.products}',
    );
    return rows.first['c'] as int;
  }

  Future<Product> productWhere(String where) async {
    final rows = await db.query(DbSchema.products, where: where, limit: 1);
    return Product.fromMap(rows.single);
  }

  test('tải đủ danh mục và mọi sản phẩm, kể cả đang ẩn', () async {
    await db.update(DbSchema.products, {'is_active': 0}, where: 'id = 1');

    final provider = await loaded();

    expect(provider.status, ViewStatus.success);
    expect(provider.categories, isNotEmpty);
    expect(provider.resultCount, await totalProducts());
    expect(provider.products.any((p) => p.id == 1 && !p.isActive), isTrue);
  });

  test('search theo tên hoặc brand, không phân biệt hoa thường', () async {
    final provider = await loaded();

    provider.setKeyword('ASTROX');
    await provider.loadProducts();
    expect(provider.products, isNotEmpty);
    expect(
      provider.products.every((p) => p.name.toLowerCase().contains('astrox')),
      isTrue,
    );

    provider.setKeyword('victor');
    await provider.loadProducts();
    expect(provider.products, isNotEmpty);
    expect(
      provider.products.every(
        (p) =>
            p.brand.toLowerCase() == 'victor' ||
            p.name.toLowerCase().contains('victor'),
      ),
      isTrue,
    );
  });

  test('lọc danh mục + "Đang ẩn" kết hợp bằng AND', () async {
    final racket = await productWhere(
      "category_id = (SELECT id FROM ${DbSchema.categories} "
      "WHERE name = 'Rackets')",
    );
    await db.update(
      DbSchema.products,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [racket.id],
    );
    final provider = await loaded();

    await provider.selectCategory(racket.categoryId);
    expect(
      provider.products.every((p) => p.categoryId == racket.categoryId),
      isTrue,
    );

    await provider.toggleHidden();
    expect(provider.products.map((p) => p.id), [racket.id]);

    await provider.resetFilters();
    expect(provider.query.hasFilter, isFalse);
    expect(provider.resultCount, await totalProducts());
  });

  test('lọc không ra kết quả → empty', () async {
    final provider = await loaded();

    provider.setKeyword('khong-co-san-pham-nay');
    await provider.loadProducts();

    expect(provider.status, ViewStatus.empty);
    expect(provider.query.hasFilter, isTrue);
  });

  test('xóa sản phẩm chưa có đơn → xóa thật, danh sách cập nhật', () async {
    final product = await productWhere(
      'id NOT IN (SELECT product_id FROM ${DbSchema.orderItems} '
      'WHERE product_id IS NOT NULL)',
    );
    final provider = await loaded();
    final before = provider.resultCount;

    expect(await provider.countOrdersOf(product), 0);
    final outcome = await provider.deleteProduct(product);

    expect(outcome, ProductDeleteOutcome.deleted);
    expect(provider.resultCount, before - 1);
    expect(provider.products.any((p) => p.id == product.id), isFalse);
    expect(provider.isBusy(product.id), isFalse);
  });

  test('xóa sản phẩm đã có đơn → ngừng bán, Hoàn tác bán lại', () async {
    final product = await productWhere(
      'is_active = 1 AND id IN (SELECT product_id FROM '
      '${DbSchema.orderItems})',
    );
    final provider = await loaded();

    expect(await provider.countOrdersOf(product), greaterThan(0));
    final outcome = await provider.deleteProduct(product);

    expect(outcome, ProductDeleteOutcome.deactivated);
    expect(
      provider.products.singleWhere((p) => p.id == product.id).isActive,
      isFalse,
    );

    await provider.restoreProduct(product);
    expect(
      provider.products.singleWhere((p) => p.id == product.id).isActive,
      isTrue,
    );
  });

  test('lỗi DB → error, Thử lại tải được', () async {
    var fail = true;
    final flaky = ProductRepository(
      database: () async => fail ? throw Exception('db down') : db,
      productDao: const ProductDao(),
    );
    final provider = AdminProductProvider(flaky);

    await provider.loadInitial();
    expect(provider.status, ViewStatus.error);
    expect(provider.errorMessage, isNotNull);

    fail = false;
    await provider.retry();
    expect(provider.status, ViewStatus.success);
  });
}
