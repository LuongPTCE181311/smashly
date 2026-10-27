import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/product.dart';
import '../data/repositories/wishlist_repository.dart';

class WishlistProvider extends ChangeNotifier {
  WishlistProvider(this._repository);

  final WishlistRepository _repository;

  int? _userId;
  int _revision = 0;

  Set<int> _favoriteIds = {};
  List<Product> _products = [];

  ViewStatus _status = ViewStatus.initial;
  String? _errorMessage;

  final Set<int> _pendingIds = {};

  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;

  List<Product> get products => List.unmodifiable(_products);

  int get count => _favoriteIds.length;

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  bool isPending(int productId) => _pendingIds.contains(productId);

  // Gọi khi user đăng nhập, đăng xuất hoặc đổi tài khoản.
  void updateUser(int? userId) {
    if (_userId == userId) return;

    _userId = userId;
    _revision++;

    _favoriteIds = {};
    _products = [];
    _pendingIds.clear();
    _errorMessage = null;
    _status = ViewStatus.initial;

    notifyListeners();

    if (userId != null) {
      load();
    }
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;

    final revision = _revision;

    _status = ViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final ids = await _repository.getProductIds(userId);
      final products = await _repository.getProducts(userId);

      if (_revision != revision) return;

      _favoriteIds = ids;
      _products = products;

      _status = ids.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } catch (error) {
      if (_revision != revision) return;

      _status = ViewStatus.error;
      _errorMessage = _message(error);
    }

    notifyListeners();
  }

  Future<bool> toggleFavorite(int productId) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Vui lòng đăng nhập để yêu thích.';
      notifyListeners();
      return false;
    }

    // Không cho cùng một sản phẩm gửi 2 thao tác đồng thời.
    if (_pendingIds.contains(productId)) return false;

    // Khi đang tải danh sách, không cho ghi theo state cũ.
    if (_status == ViewStatus.initial ||
        _status == ViewStatus.loading ||
        _status == ViewStatus.error) {
      return false;
    }

    final revision = _revision;
    final shouldFavorite = !_favoriteIds.contains(productId);

    _pendingIds.add(productId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.setFavorite(
        userId: userId,
        productId: productId,
        favorite: shouldFavorite,
      );

      if (_revision != revision) return false;

      // Đọc lại SQLite để dữ liệu luôn nhất quán.
      _favoriteIds = await _repository.getProductIds(userId);

      final products = await _repository.getProducts(userId);

      if (_revision != revision) return false;

      _products = products;
      _status = _favoriteIds.isEmpty ? ViewStatus.empty : ViewStatus.success;

      return true;
    } catch (error) {
      if (_revision == revision) {
        _errorMessage = _message(error);
      }
      return false;
    } finally {
      // Không để tác vụ cũ làm thay đổi state của user mới.
      if (_revision == revision) {
        _pendingIds.remove(productId);
        notifyListeners();
      }
    }
  }

  String _message(Object error) {
    if (error is AppException) return error.message;
    debugPrint('WishlistProvider: $error');
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }
}
