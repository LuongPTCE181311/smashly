import 'package:flutter/foundation.dart' hide Category;

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../data/models/racket_spec.dart';
import '../data/repositories/product_repository.dart';

/// State của màn Admin Product Form (S15 · UC18), dùng chung cho thêm và sửa.
///
/// [productId] null = thêm mới; có id = sửa sản phẩm đó.
class AdminProductFormProvider extends ChangeNotifier {
  AdminProductFormProvider(this._repository, {this.productId});

  final ProductRepository _repository;
  final int? productId;

  ViewStatus _status = ViewStatus.initial;
  List<Category> _categories = [];
  Product? _product;
  RacketSpec? _racketSpec;
  String? _errorMessage;
  bool _isSaving = false;
  bool _disposed = false;

  // ===== GETTERS =====

  bool get isEditing => productId != null;
  ViewStatus get status => _status;
  List<Category> get categories => List.unmodifiable(_categories);

  /// Sản phẩm đang sửa (null khi thêm mới).
  Product? get product => _product;

  /// Thông số vợt của sản phẩm đang sửa (null nếu không phải vợt).
  RacketSpec? get racketSpec => _racketSpec;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  /// Danh mục [categoryId] có phải "Rackets" không → quyết định hiện nhóm
  /// thông số vợt.
  bool isRacketCategory(int? categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) return category.name == 'Rackets';
    }
    return false;
  }

  // ===== TẢI DỮ LIỆU =====

  /// Tải danh mục (cho dropdown) và, nếu đang sửa, sản phẩm + thông số vợt.
  Future<void> load() async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.getCategories();

      if (isEditing) {
        final detail = await _repository.getProductDetail(productId!);
        if (detail == null) {
          throw const AppException(
            'Không tìm thấy sản phẩm cần sửa. Có thể sản phẩm đã bị xóa.',
          );
        }
        _product = detail.product;
        _racketSpec = detail.racketSpec;
      }

      if (_disposed) return;
      _status = ViewStatus.success;
    } catch (error) {
      if (_disposed) return;
      _status = ViewStatus.error;
      _errorMessage = error is AppException
          ? error.message
          : 'Không thể tải dữ liệu sản phẩm. Vui lòng thử lại.';
    }
    notifyListeners();
  }

  // ===== LƯU =====

  /// Thêm mới hoặc cập nhật (tùy [isEditing]). Repository ghi `products` và
  /// `racket_specs` trong một transaction. [spec] null = không phải vợt.
  ///
  /// Trả `true` khi đã lưu; `false` khi bỏ qua vì lần lưu trước chưa xong.
  /// Ném [AppException] nếu thất bại; màn hình bắt và hiện SnackBar.
  Future<bool> save(Product product, RacketSpec? spec) async {
    // Chặn bấm "Lưu" 2 lần khi lần trước chưa xong.
    if (_isSaving) return false;
    _isSaving = true;
    notifyListeners();

    try {
      if (isEditing) {
        await _repository.updateProduct(product, spec);
      } else {
        await _repository.addProduct(product, spec);
      }
      return true;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
