import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/order_summary.dart';
import '../data/repositories/order_repository.dart';
import 'base_provider.dart';

class OrderProvider extends BaseProvider {
  OrderProvider(this._repository);

  final OrderRepository _repository;

  ViewStatus _status = ViewStatus.empty;
  int? _userId;
  List<OrderSummary> _orders = [];
  String? _errorMessage;
  // Tăng mỗi lần tải mới; kết quả mang số cũ thì bỏ qua.
  int _loadId = 0;

  ViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _userId != null;
  List<OrderSummary> get orders => UnmodifiableListView(_orders);

  List<OrderSummary> ordersWith(OrderStatus? status) {
    if (status == null) return orders;
    return _orders.where((summary) => summary.order.status == status).toList();
  }

  int countOf(OrderStatus? status) => ordersWith(status).length;

  /// Đổi người dùng: xóa dữ liệu cũ rồi tải lại cho [userId] (null = đã đăng xuất).
  void updateUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _loadId++;
    _orders = [];
    _errorMessage = null;
    _status = userId == null ? ViewStatus.empty : ViewStatus.initial;
    // Hàm này chạy trong lúc ProxyProvider build nên không được notify ngay.
    Future.microtask(() {
      if (userId != _userId) return;
      if (userId == null) {
        notify();
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
    final loadId = _loadId;

    if (showLoading) {
      _status = ViewStatus.loading;
      _errorMessage = null;
      notify();
    }

    try {
      final orders = await _repository.getOrderHistory(userId);
      if (loadId != _loadId) return;
      _orders = orders;
      _errorMessage = null;
      _status = orders.isEmpty ? ViewStatus.empty : ViewStatus.success;
    } catch (error) {
      if (loadId != _loadId) return;
      if (showLoading) {
        _status = ViewStatus.error;
        _errorMessage = errorMessageOf(
          error,
          'Không thể tải danh sách đơn hàng. Vui lòng thử lại.',
        );
      } else {
        debugPrint('OrderProvider.refresh: $error');
      }
    }

    notify();
  }
}
