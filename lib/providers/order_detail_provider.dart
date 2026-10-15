import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';

class OrderDetailProvider extends ChangeNotifier {
  OrderDetailProvider(this._repository, {this.orderId, this.userId});

  final OrderRepository _repository;
  final int? orderId;
  final int? userId;

  ViewStatus _status = ViewStatus.initial;
  Order? _order;
  String? _errorMessage;
  bool _disposed = false;

  ViewStatus get status => _status;
  Order? get order => _order;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    final id = orderId;
    final user = userId;
    if (id == null || user == null) {
      _status = ViewStatus.empty;
      _notify();
      return;
    }

    _status = ViewStatus.loading;
    _errorMessage = null;
    _notify();

    try {
      _order = await _repository.getOrderDetail(id, userId: user);
      _status = _order == null ? ViewStatus.empty : ViewStatus.success;
    } catch (error) {
      _status = ViewStatus.error;
      _errorMessage = error is AppException && error.message.isNotEmpty
          ? error.message
          : 'Không thể tải chi tiết đơn hàng. Vui lòng thử lại.';
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
