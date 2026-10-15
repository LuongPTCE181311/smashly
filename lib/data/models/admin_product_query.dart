/// Điều kiện lọc danh sách sản phẩm ở màn Admin Products (S14).
///
/// Khác [ProductQuery] của Shop: lấy cả sản phẩm đang ẩn (`is_active = 0`)
/// và có thêm cờ [onlyHidden] cho chip "Đang ẩn".
class AdminProductQuery {
  const AdminProductQuery({
    this.keyword = '',
    this.categoryId,
    this.onlyHidden = false,
  });

  /// Tìm theo tên hoặc brand (không phân biệt hoa thường).
  final String keyword;

  /// `null` = mọi danh mục.
  final int? categoryId;

  /// `true` = chỉ sản phẩm đang ẩn / ngừng bán.
  final bool onlyHidden;

  /// Có ít nhất một bộ lọc đang bật (để phân biệt "chưa có sản phẩm" với
  /// "lọc không ra kết quả").
  bool get hasFilter =>
      keyword.trim().isNotEmpty || categoryId != null || onlyHidden;

  AdminProductQuery copyWith({
    String? keyword,
    int? categoryId,
    bool clearCategory = false,
    bool? onlyHidden,
  }) {
    return AdminProductQuery(
      keyword: keyword ?? this.keyword,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      onlyHidden: onlyHidden ?? this.onlyHidden,
    );
  }
}
