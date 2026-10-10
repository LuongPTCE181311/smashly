import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../models/category.dart';
import '../models/product.dart';

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
}
