import 'order.dart';
import 'order_item.dart';

class OrderSummary {
  const OrderSummary({
    required this.order,
    required this.firstItem,
    required this.itemCount,
  });

  final Order order;
  final OrderItem? firstItem;
  final int itemCount;

  int get otherItemCount => itemCount > 1 ? itemCount - 1 : 0;
}
