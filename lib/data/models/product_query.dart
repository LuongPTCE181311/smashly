enum ProductSort { popular, priceAscending, priceDescending, ratingDescending }

class ProductQuery {
  const ProductQuery({
    this.keyword = '',
    this.categoryId,
    this.sort = ProductSort.popular,
  });

  final String keyword;
  final int? categoryId;
  final ProductSort sort;

  ProductQuery copyWith({
    String? keyword,
    int? categoryId,
    bool clearCategory = false,
    ProductSort? sort,
  }) {
    return ProductQuery(
      keyword: keyword ?? this.keyword,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      sort: sort ?? this.sort,
    );
  }
}
