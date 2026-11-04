import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';
import 'base_provider.dart';

class OrderDetailProvider extends BaseProvider {
  OrderDetailProvider(this._repository, {this.orderId, this.userId});

  final OrderRepository _repository;
  final int? orderId;
  final int? userId;

  ViewStatus _status = ViewStatus.initial;
  Order? _order;
  String? _errorMessage;
  bool _isCancelling = false;

  ViewStatus get status => _status;
  Order? get order => _order;
  String? get errorMessage => _errorMessage;
  bool get isCancelling => _isCancelling;
  bool get canCancel => _order?.status == OrderStatus.pending && userId != null;

  Future<void> load() async {
    final id = orderId;
    final user = userId;
    if (id == null || user == null) {
      _status = ViewStatus.empty;
      notify();
      return;
    }

    _status = ViewStatus.loading;
    _errorMessage = null;
    notify();

    try {
      _order = await _repository.getOrderDetail(id, userId: user);
      _status = _order == null ? ViewStatus.empty : ViewStatus.success;
    } catch (error) {
      _status = ViewStatus.error;
      _errorMessage = errorMessageOf(
        error,
        'Không thể tải chi tiết đơn hàng. Vui lòng thử lại.',
      );
    }

    notify();
  }

  Future<String?> cancelOrder() async {
    final current = _order;
    final user = userId;
    if (current == null || user == null || !canCancel || _isCancelling) {
      return null;
    }

    _isCancelling = true;
    notify();

    String? error;
    try {
      _order = await _repository.cancelOrder(current.id, userId: user);
    } catch (caught) {
      error = errorMessageOf(
        caught,
        'Không thể hủy đơn hàng. Vui lòng thử lại.',
      );
    }

    _isCancelling = false;
    notify();
    return error;
  }
}
