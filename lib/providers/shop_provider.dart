import 'dart:async';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/models/product_query.dart';
import '../data/repositories/product_repository.dart';
import 'base_provider.dart';

class ShopProvider extends BaseProvider {
  ShopProvider(this._repository);

  final ProductRepository _repository;

  // Điều kiện tìm kiếm hiện tại.
  ProductQuery _query = const ProductQuery();

  // Trạng thái giao diện.
  ViewStatus _status = ViewStatus.initial;

  // Dữ liệu hiển thị.
  List<Product> _products = [];
  List<Category> _categories = [];

  String? _errorMessage;

  // Timer phục vụ debounce.
  Timer? _debounceTimer;

  // Tăng mỗi lần tải mới; kết quả mang số cũ thì bỏ qua.
  int _loadId = 0;

  // ===== GETTERS =====

  ProductQuery get query => _query;

  ViewStatus get status => _status;

  List<Product> get products => List.unmodifiable(_products);

  List<Category> get categories => List.unmodifiable(_categories);

  String? get errorMessage => _errorMessage;

  int get resultCount => _products.length;

  // ===== KHỞI TẠO =====

  Future<void> loadInitial() async {
    // Tải danh mục và danh sách sản phẩm.
    _status = ViewStatus.loading;
    notify();

    try {
      _categories = await _repository.getCategories();
    } on AppException catch (e) {
      if (isDisposed) return;

      _status = ViewStatus.error;
      _errorMessage = e.message;
      notify();
      return;
    } catch (_) {
      if (isDisposed) return;

      _status = ViewStatus.error;
      _errorMessage = 'Không thể tải danh mục sản phẩm.';
      notify();
      return;
    }

    await loadProducts();
  }

  // ===== TÌM KIẾM =====

  void setKeyword(String value) {
    _query = _query.copyWith(keyword: value);

    // Hủy timer chưa chạy.
    _debounceTimer?.cancel();

    _loadId++;

    // Bắt đầu chờ 300ms.
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadProducts();
    });
  }

  // ===== DANH MỤC =====

  Future<void> selectCategory(int? categoryId) async {
    _debounceTimer?.cancel();

    _query = _query.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
    );

    await loadProducts();
  }

  // ===== SẮP XẾP =====

  Future<void> changeSort(ProductSort sort) async {
    _debounceTimer?.cancel();

    _query = _query.copyWith(sort: sort);

    await loadProducts();
  }

  // ===== RESET =====

  Future<void> resetFilters() async {
    _debounceTimer?.cancel();

    _query = const ProductQuery();

    await loadProducts();
  }

  // ===== LOAD DATA =====

  Future<void> loadProducts() async {
    if (isDisposed) return;

    final loadId = ++_loadId;

    // Chụp lại query cho lần tìm kiếm này.
    final currentQuery = _query;

    _status = ViewStatus.loading;
    _errorMessage = null;
    notify();

    try {
      final result = await _repository.searchProducts(currentQuery);

      if (isDisposed || loadId != _loadId) {
        return;
      }

      _products = result;

      _status = result.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on AppException catch (e) {
      if (isDisposed || loadId != _loadId) {
        return;
      }

      _status = ViewStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      if (isDisposed || loadId != _loadId) {
        return;
      }

      _status = ViewStatus.error;
      _errorMessage = 'Không thể tải sản phẩm.';
    }

    notify();
  }

  Future<void> refresh() {
    _debounceTimer?.cancel();
    return loadProducts();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
