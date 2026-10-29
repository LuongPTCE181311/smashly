import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../../core/utils/db_time.dart';
import '../models/cart_item.dart';

/// Only SQL for carts + cart_items. Stock checks belong to CartRepository.
class CartDao {
  const CartDao();

  static const _selectItem =
      '''
      SELECT ci.id, ci.product_id, ci.quantity, ci.size, ci.is_selected,
             p.name, p.brand, p.image_path, p.price, p.stock
      FROM ${DbSchema.cartItems} ci
      JOIN ${DbSchema.products} p ON p.id = ci.product_id
  ''';

  /// Used by Hào on sign-up: exactly one cart per customer.
  Future<int> createForUser(DatabaseExecutor db, int userId) {
    return db.insert(DbSchema.carts, {'user_id': userId});
  }

  /// Always look up by `user_id`; never assume `cart_id = user_id`.
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

  /// Current stock of a product on sale; null if missing or discontinued.
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

  /// Sellable sizes of a product (products.sizes column, comma separated).
  /// Empty if the product has no size (rackets, accessories) or does not exist.
  Future<List<String>> findSizes(DatabaseExecutor db, int productId) async {
    final rows = await db.query(
      DbSchema.products,
      columns: ['sizes'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (rows.isEmpty) return [];
    return ((rows.first['sizes'] as String?) ?? '')
        .split(',')
        .map((size) => size.trim())
        .where((size) => size.isNotEmpty)
        .toList();
  }

  Future<List<CartItem>> findItems(DatabaseExecutor db, int cartId) async {
    final rows = await db.rawQuery(
      '$_selectItem WHERE ci.cart_id = ? ORDER BY ci.added_at DESC, ci.id DESC',
      [cartId],
    );
    return rows.map(CartItem.fromMap).toList();
  }

  /// Existing line for the same (product, size), used to accumulate quantity.
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

  /// Deletes several lines with one DELETE (atomic): a single line or every
  /// size of one product.
  Future<int> deleteLines(DatabaseExecutor db, List<int> itemIds) {
    if (itemIds.isEmpty) return Future.value(0);
    final marks = List.filled(itemIds.length, '?').join(', ');
    return db.delete(
      DbSchema.cartItems,
      where: 'id IN ($marks)',
      whereArgs: itemIds,
    );
  }

  /// Deletes the selected lines (called after a successful checkout).
  Future<int> deleteSelected(DatabaseExecutor db, int cartId) {
    return db.delete(
      DbSchema.cartItems,
      where: 'cart_id = ? AND is_selected = 1',
      whereArgs: [cartId],
    );
  }
}
