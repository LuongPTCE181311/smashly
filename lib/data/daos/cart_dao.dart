import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../../core/utils/db_time.dart';
import '../models/cart_item.dart';

/// Chỉ viết SQL cho carts + cart_items. Kiểm tra tồn kho thuộc CartRepository.
class CartDao {
  const CartDao();

  static const _selectItem =
      '''
      SELECT ci.id, ci.product_id, ci.quantity, ci.size, ci.is_selected,
             p.name, p.image_path, p.price, p.stock
      FROM ${DbSchema.cartItems} ci
      JOIN ${DbSchema.products} p ON p.id = ci.product_id
  ''';

  /// Hào gọi khi đăng ký: mỗi khách đúng một giỏ.
  Future<int> createForUser(DatabaseExecutor db, int userId) {
    return db.insert(DbSchema.carts, {'user_id': userId});
  }

  /// Luôn tra theo `user_id`, không coi `cart_id = user_id`.
  Future<int> getOrCreateCartId(DatabaseExecutor db, int userId) async {
    final rows = await db.query(
      DbSchema.carts,
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return createForUser(db, userId);
  }

  /// Tồn kho hiện tại của sản phẩm đang bán; null nếu không có / đã ngừng bán.
  Future<int?> findStock(DatabaseExecutor db, int productId) async {
    final rows = await db.query(
      DbSchema.products,
      columns: ['stock'],
      where: 'id = ? AND is_active = 1',
      whereArgs: [productId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['stock'] as int;
  }

  Future<List<CartItem>> findItems(DatabaseExecutor db, int cartId) async {
    final rows = await db.rawQuery(
      '$_selectItem WHERE ci.cart_id = ? ORDER BY ci.added_at DESC, ci.id DESC',
      [cartId],
    );
    return rows.map(CartItem.fromMap).toList();
  }

  /// Dòng cùng (sản phẩm, size) nếu đã có trong giỏ, để cộng dồn số lượng.
  Future<CartItem?> findLine(
    DatabaseExecutor db,
    int cartId,
    int productId,
    String size,
  ) async {
    final rows = await db.rawQuery(
      '$_selectItem WHERE ci.cart_id = ? AND ci.product_id = ? AND ci.size = ? LIMIT 1',
      [cartId, productId, size],
    );
    return rows.isEmpty ? null : CartItem.fromMap(rows.first);
  }

  Future<int> insertLine(
    DatabaseExecutor db, {
    required int cartId,
    required int productId,
    required int quantity,
    required String size,
    bool isSelected = true,
  }) {
    return db.insert(DbSchema.cartItems, {
      'cart_id': cartId,
      'product_id': productId,
      'quantity': quantity,
      'size': size,
      'is_selected': isSelected ? 1 : 0,
      'added_at': dbTime(DateTime.now()),
    });
  }

  Future<int> updateQuantity(DatabaseExecutor db, int itemId, int quantity) {
    return db.update(
      DbSchema.cartItems,
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> setSelected(DatabaseExecutor db, int itemId, bool selected) {
    return db.update(
      DbSchema.cartItems,
      {'is_selected': selected ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> setAllSelected(DatabaseExecutor db, int cartId, bool selected) {
    return db.update(
      DbSchema.cartItems,
      {'is_selected': selected ? 1 : 0},
      where: 'cart_id = ?',
      whereArgs: [cartId],
    );
  }

  Future<int> deleteLine(DatabaseExecutor db, int itemId) {
    return db.delete(DbSchema.cartItems, where: 'id = ?', whereArgs: [itemId]);
  }

  /// Xóa các món đã chọn (gọi sau khi đặt hàng thành công).
  Future<int> deleteSelected(DatabaseExecutor db, int cartId) {
    return db.delete(
      DbSchema.cartItems,
      where: 'cart_id = ? AND is_selected = 1',
      whereArgs: [cartId],
    );
  }
}
