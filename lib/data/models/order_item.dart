/// Một dòng trong đơn hàng (bảng order_items).
/// Tên, ảnh, giá được chụp lại lúc đặt nên đổi/xóa sản phẩm sau này không làm
/// sai đơn cũ; vì vậy [productId] có thể null (sản phẩm đã bị xóa).
class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.size,
  });

  final int id;
  final int orderId;
  final int? productId;
  final String productName;
  final String productImage;
  final int unitPrice;
  final int quantity;

  /// Chuỗi rỗng khi sản phẩm không có size (cột order_items.size cho phép NULL).
  final String size;

  int get lineTotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, Object?> map) => OrderItem(
    id: map['id'] as int,
    orderId: map['order_id'] as int,
    productId: map['product_id'] as int?,
    productName: map['product_name'] as String,
    productImage: map['product_image'] as String,
    unitPrice: map['unit_price'] as int,
    quantity: map['quantity'] as int,
    size: (map['size'] as String?) ?? '',
  );
}
