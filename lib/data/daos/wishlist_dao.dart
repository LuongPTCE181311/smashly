import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../models/product.dart';

class WishlistDao {
  const WishlistDao();

  // Lấy danh sách ID sản phẩm đã yêu thích.
  Future<Set<int>> getProductIds(DatabaseExecutor db, int userId) async {
    final rows = await db.query(
      DbSchema.wishlists,
      columns: ['product_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return rows.map((row) => row['product_id'] as int).toSet();
  }

  // Lấy danh sách sản phẩm để hiển thị Profile.
  Future<List<Product>> getProducts(DatabaseExecutor db, int userId) async {
    final rows = await db.rawQuery(
      '''
      SELECT p.*
      FROM ${DbSchema.wishlists} AS w
      INNER JOIN ${DbSchema.products} AS p
        ON p.id = w.product_id
      WHERE w.user_id = ?
        AND p.is_active = 1
      ORDER BY w.created_at DESC, p.id DESC
    ''',
      [userId],
    );

    return rows.map(Product.fromMap).toList();
  }

  // Thêm vào yêu thích.
  Future<void> add(DatabaseExecutor db, int userId, int productId) async {
    await db.insert(DbSchema.wishlists, {
      'user_id': userId,
      'product_id': productId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Bỏ yêu thích.
  Future<void> remove(DatabaseExecutor db, int userId, int productId) async {
    await db.delete(
      DbSchema.wishlists,
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
  }
}
