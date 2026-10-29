import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/models/product.dart';
import 'package:smashly/data/models/product_query.dart';
import 'package:smashly/data/models/racket_spec.dart';
import 'package:smashly/data/repositories/product_repository.dart';
import 'package:smashly/providers/admin_product_form_provider.dart';
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

  Future<int> categoryId(String name) async {
    final rows = await db.query(
      DbSchema.categories,
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
    );
    return rows.single['id'] as int;
  }

  Future<int> countRows(String table, String where, List<Object?> args) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $table WHERE $where',
      args,
    );
    return rows.single['c'] as int;
  }

  test('thêm mới: tải danh mục, chưa có sản phẩm nào để điền', () async {
    final form = AdminProductFormProvider(repository);
    await form.load();

    expect(form.isEditing, isFalse);
    expect(form.status, ViewStatus.success);
    expect(form.categories, isNotEmpty);
    expect(form.product, isNull);
    expect(form.isRacketCategory(await categoryId('Rackets')), isTrue);
    expect(form.isRacketCategory(await categoryId('Shoes')), isFalse);
    expect(form.isRacketCategory(null), isFalse);
  });

  test('thêm vợt mới: ghi products + racket_specs và hiện ở Shop', () async {
    final form = AdminProductFormProvider(repository);
    await form.load();

    final saved = await form.save(
      _product(categoryId: await categoryId('Rackets'), name: 'Vợt UC18'),
      _spec(),
    );

    expect(saved, isTrue);
    expect(form.isSaving, isFalse);
    final rows = await db.query(
      DbSchema.products,
      where: 'name = ?',
      whereArgs: ['Vợt UC18'],
    );
    final id = rows.single['id'] as int;
    expect(await countRows(DbSchema.racketSpecs, 'product_id = ?', [id]), 1);

    // Màn Shop của khách đọc qua searchProducts → thấy ngay sản phẩm mới.
    final shopProducts = await repository.searchProducts(const ProductQuery());
    expect(shopProducts.any((p) => p.id == id), isTrue);
  });

  test('sửa: tải sẵn sản phẩm và thông số vợt cũ', () async {
    final form = AdminProductFormProvider(repository, productId: 1);
    await form.load();

    expect(form.isEditing, isTrue);
    expect(form.status, ViewStatus.success);
    expect(form.product?.id, 1);
    expect(form.racketSpec, isNotNull);
  });

  test('sửa vợt sang Giày (spec null) thì xóa racket_specs cũ', () async {
    final form = AdminProductFormProvider(repository, productId: 1);
    await form.load();
    final shoesId = await categoryId('Shoes');

    await form.save(
      _product(id: 1, categoryId: shoesId, name: 'Đã đổi thành giày'),
      null,
    );

    final rows = await db.query(
      DbSchema.products,
      where: 'id = ?',
      whereArgs: [1],
    );
    expect(rows.single['category_id'], shoesId);
    expect(rows.single['name'], 'Đã đổi thành giày');
    expect(await countRows(DbSchema.racketSpecs, 'product_id = ?', [1]), 0);
  });

  test('sửa id không tồn tại → trạng thái lỗi kèm thông báo', () async {
    final form = AdminProductFormProvider(repository, productId: 99999);
    await form.load();

    expect(form.status, ViewStatus.error);
    expect(form.errorMessage, contains('Không tìm thấy sản phẩm'));
  });

  test('SQLite từ chối (giá = 0) → ném AppException, không ghi gì', () async {
    final form = AdminProductFormProvider(repository);
    await form.load();
    final before = await countRows(DbSchema.products, '1 = 1', []);

    await expectLater(
      form.save(
        _product(categoryId: await categoryId('Shoes'), price: 0),
        null,
      ),
      throwsA(isA<AppException>()),
    );

    expect(form.isSaving, isFalse);
    expect(await countRows(DbSchema.products, '1 = 1', []), before);
  });

  test('vợt có spec sai: transaction hủy cả dòng products', () async {
    final form = AdminProductFormProvider(repository);
    await form.load();
    final before = await countRows(DbSchema.products, '1 = 1', []);

    await expectLater(
      form.save(
        _product(categoryId: await categoryId('Rackets')),
        _spec(weightClass: '9U'), // vi phạm CHECK weight_class
      ),
      throwsA(isA<AppException>()),
    );

    expect(await countRows(DbSchema.products, '1 = 1', []), before);
  });
}

Product _product({
  int id = 0,
  required int categoryId,
  String name = 'Sản phẩm test',
  int price = 1500000,
}) {
  return Product(
    id: id,
    categoryId: categoryId,
    name: name,
    brand: 'Yonex',
    price: price,
    stock: 10,
    rating: 0,
    ratingCount: 0,
    description: '',
    imagePath: 'assets/images/products/rackets/racket_yonex_astrox99pro.png',
    isFeatured: false,
    isActive: true,
  );
}

RacketSpec _spec({String weightClass = '4U'}) {
  return RacketSpec(
    productId: 0,
    weightClass: weightClass,
    balance: 'HEAD_HEAVY',
    shaft: 'STIFF',
    maxTensionLbs: 28,
    playerLevel: 'ADVANCED',
    playStyle: 'ATTACK',
  );
}
