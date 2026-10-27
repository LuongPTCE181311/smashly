class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.rating,
    required this.ratingCount,
    required this.description,
    required this.imagePath,
    this.sizes,
    required this.isFeatured,
    required this.isActive,
  });

  final int id;
  final int categoryId;
  final String name;
  final String brand;

  final int price;
  final int? originalPrice;

  final int stock;

  final double rating;
  final int ratingCount;

  final String description;
  final String imagePath;

  final String? sizes;

  final bool isFeatured;
  final bool isActive;

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  int get discountPercent {
    if (!hasDiscount) return 0;

    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      brand: map['brand'] as String,
      price: map['price'] as int,
      originalPrice: map['original_price'] as int?,
      stock: map['stock'] as int,
      rating: (map['rating'] as num).toDouble(),
      ratingCount: map['rating_count'] as int,
      description: map['description'] as String,
      imagePath: map['image_path'] as String,
      sizes: map['sizes'] as String?,
      isFeatured: (map['is_featured'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
    );
  }
}
