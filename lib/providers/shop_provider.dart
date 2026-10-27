import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/models/product_query.dart';
import '../data/repositories/product_repository.dart';

class ShopProvider extends ChangeNotifier {
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

  // Số thứ tự truy vấn, tránh kết quả cũ ghi đè.
  int _requestId = 0;

  bool _disposed = false;

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
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
    } on AppException catch (e) {
      if (_disposed) return;

      _status = ViewStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return;
    } catch (_) {
      if (_disposed) return;

      _status = ViewStatus.error;
      _errorMessage = 'Không thể tải danh mục sản phẩm.';
      notifyListeners();
      return;
    }

    await loadProducts();
  }

  // ===== TÌM KIẾM =====

  void setKeyword(String value) {
    _query = _query.copyWith(keyword: value);

    // Hủy timer chưa chạy.
    _debounceTimer?.cancel();

    // Làm vô hiệu kết quả từ query trước.
    _requestId++;

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
    if (_disposed) return;

    // Mỗi lần query có một ID riêng.
    final requestId = ++_requestId;

    // Chụp lại query cho lần tìm kiếm này.
    final currentQuery = _query;

    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.searchProducts(currentQuery);

      // Bỏ qua nếu provider đã dispose
      // hoặc đã có request mới hơn.
      if (_disposed || requestId != _requestId) {
        return;
      }

      _products = result;

      _status = result.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } on AppException catch (e) {
      if (_disposed || requestId != _requestId) {
        return;
      }

      _status = ViewStatus.error;
      _errorMessage = e.message;
    } catch (_) {
      if (_disposed || requestId != _requestId) {
        return;
      }

      _status = ViewStatus.error;
      _errorMessage = 'Không thể tải sản phẩm.';
    }

    notifyListeners();
  }

  Future<void> refresh() {
    _debounceTimer?.cancel();
    return loadProducts();
  }

  @override
  void dispose() {
    _disposed = true;

    // Hủy timer để tránh gọi sau dispose.
    _debounceTimer?.cancel();

    // Vô hiệu các request chưa kết thúc.
    _requestId++;

    super.dispose();
  }
}
