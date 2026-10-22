import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_exception.dart';
import '../daos/product_dao.dart';
import '../daos/wishlist_dao.dart';
import '../models/product.dart';

class WishlistRepository {
  const WishlistRepository({
    required Future<Database> Function() database,
    required WishlistDao wishlistDao,
    required ProductDao productDao,
  }) : _database = database,
       _wishlistDao = wishlistDao,
       _productDao = productDao;

  final Future<Database> Function() _database;
  final WishlistDao _wishlistDao;
  final ProductDao _productDao;

  Future<Set<int>> getProductIds(int userId) async {
    try {
      final db = await _database();
      return await _wishlistDao.getProductIds(db, userId);
    } catch (error) {
      debugPrint('WishlistRepository.getProductIds: $error');
      throw const AppException('Không thể tải danh sách yêu thích.');
    }
  }

  Future<List<Product>> getProducts(int userId) async {
    try {
      final db = await _database();
      return await _wishlistDao.getProducts(db, userId);
    } catch (error) {
      debugPrint('WishlistRepository.getProducts: $error');
      throw const AppException('Không thể tải sản phẩm yêu thích.');
    }
  }

  Future<void> setFavorite({
    required int userId,
    required int productId,
    required bool favorite,
  }) async {
    try {
      final db = await _database();

      if (favorite) {
        final product = await _productDao.findById(db, productId);

        if (product == null || !product.isActive) {
          throw const AppException('Sản phẩm không còn được bán.');
        }

        await _wishlistDao.add(db, userId, productId);
      } else {
        await _wishlistDao.remove(db, userId, productId);
      }
    } on AppException {
      rethrow;
    } catch (error) {
      debugPrint('WishlistRepository.setFavorite: $error');
      throw const AppException(
        'Không thể cập nhật yêu thích. Vui lòng thử lại.',
      );
    }
  }
}
