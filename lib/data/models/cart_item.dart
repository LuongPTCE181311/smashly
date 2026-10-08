/// Một dòng trong giỏ, ghép từ cart_items + products (JOIN).
/// Giá luôn lấy từ products, giỏ hàng không lưu giá.
class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.stock,
    required this.quantity,
    required this.size,
    required this.isSelected,
  });

  final int id;
  final int productId;
  final String name;
  final String imagePath;
  final int price;
  final int stock;
  final int quantity;

  /// Chuỗi rỗng khi sản phẩm không có size (cột cart_items.size là NOT NULL).
  final String size;
  final bool isSelected;

  int get lineTotal => price * quantity;

  CartItem copyWith({int? quantity, bool? isSelected}) => CartItem(
    id: id,
    productId: productId,
    name: name,
    imagePath: imagePath,
    price: price,
    stock: stock,
    size: size,
    quantity: quantity ?? this.quantity,
    isSelected: isSelected ?? this.isSelected,
  );

  factory CartItem.fromMap(Map<String, Object?> map) => CartItem(
    id: map['id'] as int,
    productId: map['product_id'] as int,
    name: map['name'] as String,
    imagePath: map['image_path'] as String,
    price: map['price'] as int,
    stock: map['stock'] as int,
    quantity: map['quantity'] as int,
    size: map['size'] as String,
    isSelected: (map['is_selected'] as int) == 1,
  );
}
