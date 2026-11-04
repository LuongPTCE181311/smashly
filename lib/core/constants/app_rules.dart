/// Luật nghiệp vụ dùng chung của cửa hàng.
abstract final class AppRules {
  /// Phí ship cho đơn dưới [freeShippingFrom].
  static const shippingFee = 30000;

  /// Đơn từ mức này trở lên được miễn phí ship.
  static const freeShippingFrom = 1000000;

  /// Tồn kho từ mức này trở xuống là "sắp hết hàng".
  static const lowStockThreshold = 5;

  /// Số lượng tối đa của một dòng trong giỏ.
  static const maxQuantityPerLine = 99;

  /// Thời gian chờ sau lần gõ cuối mới tìm kiếm.
  static const searchDebounce = Duration(milliseconds: 300);
}
