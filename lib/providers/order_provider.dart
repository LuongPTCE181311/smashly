import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/order_summary.dart';
import '../data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._repository);

  final OrderRepository _repository;

  ViewStatus _status = ViewStatus.initial;
  int? _userId;
  bool _userKnown = false;
  List<OrderSummary> _orders = [];
  String? _errorMessage;
  int _generation = 0;
  bool _disposed = false;

  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _userId != null;
  List<OrderSummary> get orders => UnmodifiableListView(_orders);

  List<OrderSummary> ordersWith(OrderStatus? status) {
    if (status == null) return orders;
    return _orders.where((summary) => summary.order.status == status).toList();
  }

  int countOf(OrderStatus? status) => ordersWith(status).length;

  void updateUser(int? userId) {
    if (_userKnown && userId == _userId) return;
    _userKnown = true;
    _userId = userId;
    _generation++;
    _orders = [];
    _errorMessage = null;
    _status = userId == null ? ViewStatus.empty : ViewStatus.initial;
    Future.microtask(() {
      if (userId != _userId) return;
      if (userId == null) {
        _notify();
      } else {
        load();
      }
    });
  }

  Future<void> load() => _fetch(showLoading: true);

  Future<void> refresh() => _fetch(showLoading: _orders.isEmpty);

  Future<void> _fetch({required bool showLoading}) async {
    final userId = _userId;
    if (userId == null) return;
    final generation = _generation;

    if (showLoading) {
      _status = ViewStatus.loading;
      _errorMessage = null;
      _notify();
    }

    try {
      final orders = await _repository.getOrderHistory(userId);
      if (generation != _generation) return;
      _orders = orders;
      _errorMessage = null;
      _status = orders.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } catch (error) {
      if (generation != _generation) return;
      if (showLoading) {
        _status = ViewStatus.error;
        _errorMessage = error is AppException && error.message.isNotEmpty
            ? error.message
            : 'Không thể tải danh sách đơn hàng. Vui lòng thử lại.';
      } else {
        debugPrint('OrderProvider.refresh: $error');
      }
    }

    _notify();
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
