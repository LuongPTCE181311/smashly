import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';

/// Trạng thái màn Checkout: đang đặt hàng + lỗi lần đặt gần nhất.
class CheckoutProvider extends ChangeNotifier {
  CheckoutProvider(this._repository);

  final OrderRepository _repository;

  bool _isPlacing = false;
  String? _errorMessage;
  bool _disposed = false;

  bool get isPlacing => _isPlacing;
  String? get errorMessage => _errorMessage;

  /// Trả về đơn vừa tạo, hoặc `null` khi lỗi ([errorMessage] có câu lỗi) hoặc
  /// đang đặt dở. Cờ `_isPlacing` bật đồng bộ trước `await` nên bấm 2 lần liên
  /// tiếp chỉ tạo 1 đơn. Thành công thì giữ cờ bật: màn sắp bị thay.
  Future<Order?> placeOrder({
    required int userId,
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    required PaymentMethod paymentMethod,
    String? note,
  }) async {
    if (_isPlacing) return null;
    _isPlacing = true;
    _errorMessage = null;
    _notify();
    try {
      return await _repository.placeOrder(
        userId: userId,
        receiverName: receiverName,
        receiverPhone: receiverPhone,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        note: note,
      );
    } catch (error) {
      if (error is AppException && error.message.isNotEmpty) {
        _errorMessage = error.message;
      } else {
        debugPrint('CheckoutProvider.placeOrder: $error');
        _errorMessage = 'Không thể đặt hàng. Vui lòng thử lại.';
      }
      _isPlacing = false;
      _notify();
      return null;
    }
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
