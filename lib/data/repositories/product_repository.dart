import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_exception.dart';
import '../daos/product_dao.dart';
import '../models/category.dart';
import '../models/product.dart';

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
}
