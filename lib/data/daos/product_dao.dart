import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../../core/utils/db_time.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/racket_spec.dart';

class ProductDao {
  const ProductDao();

  Future<List<Category>> getCategories(DatabaseExecutor db) async {
    final rows = await db.query(DbSchema.categories, orderBy: 'sort_order ASC');

    return rows.map(Category.fromMap).toList();
  }

  Future<List<Product>> getFeaturedProducts(
    DatabaseExecutor db, {
    int limit = 6,
  }) async {
    final rows = await db.query(
      DbSchema.products,
      where: 'is_active = ? AND is_featured = ?',
      whereArgs: [1, 1],
      orderBy: 'rating DESC, rating_count DESC',
      limit: limit,
    );

    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getHeroProduct(DatabaseExecutor db) async {
    final rows = await db.query(
      DbSchema.products,
      where: 'is_active = ? AND is_featured = ?',
      whereArgs: [1, 1],
      orderBy: 'rating DESC, rating_count DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Product.fromMap(rows.first);
  }

  Future<List<Product>> getTrendingProducts(
    DatabaseExecutor db, {
    int limit = 6,
  }) async {
    final rows = await db.query(
      DbSchema.products,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'rating_count DESC, rating DESC',
      limit: limit,
    );

    return rows.map(Product.fromMap).toList();
  }

  Future<List<String>> getTopBrands(
    DatabaseExecutor db, {
    int limit = 6,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        brand,
        COUNT(*) AS product_count,
        AVG(rating) AS avg_rating
      FROM ${DbSchema.products}
      WHERE is_active = 1
      GROUP BY brand
      ORDER BY product_count DESC, avg_rating DESC
      LIMIT ?
    ''',
      [limit],
    );

    return rows.map((row) => row['brand'] as String).toList();
  }

  Future<Product?> findById(DatabaseExecutor db, int productId) async {
    final rows = await db.query(
      DbSchema.products,
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Product.fromMap(rows.first);
  }

  // ===== WRITE (Trọng) =====

  /// Các cột admin được ghi; không gồm `id`, `created_at`, `updated_at`.
  Map<String, Object?> _productValues(Product product) {
    return {
      'category_id': product.categoryId,
      'name': product.name,
      'brand': product.brand,
      'price': product.price,
      'original_price': product.originalPrice,
      'stock': product.stock,
      'rating': product.rating,
      'rating_count': product.ratingCount,
      'description': product.description,
      'image_path': product.imagePath,
      'sizes': product.sizes,
      'is_featured': product.isFeatured ? 1 : 0,
      'is_active': product.isActive ? 1 : 0,
    };
  }

  /// Bỏ qua [Product.id]; SQLite tự cấp id mới và trả về.
  Future<int> insertProduct(DatabaseExecutor db, Product product) {
    return db.insert(DbSchema.products, _productValues(product));
  }

  /// Trả về số dòng bị ảnh hưởng (0 nếu không có sản phẩm với id này).
  Future<int> updateProduct(DatabaseExecutor db, Product product) {
    return db.update(
      DbSchema.products,
      {..._productValues(product), 'updated_at': dbTime(DateTime.now())},
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> upsertRacketSpec(DatabaseExecutor db, RacketSpec spec) {
    return db.insert(DbSchema.racketSpecs, {
      'product_id': spec.productId,
      'weight_class': spec.weightClass,
      'balance': spec.balance,
      'shaft': spec.shaft,
      'max_tension_lbs': spec.maxTensionLbs,
      'player_level': spec.playerLevel,
      'play_style': spec.playStyle,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteRacketSpec(DatabaseExecutor db, int productId) {
    return db.delete(
      DbSchema.racketSpecs,
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> countOrderItems(DatabaseExecutor db, int productId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DbSchema.orderItems} '
      'WHERE product_id = ?',
      [productId],
    );
    return rows.first['count'] as int;
  }

  Future<int> countOrdersOfProduct(DatabaseExecutor db, int productId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT order_id) AS count FROM ${DbSchema.orderItems} '
      'WHERE product_id = ?',
      [productId],
    );
    return rows.first['count'] as int;
  }

  /// Xóa thật; racket_specs, cart_items, wishlists tự xóa theo ON DELETE CASCADE.
  Future<int> deleteProduct(DatabaseExecutor db, int productId) {
    return db.delete(
      DbSchema.products,
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<int> setActive(DatabaseExecutor db, int productId, bool isActive) {
    return db.update(
      DbSchema.products,
      {'is_active': isActive ? 1 : 0, 'updated_at': dbTime(DateTime.now())},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
}
