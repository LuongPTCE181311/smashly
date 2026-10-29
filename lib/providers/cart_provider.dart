import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/cart_item.dart';
import '../data/repositories/cart_repository.dart';

/// Cart of the signed-in user. It lives for the whole app, so it MUST be told
/// when the user changes: main.dart wires it to AuthProvider with a
/// ChangeNotifierProxyProvider that calls [updateUser].
///
/// Action methods return `String?`: `null` means success, otherwise a
/// Vietnamese message the screen shows in a SnackBar.
class CartProvider extends ChangeNotifier {
  CartProvider(this._repository);

  final CartRepository _repository;

  // No user = empty cart; with a user it goes initial -> loading in updateUser.
  ViewStatus _status = ViewStatus.empty;
  int? _userId;
  List<CartItem> _items = [];
  String? _errorMessage;

  /// Bumped on every user change to discard a late result of an older load.
  int _generation = 0;
  bool _disposed = false;

  List<CartItem> _lastRemoved = const [];

  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<CartItem> get items => UnmodifiableListView(_items);
  bool get canUndoRemove => _lastRemoved.isNotEmpty;

  Iterable<CartItem> get selectedItems => _items.where((i) => i.isSelected);
  int get selectedCount => selectedItems.length;
  int get selectedTotal => selectedItems.fold(0, (sum, i) => sum + i.lineTotal);
  bool get allSelected =>
      _items.isNotEmpty && _items.every((i) => i.isSelected);

  /// Number on the Cart tab badge: count of lines (items) in the cart, not the
  /// sum of quantities. The same product in another size counts as 2 lines.
  int get itemCount => _items.length;

  /// A selected item that is sold out or over stock blocks checkout.
  bool get hasUnavailableSelected =>
      selectedItems.any((i) => i.stock <= 0 || i.quantity > i.stock);

  /// Called when the user changes or signs out: clears the old cart from memory
  /// and loads the new user's cart. Runs during build, so it never notifies sync.
  void updateUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _generation++;
    _items = [];
    _lastRemoved = const [];
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

  /// Called by Product Detail. `size = ''` when the product has no size.
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

  /// [delta] = +1 / -1. Decreasing at 1 does nothing (remove by swiping).
  Future<String?> changeQuantity(CartItem item, int delta) {
    final quantity = item.quantity + delta;
    if (quantity < 1) return Future.value();
    return setQuantity(item, quantity);
  }

  Future<String?> setQuantity(CartItem item, int quantity) async {
    if (quantity < 1) return 'Số lượng phải từ 1 trở lên';
    if (quantity == item.quantity) return null;
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

  Future<String?> remove(CartItem item) => removeMany([item]);

  /// Removes right away in the UI (so Dismissible can drop the widget); on a DB
  /// error every line goes back to its original position. On success the removed
  /// lines are remembered for [undoRemove] (a multi-size product undoes fully).
  Future<String?> removeMany(List<CartItem> items) async {
    final ids = {for (final item in items) item.id};
    final removed = <(int, CartItem)>[
      for (var i = 0; i < _items.length; i++)
        if (ids.contains(_items[i].id)) (i, _items[i]),
    ];
    if (removed.isEmpty) return null;
    _items = [
      for (final item in _items)
        if (!ids.contains(item.id)) item,
    ];
    _refreshStatus();
    _notify();
    try {
      await _repository.removeMany([for (final (_, item) in removed) item]);
    } catch (error) {
      // Re-insert in ascending original order so each line returns to its place.
      final restored = [..._items];
      for (final (index, item) in removed) {
        restored.insert(index.clamp(0, restored.length), item);
      }
      _items = restored;
      _refreshStatus();
      _notify();
      return _messageOf(error, 'Không thể xóa sản phẩm');
    }
    _lastRemoved = [for (final (_, item) in removed) item];
    return null;
  }

  Future<String?> undoRemove() async {
    final userId = _userId;
    final removed = _lastRemoved;
    if (userId == null || removed.isEmpty) return null;
    _lastRemoved = const [];
    try {
      await _repository.restoreMany(userId, removed);
    } catch (error) {
      return _messageOf(error, 'Không thể hoàn tác');
    }
    await _reload(userId);
    return null;
  }

  /// Reloads without flashing the loading screen (after add / undo).
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

  /// Catches Error too (see AuthProvider._handleError): unknown errors are generic.
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
