import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/models/product.dart';
import 'package:smashly/data/models/racket_spec.dart';
import 'package:smashly/data/repositories/product_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late ProductRepository repository;
  late int racketsId;
  late int shoesId;

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
    racketsId = await _categoryIdByName(db, 'Rackets');
    shoesId = await _categoryIdByName(db, 'Shoes');
  });

  tearDown(() async {
    await db.close();
  });

  test('thêm vợt ghi cả products và racket_specs', () async {
    final id = await repository.addProduct(
      _product(categoryId: racketsId),
      _spec(),
    );

    expect(await _countRows(db, DbSchema.products, 'id', id), 1);
    final specs = await db.query(
      DbSchema.racketSpecs,
      where: 'product_id = ?',
      whereArgs: [id],
    );
    expect(specs.single['weight_class'], '4U');
  });

  test('thêm giày không tạo dòng racket_specs', () async {
    final id = await repository.addProduct(
      _product(categoryId: shoesId),
      null,
    );

    expect(await _countRows(db, DbSchema.products, 'id', id), 1);
    expect(await _countRows(db, DbSchema.racketSpecs, 'product_id', id), 0);
  });

  test('sửa vợt sang danh mục khác thì xóa racket_specs', () async {
    final id = await repository.addProduct(
      _product(categoryId: racketsId),
      _spec(),
    );

    await repository.updateProduct(
      _product(id: id, categoryId: shoesId, name: 'Giày test'),
      null,
    );

    final rows = await db.query(
      DbSchema.products,
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(rows.single['category_id'], shoesId);
    expect(rows.single['name'], 'Giày test');
    expect(await _countRows(db, DbSchema.racketSpecs, 'product_id', id), 0);
  });

  test('spec vi phạm CHECK thì rollback, products không được ghi', () async {
    final before = await _countAll(db, DbSchema.products);

    await expectLater(
      repository.addProduct(
        _product(categoryId: racketsId),
        _spec(weightClass: '9U'),
      ),
      throwsA(isA<AppException>()),
    );

    expect(await _countAll(db, DbSchema.products), before);
  });

  test('xóa sản phẩm chưa có trong đơn thì mất hẳn (kể cả spec)', () async {
    final id = await repository.addProduct(
      _product(categoryId: racketsId),
      _spec(),
    );

    final outcome = await repository.deleteProduct(id);

    expect(outcome, ProductDeleteOutcome.deleted);
    expect(await _countRows(db, DbSchema.products, 'id', id), 0);
    expect(await _countRows(db, DbSchema.racketSpecs, 'product_id', id), 0);
  });

  test('xóa sản phẩm đã có trong đơn thì ngừng bán, restore bán lại', () async {
    final orderItems = await db.query(
      DbSchema.orderItems,
      columns: ['product_id'],
      where: 'product_id IS NOT NULL',
      limit: 1,
    );
    final id = orderItems.single['product_id'] as int;
    expect(await repository.countOrdersOfProduct(id), greaterThan(0));

    final outcome = await repository.deleteProduct(id);

    expect(outcome, ProductDeleteOutcome.deactivated);
    expect(await _isActive(db, id), 0);

    await repository.restoreProduct(id);

    expect(await _isActive(db, id), 1);
  });
}

Product _product({
  int id = 0,
  required int categoryId,
  String name = 'Sản phẩm test',
}) {
  return Product(
    id: id,
    categoryId: categoryId,
    name: name,
    brand: 'Yonex',
    price: 1500000,
    stock: 10,
    rating: 0,
    ratingCount: 0,
    description: '',
    imagePath: 'rackets/test.png',
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

Future<int> _categoryIdByName(Database db, String name) async {
  final rows = await db.query(
    DbSchema.categories,
    columns: ['id'],
    where: 'name = ?',
    whereArgs: [name],
  );
  return rows.single['id'] as int;
}

Future<int> _countAll(Database db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
  return rows.single['count'] as int;
}

Future<int> _countRows(
  Database db,
  String table,
  String column,
  int value,
) async {
  final rows = await db.rawQuery(
    'SELECT COUNT(*) AS count FROM $table WHERE $column = ?',
    [value],
  );
  return rows.single['count'] as int;
}

Future<int> _isActive(Database db, int id) async {
  final rows = await db.query(
    DbSchema.products,
    columns: ['is_active'],
    where: 'id = ?',
    whereArgs: [id],
  );
  return rows.single['is_active'] as int;
}
