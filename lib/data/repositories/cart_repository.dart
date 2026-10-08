import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_exception.dart';
import '../daos/cart_dao.dart';
import '../models/cart_item.dart';

class CartRepository {
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

  /// Thêm vào giỏ; cùng sản phẩm + size thì cộng dồn, không vượt tồn kho.
  /// Món không có size truyền `size: ''`.
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

  Future<void> remove(CartItem item) {
    return _guard('remove', 'Không thể xóa sản phẩm', () async {
      await _cartDao.deleteLine(await _database(), item.id);
    });
  }

  /// Hoàn tác xóa: chèn lại đúng số lượng, size, trạng thái chọn.
  Future<void> restore(int userId, CartItem item) {
    return _guard('restore', 'Không thể hoàn tác', () async {
      final db = await _database();
      await db.transaction((txn) async {
        final cartId = await _cartDao.getOrCreateCartId(txn, userId);
        await _cartDao.insertLine(
          txn,
          cartId: cartId,
          productId: item.productId,
          quantity: item.quantity,
          size: item.size,
          isSelected: item.isSelected,
        );
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
