import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/app_exception.dart';
import '../daos/product_dao.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/racket_spec.dart';

class ProductRepository {
  const ProductRepository({
    required Future<Database> Function() database,
    required ProductDao productDao,
  }) : _database = database,
       _productDao = productDao;

  final Future<Database> Function() _database;
  final ProductDao _productDao;

  Future<List<Category>> getCategories() async {
    try {
      final db = await _database();
      return await _productDao.getCategories(db);
    } catch (_) {
      throw const AppException('Không thể tải danh mục sản phẩm.');
    }
  }

  Future<Product?> getHeroProduct() async {
    try {
      final db = await _database();
      return await _productDao.getHeroProduct(db);
    } catch (_) {
      throw const AppException('Không thể tải sản phẩm nổi bật.');
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final db = await _database();

      return await _productDao.getFeaturedProducts(db, limit: 6);
    } catch (_) {
      throw const AppException('Không thể tải sản phẩm nổi bật.');
    }
  }

  Future<List<Product>> getTrendingProducts() async {
    try {
      final db = await _database();

      return await _productDao.getTrendingProducts(db, limit: 6);
    } catch (_) {
      throw const AppException('Không thể tải sản phẩm thịnh hành.');
    }
  }

  Future<List<String>> getTopBrands() async {
    try {
      final db = await _database();

      return await _productDao.getTopBrands(db, limit: 6);
    } catch (_) {
      throw const AppException('Không thể tải thương hiệu.');
    }
  }

  // ===== WRITE (Trọng) =====

  /// Thêm sản phẩm mới (bỏ qua [Product.id]). Có [spec] thì ghi thông số vợt
  /// cùng transaction. Trả về id mới.
  Future<int> addProduct(Product product, RacketSpec? spec) async {
    try {
      final db = await _database();
      return await db.transaction((txn) async {
        final productId = await _productDao.insertProduct(txn, product);
        if (spec != null) {
          await _productDao.upsertRacketSpec(
            txn,
            _specForProduct(spec, productId),
          );
        }
        return productId;
      });
    } on DatabaseException catch (error) {
      debugPrint('ProductRepository.addProduct: $error');
      throw const AppException(
        'Không thể thêm sản phẩm. Vui lòng kiểm tra lại thông tin.',
      );
    }
  }

  /// Cập nhật sản phẩm theo [Product.id]. Có [spec] thì ghi đè thông số vợt,
  /// không có thì xóa thông số vợt cũ (nếu có).
  Future<void> updateProduct(Product product, RacketSpec? spec) async {
    try {
      final db = await _database();
      await db.transaction((txn) async {
        final updated = await _productDao.updateProduct(txn, product);
        if (updated == 0) {
          throw const AppException('Không tìm thấy sản phẩm cần sửa.');
        }
        if (spec != null) {
          await _productDao.upsertRacketSpec(
            txn,
            _specForProduct(spec, product.id),
          );
        } else {
          await _productDao.deleteRacketSpec(txn, product.id);
        }
      });
    } on DatabaseException catch (error) {
      debugPrint('ProductRepository.updateProduct: $error');
      throw const AppException(
        'Không thể lưu sản phẩm. Vui lòng kiểm tra lại thông tin.',
      );
    }
  }

  /// Số đơn hàng (không trùng) có chứa sản phẩm, để hiện trong dialog xác nhận.
  Future<int> countOrdersOfProduct(int productId) async {
    try {
      final db = await _database();
      return await _productDao.countOrdersOfProduct(db, productId);
    } on DatabaseException catch (error) {
      debugPrint('ProductRepository.countOrdersOfProduct: $error');
      throw const AppException('Không thể kiểm tra đơn hàng của sản phẩm.');
    }
  }

  /// Chưa nằm trong đơn nào thì xóa thật, ngược lại chỉ ngừng bán để giữ
  /// lịch sử đơn hàng.
  Future<ProductDeleteOutcome> deleteProduct(int productId) async {
    try {
      final db = await _database();
      return await db.transaction((txn) async {
        final orderItemCount = await _productDao.countOrderItems(
          txn,
          productId,
        );
        final affected = orderItemCount == 0
            ? await _productDao.deleteProduct(txn, productId)
            : await _productDao.setActive(txn, productId, false);
        if (affected == 0) {
          throw const AppException('Không tìm thấy sản phẩm cần xóa.');
        }
        return orderItemCount == 0
            ? ProductDeleteOutcome.deleted
            : ProductDeleteOutcome.deactivated;
      });
    } on DatabaseException catch (error) {
      debugPrint('ProductRepository.deleteProduct: $error');
      throw const AppException('Không thể xóa sản phẩm lúc này.');
    }
  }

  /// Bán lại sản phẩm đã ngừng bán (nút Undo).
  Future<void> restoreProduct(int productId) async {
    try {
      final db = await _database();
      final updated = await _productDao.setActive(db, productId, true);
      if (updated == 0) {
        throw const AppException('Không tìm thấy sản phẩm cần khôi phục.');
      }
    } on DatabaseException catch (error) {
      debugPrint('ProductRepository.restoreProduct: $error');
      throw const AppException('Không thể khôi phục sản phẩm lúc này.');
    }
  }

  RacketSpec _specForProduct(RacketSpec spec, int productId) {
    return RacketSpec(
      productId: productId,
      weightClass: spec.weightClass,
      balance: spec.balance,
      shaft: spec.shaft,
      maxTensionLbs: spec.maxTensionLbs,
      playerLevel: spec.playerLevel,
      playStyle: spec.playStyle,
    );
  }
}
