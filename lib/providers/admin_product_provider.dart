import 'dart:async';

import '../core/constants/app_rules.dart';
import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/admin_product_query.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';
import 'base_provider.dart';

/// State của màn Admin Products (S14 · UC17): tải, tìm, lọc, xóa sản phẩm.
class AdminProductProvider extends BaseProvider {
  AdminProductProvider(this._repository);

  final ProductRepository _repository;

  AdminProductQuery _query = const AdminProductQuery();
  ViewStatus _status = ViewStatus.initial;
  List<Product> _products = [];
  List<Category> _categories = [];
  String? _errorMessage;

  /// id sản phẩm đang xóa / khôi phục, để khóa nút trên hàng đó.
  final Set<int> _busyIds = {};

  Timer? _debounceTimer;

  // Tăng mỗi lần tải mới; kết quả mang số cũ thì bỏ qua.
  int _loadId = 0;

  // ===== GETTERS =====

  AdminProductQuery get query => _query;
  ViewStatus get status => _status;
  List<Product> get products => List.unmodifiable(_products);
  List<Category> get categories => List.unmodifiable(_categories);
  String? get errorMessage => _errorMessage;
  int get resultCount => _products.length;

  bool isBusy(int productId) => _busyIds.contains(productId);

  /// Tên danh mục theo id; chưa tải được danh mục thì trả chuỗi rỗng.
  String categoryNameOf(int categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    return '';
  }

  // ===== TẢI DỮ LIỆU =====

  Future<void> loadInitial() async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notify();

    try {
      _categories = await _repository.getCategories();
    } on AppException catch (e) {
      if (isDisposed) return;
      _status = ViewStatus.error;
      _errorMessage = e.message;
      notify();
      return;
    }

    await loadProducts();
  }

  /// Chạy lại truy vấn với [_query] hiện tại. [showLoading] = false khi tải lại
  /// sau xóa/khôi phục để danh sách không nháy sang spinner.
  Future<void> loadProducts({bool showLoading = true}) async {
    if (isDisposed) return;

    final loadId = ++_loadId;
    final currentQuery = _query;

    if (showLoading) {
      _status = ViewStatus.loading;
      _errorMessage = null;
      notify();
    }

    try {
      final result = await _repository.getAdminProducts(currentQuery);
      if (isDisposed || loadId != _loadId) return;

      _products = result;
      _status = result.isEmpty ? ViewStatus.empty : ViewStatus.success;
      _errorMessage = null;
    } on AppException catch (e) {
      if (isDisposed || loadId != _loadId) return;

      _status = ViewStatus.error;
      _errorMessage = e.message;
    }

    notify();
  }

  /// Nút "Thử lại" ở trạng thái lỗi: chưa có danh mục thì tải lại từ đầu.
  Future<void> retry() {
    _debounceTimer?.cancel();
    return _categories.isEmpty ? loadInitial() : loadProducts();
  }

  Future<void> refresh() {
    _debounceTimer?.cancel();
    return loadProducts(showLoading: false);
  }

  // ===== TÌM KIẾM & LỌC =====

  /// Gõ vào ô search: chờ 300ms sau lần gõ cuối mới truy vấn.
  void setKeyword(String value) {
    _query = _query.copyWith(keyword: value);
    _debounceTimer?.cancel();
    _loadId++;
    _debounceTimer = Timer(AppRules.searchDebounce, loadProducts);
  }

  Future<void> selectCategory(int? categoryId) {
    _debounceTimer?.cancel();
    _query = _query.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
    );
    return loadProducts();
  }

  /// Bật/tắt chip "Đang ẩn".
  Future<void> toggleHidden() {
    _debounceTimer?.cancel();
    _query = _query.copyWith(onlyHidden: !_query.onlyHidden);
    return loadProducts();
  }

  Future<void> resetFilters() {
    _debounceTimer?.cancel();
    _query = const AdminProductQuery();
    return loadProducts();
  }

  // ===== XÓA =====

  /// Số đơn hàng có chứa [product], dùng để viết hậu quả trong dialog xác nhận.
  /// Ném [AppException] nếu không đọc được.
  Future<int> countOrdersOf(Product product) {
    return _repository.countOrdersOfProduct(product.id);
  }

  /// Xóa thật hoặc ngừng bán (do Repository quyết định), rồi tải lại danh sách.
  /// Ném [AppException] nếu thất bại.
  Future<ProductDeleteOutcome> deleteProduct(Product product) async {
    _setBusy(product.id, true);
    try {
      final outcome = await _repository.deleteProduct(product.id);
      await loadProducts(showLoading: false);
      return outcome;
    } finally {
      _setBusy(product.id, false);
    }
  }

  /// Nút "Hoàn tác" sau khi ngừng bán: bán lại rồi tải lại danh sách.
  /// Ném [AppException] nếu thất bại.
  Future<void> restoreProduct(Product product) async {
    _setBusy(product.id, true);
    try {
      await _repository.restoreProduct(product.id);
      await loadProducts(showLoading: false);
    } finally {
      _setBusy(product.id, false);
    }
  }

  void _setBusy(int productId, bool busy) {
    if (isDisposed) return;
    busy ? _busyIds.add(productId) : _busyIds.remove(productId);
    notify();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
