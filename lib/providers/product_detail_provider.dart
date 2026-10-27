import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/product.dart';
import '../data/models/product_detail.dart';
import '../data/models/racket_spec.dart';
import '../data/repositories/product_repository.dart';
import 'cart_provider.dart';

class ProductDetailProvider extends ChangeNotifier {
  ProductDetailProvider(this._repository, this.productId);

  final ProductRepository _repository;
  final int? productId;

  ViewStatus _status = ViewStatus.initial;
  ProductDetail? _detail;
  String? _errorMessage;
  int _quantity = 1;
  String? _selectedSize;
  bool _isAdding = false;
  bool _disposed = false;

  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  ProductDetail? get detail => _detail;
  Product? get product => _detail?.product;
  RacketSpec? get racketSpec => _detail?.racketSpec;
  List<String> get sizes => _detail?.sizes ?? const [];
  int get quantity => _quantity;
  String? get selectedSize => _selectedSize;
  bool get isAdding => _isAdding;

  int get stock => product?.stock ?? 0;
  bool get isOutOfStock => stock <= 0;
  bool get needsSize => sizes.isNotEmpty;
  bool get isSizeMissing => needsSize && _selectedSize == null;
  bool get canDecrease => _quantity > 1;
  bool get canIncrease => _quantity < stock;

  bool get canAddToCart =>
      _status == ViewStatus.success &&
      !isOutOfStock &&
      !isSizeMissing &&
      !_isAdding;

  Future<void> load() async {
    final id = productId;
    if (id == null) {
      _status = ViewStatus.empty;
      _notify();
      return;
    }

    _status = ViewStatus.loading;
    _errorMessage = null;
    _notify();

    try {
      final detail = await _repository.getProductDetail(id);
      _detail = detail;
      _quantity = 1;
      _selectedSize = null;
      _status = detail == null || !detail.isAvailable
          ? ViewStatus.empty
          : ViewStatus.success;
    } catch (error) {
      _status = ViewStatus.error;
      _errorMessage = error is AppException && error.message.isNotEmpty
          ? error.message
          : 'Không thể tải thông tin sản phẩm. Vui lòng thử lại.';
    }

    _notify();
  }

  void increase() {
    if (!canIncrease) return;
    _quantity++;
    _notify();
  }

  void decrease() {
    if (!canDecrease) return;
    _quantity--;
    _notify();
  }

  void selectSize(String size) {
    if (_selectedSize == size || !sizes.contains(size)) return;
    _selectedSize = size;
    _notify();
  }

  Future<String?> addToCart(CartProvider cart) async {
    final current = product;
    if (current == null || !canAddToCart) return null;

    _isAdding = true;
    _notify();

    final error = await cart.addToCart(
      productId: current.id,
      quantity: _quantity,
      size: _selectedSize ?? '',
    );

    _isAdding = false;
    if (error == null) _quantity = 1;
    _notify();
    return error;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
