import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/cart_item.dart';
import '../data/repositories/cart_repository.dart';

/// Giỏ hàng của người đang đăng nhập. Sống suốt app nên PHẢI được báo khi đổi
/// người dùng: main.dart nối với AuthProvider bằng ChangeNotifierProxyProvider
/// và gọi [updateUser].
///
/// Các hàm thao tác trả về `String?`: `null` = thành công, ngược lại là câu
/// lỗi tiếng Việt để màn hình hiện SnackBar.
class CartProvider extends ChangeNotifier {
  CartProvider(this._repository);

  final CartRepository _repository;

  // Chưa có user = giỏ trống; có user thì chuyển initial -> loading ở updateUser.
  ViewStatus _status = ViewStatus.empty;
  int? _userId;
  List<CartItem> _items = [];
  String? _errorMessage;

  /// Tăng mỗi khi đổi user để bỏ kết quả của lần tải cũ về muộn.
  int _generation = 0;
  bool _disposed = false;

  CartItem? _lastRemoved;

  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<CartItem> get items => UnmodifiableListView(_items);
  bool get canUndoRemove => _lastRemoved != null;

  Iterable<CartItem> get selectedItems => _items.where((i) => i.isSelected);
  int get selectedCount => selectedItems.length;
  int get selectedTotal => selectedItems.fold(0, (sum, i) => sum + i.lineTotal);
  bool get allSelected =>
      _items.isNotEmpty && _items.every((i) => i.isSelected);

  /// Số trên badge tab Giỏ hàng: số mặt hàng (dòng) trong giỏ, không cộng số
  /// lượng. Cùng sản phẩm khác size tính là 2 dòng.
  int get itemCount => _items.length;

  /// Có món đang chọn mà vượt tồn kho / hết hàng -> không cho thanh toán.
  bool get hasUnavailableSelected =>
      selectedItems.any((i) => i.stock <= 0 || i.quantity > i.stock);

  /// Gọi khi người dùng đổi hoặc đăng xuất: bỏ giỏ cũ khỏi bộ nhớ rồi tải giỏ
  /// của người mới. Được gọi trong lúc build nên không notify đồng bộ.
  void updateUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _generation++;
    _items = [];
    _lastRemoved = null;
    _errorMessage = null;
    _status = userId == null ? ViewStatus.empty : ViewStatus.initial;
    Future.microtask(() {
      if (userId == null) {
        _notify();
      } else if (userId == _userId) {
        load();
      }
    });
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    final generation = _generation;
    _status = ViewStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      final items = await _repository.loadItems(userId);
      if (generation != _generation) return;
      _items = items;
      _status = items.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } catch (error) {
      if (generation != _generation) return;
      _status = ViewStatus.error;
      _errorMessage = _messageOf(error, 'Không thể tải giỏ hàng');
    }
    _notify();
  }

  /// Lượng gọi từ Product Detail. `size = ''` nếu sản phẩm không có size.
  Future<String?> addToCart({
    required int productId,
    int quantity = 1,
    String size = '',
  }) async {
    final userId = _userId;
    if (userId == null) return 'Bạn cần đăng nhập để thêm vào giỏ hàng';
    try {
      await _repository.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
        size: size,
      );
    } catch (error) {
      return _messageOf(error, 'Không thể thêm vào giỏ hàng');
    }
    await _reload(userId);
    return null;
  }

  /// [delta] = +1 / -1. Giảm khi đang là 1 thì không làm gì (xóa bằng vuốt).
  Future<String?> changeQuantity(CartItem item, int delta) async {
    final quantity = item.quantity + delta;
    if (quantity < 1) return null;
    try {
      await _repository.setQuantity(item, quantity);
    } catch (error) {
      return _messageOf(error, 'Không thể đổi số lượng');
    }
    _replace(item.id, (i) => i.copyWith(quantity: quantity));
    return null;
  }

  Future<String?> toggleSelected(CartItem item) async {
    final selected = !item.isSelected;
    try {
      await _repository.setSelected(item, selected);
    } catch (error) {
      return _messageOf(error, 'Không thể cập nhật lựa chọn');
    }
    _replace(item.id, (i) => i.copyWith(isSelected: selected));
    return null;
  }

  Future<String?> setAllSelected(bool selected) async {
    final userId = _userId;
    if (userId == null) return null;
    try {
      await _repository.setAllSelected(userId, selected);
    } catch (error) {
      return _messageOf(error, 'Không thể cập nhật lựa chọn');
    }
    _items = [for (final i in _items) i.copyWith(isSelected: selected)];
    _notify();
    return null;
  }

  /// Xóa ngay trên giao diện (để Dismissible gỡ được widget), lỗi DB thì hoàn
  /// lại. Thành công thì nhớ món vừa xóa cho [undoRemove].
  Future<String?> remove(CartItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index < 0) return null;
    _items = [..._items]..removeAt(index);
    _refreshStatus();
    _notify();
    try {
      await _repository.remove(item);
    } catch (error) {
      _items = [..._items]..insert(index.clamp(0, _items.length), item);
      _refreshStatus();
      _notify();
      return _messageOf(error, 'Không thể xóa sản phẩm');
    }
    _lastRemoved = item;
    return null;
  }

  Future<String?> undoRemove() async {
    final userId = _userId;
    final removed = _lastRemoved;
    if (userId == null || removed == null) return null;
    _lastRemoved = null;
    try {
      await _repository.restore(userId, removed);
    } catch (error) {
      return _messageOf(error, 'Không thể hoàn tác');
    }
    await _reload(userId);
    return null;
  }

  /// Tải lại mà không nháy màn loading (sau khi thêm / hoàn tác).
  Future<void> _reload(int userId) async {
    final generation = _generation;
    try {
      final items = await _repository.loadItems(userId);
      if (generation != _generation) return;
      _items = items;
      _refreshStatus();
    } catch (error) {
      if (generation != _generation) return;
      debugPrint('CartProvider._reload: $error');
    }
    _notify();
  }

  void _replace(int id, CartItem Function(CartItem) change) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) return;
    _items = [..._items]..[index] = change(_items[index]);
    _notify();
  }

  void _refreshStatus() {
    _status = _items.isEmpty ? ViewStatus.empty : ViewStatus.success;
  }

  /// Bắt cả Error (xem AuthProvider._handleError): lỗi lạ chỉ hiện câu chung.
  String _messageOf(Object error, String fallback) {
    if (error is AppException && error.message.isNotEmpty) {
      return error.message;
    }
    debugPrint('CartProvider: $error');
    return fallback;
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
