import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/order.dart';
import '../data/repositories/order_repository.dart';
import 'base_provider.dart';

/// Trạng thái màn Checkout: đang đặt hàng + lỗi lần đặt gần nhất.
class CheckoutProvider extends BaseProvider {
  CheckoutProvider(this._repository);

  final OrderRepository _repository;

  bool _isPlacing = false;
  String? _errorMessage;

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
    notify();
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
      _errorMessage = errorMessageOf(
        error,
        'Không thể đặt hàng. Vui lòng thử lại.',
      );
      _isPlacing = false;
      notify();
      return null;
    }
  }
}
