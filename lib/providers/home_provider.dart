import 'package:flutter/foundation.dart' hide Category;

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

class HomeProvider extends ChangeNotifier {
  HomeProvider(this._repository);

  final ProductRepository _repository;

  ViewStatus _status = ViewStatus.initial;

  Product? _heroProduct;

  List<Category> _categories = [];
  List<Product> _featuredProducts = [];
  List<Product> _trendingProducts = [];
  List<String> _brands = [];

  String? _errorMessage;

  ViewStatus get status => _status;

  Product? get heroProduct => _heroProduct;

  List<Category> get categories => _categories;

  List<Product> get featuredProducts => _featuredProducts;

  List<Product> get trendingProducts => _trendingProducts;

  List<String> get brands => _brands;

  String? get errorMessage => _errorMessage;

  Future<void> loadHome({bool force = false}) async {
    if (!force &&
        (_status == ViewStatus.loading || _status == ViewStatus.success)) {
      return;
    }

    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _heroProduct = await _repository.getHeroProduct();

      _categories = await _repository.getCategories();

      _featuredProducts = await _repository.getFeaturedProducts();

      _brands = await _repository.getTopBrands();

      _trendingProducts = await _repository.getTrendingProducts();

      final hasData =
          _heroProduct != null ||
          _categories.isNotEmpty ||
          _featuredProducts.isNotEmpty ||
          _trendingProducts.isNotEmpty;

      _status = hasData ? ViewStatus.success : ViewStatus.empty;
    } on AppException catch (e) {
      _status = ViewStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      _status = ViewStatus.error;
      _errorMessage = 'Không thể tải trang chủ. Vui lòng thử lại.';
    }

    notifyListeners();
  }

  Future<void> refresh() {
    return loadHome(force: true);
  }
}
