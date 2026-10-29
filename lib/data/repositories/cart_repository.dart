import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_exception.dart';
import '../daos/cart_dao.dart';
import '../models/cart_item.dart';

class CartRepository {
  static const maxQuantityPerLine = 99;

  /// Error for [size] against the sellable [sizes]; null = valid.
  /// Shared by add-to-cart and checkout (a size may be removed after the item
  /// is already in the cart).
  static String? sizeProblem(List<String> sizes, String size) {
    if (sizes.isEmpty) {
      return size.isEmpty ? null : 'Sản phẩm này không có size';
    }
    if (size.isEmpty) return 'Vui lòng chọn size';
    if (!sizes.contains(size)) return 'Size $size không còn bán';
    return null;
  }

  const CartRepository({required this._database, required this._cartDao});

  final Future<Database> Function() _database;
  final CartDao _cartDao;

  Future<List<CartItem>> loadItems(int userId) {
    return _guard('loadItems', 'Không thể tải giỏ hàng', () async {
      final db = await _database();
      final cartId = await _cartDao.getOrCreateCartId(db, userId);
      return _cartDao.findItems(db, cartId);
    });
  }

  /// Adds to the cart; same product + size accumulates, never above stock.
  /// A product with sizes requires one of its sellable sizes; a product without
  /// size passes `size: ''`. The same product in another size is a separate line.
  Future<void> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
    String size = '',
  }) async {
    if (quantity < 1) throw const AppException('Số lượng phải từ 1 trở lên');
    return _guard('addToCart', 'Không thể thêm vào giỏ hàng', () async {
      final db = await _database();
      await db.transaction((txn) async {
        final stock = await _requireStock(txn, productId);
        final sizeError = sizeProblem(
          await _cartDao.findSizes(txn, productId),
          size,
        );
        if (sizeError != null) throw AppException(sizeError);
        final cartId = await _cartDao.getOrCreateCartId(txn, userId);
        final line = await _cartDao.findLine(txn, cartId, productId, size);
        final total = (line?.quantity ?? 0) + quantity;
        _checkStock(stock, total);

        if (line == null) {
          await _cartDao.insertLine(
            txn,
            cartId: cartId,
            productId: productId,
            quantity: quantity,
            size: size,
          );
        } else {
          await _cartDao.updateQuantity(txn, line.id, total);
        }
      });
    });
  }

  Future<void> setQuantity(CartItem item, int quantity) async {
    if (quantity < 1) throw const AppException('Số lượng phải từ 1 trở lên');
    return _guard('setQuantity', 'Không thể đổi số lượng', () async {
      final db = await _database();
      await db.transaction((txn) async {
        _checkStock(await _requireStock(txn, item.productId), quantity);
        await _cartDao.updateQuantity(txn, item.id, quantity);
      });
    });
  }

  Future<void> setSelected(CartItem item, bool selected) {
    return _guard('setSelected', 'Không thể cập nhật lựa chọn', () async {
      await _cartDao.setSelected(await _database(), item.id, selected);
    });
  }

  Future<void> setAllSelected(int userId, bool selected) {
    return _guard('setAllSelected', 'Không thể cập nhật lựa chọn', () async {
      final db = await _database();
      final cartId = await _cartDao.getOrCreateCartId(db, userId);
      await _cartDao.setAllSelected(db, cartId, selected);
    });
  }

  /// Removes one or many cart lines at once (a single DELETE, all or nothing).
  Future<void> removeMany(List<CartItem> items) {
    return _guard('removeMany', 'Không thể xóa sản phẩm', () async {
      await _cartDao.deleteLines(await _database(), [
        for (final item in items) item.id,
      ]);
    });
  }

  /// Undo for a removal: re-inserts every line with its quantity, size and
  /// selection in one transaction (restores everything or inserts nothing).
  Future<void> restoreMany(int userId, List<CartItem> items) {
    return _guard('restoreMany', 'Không thể hoàn tác', () async {
      final db = await _database();
      await db.transaction((txn) async {
        final cartId = await _cartDao.getOrCreateCartId(txn, userId);
        for (final item in items) {
          await _cartDao.insertLine(
            txn,
            cartId: cartId,
            productId: item.productId,
            quantity: item.quantity,
            size: item.size,
            isSelected: item.isSelected,
          );
        }
      });
    });
  }

  Future<int> _requireStock(DatabaseExecutor db, int productId) async {
    final stock = await _cartDao.findStock(db, productId);
    if (stock == null) {
      throw const AppException('Sản phẩm này không còn được bán');
    }
    return stock;
  }

  void _checkStock(int stock, int wanted) {
    if (stock <= 0) throw const AppException('Sản phẩm đã hết hàng');
    if (wanted > stock) {
      throw AppException('Chỉ còn $stock sản phẩm trong kho');
    }
    if (wanted > maxQuantityPerLine) {
      throw const AppException('Tối đa $maxQuantityPerLine sản phẩm mỗi dòng');
    }
  }

  Future<T> _guard<T>(
    String action,
    String fallback,
    Future<T> Function() body,
  ) async {
    try {
      return await body();
    } on DatabaseException catch (error) {
      debugPrint('CartRepository.$action: $error');
      throw AppException(fallback);
    }
  }
}
