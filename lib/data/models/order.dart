import '../../core/constants/enums.dart';
import '../../core/utils/db_time.dart';
import 'order_item.dart';

/// Một đơn hàng (bảng orders) kèm các dòng [items] (bảng order_items).
/// Danh sách đơn có thể bỏ trống [items]; màn chi tiết thì nạp đủ.
class Order {
  const Order({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.status,
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.note,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.items = const [],
  });

  final int id;
  final String orderCode;
  final int userId;
  final OrderStatus status;
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final PaymentMethod paymentMethod;
  final String? note;
  final int subtotal;
  final int shippingFee;
  final int total;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final List<OrderItem> items;

  /// Tổng số lượng sản phẩm (cộng số lượng từng dòng).
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  Order copyWith({List<OrderItem>? items}) => Order(
    id: id,
    orderCode: orderCode,
    userId: userId,
    status: status,
    receiverName: receiverName,
    receiverPhone: receiverPhone,
    shippingAddress: shippingAddress,
    paymentMethod: paymentMethod,
    note: note,
    subtotal: subtotal,
    shippingFee: shippingFee,
    total: total,
    createdAt: createdAt,
    confirmedAt: confirmedAt,
    shippedAt: shippedAt,
    deliveredAt: deliveredAt,
    cancelledAt: cancelledAt,
    items: items ?? this.items,
  );

  factory Order.fromMap(
    Map<String, Object?> map, {
    List<OrderItem> items = const [],
  }) {
    DateTime? time(String column) {
      final value = map[column] as String?;
      return value == null ? null : parseDbTime(value);
    }

    return Order(
      id: map['id'] as int,
      orderCode: map['order_code'] as String,
      userId: map['user_id'] as int,
      status: OrderStatus.fromDb(map['status'] as String),
      receiverName: map['receiver_name'] as String,
      receiverPhone: map['receiver_phone'] as String,
      shippingAddress: map['shipping_address'] as String,
      paymentMethod: PaymentMethod.fromDb(map['payment_method'] as String),
      note: map['note'] as String?,
      subtotal: map['subtotal'] as int,
      shippingFee: map['shipping_fee'] as int,
      total: map['total'] as int,
      createdAt: time('created_at')!,
      confirmedAt: time('confirmed_at'),
      shippedAt: time('shipped_at'),
      deliveredAt: time('delivered_at'),
      cancelledAt: time('cancelled_at'),
      items: items,
    );
  }
}
