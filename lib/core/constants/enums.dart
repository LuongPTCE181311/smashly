enum UserRole {
  customer('CUSTOMER'),
  admin('ADMIN');

  const UserRole(this.dbValue);

  /// Giá trị lưu trong cột `users.role`, khớp CHECK constraint trong db_schema.dart.
  final String dbValue;

  /// Nhãn vai trò hiển thị trên giao diện.
  String get label => switch (this) {
    UserRole.customer => 'Khách hàng',
    UserRole.admin => 'Admin',
  };

  static UserRole fromDb(String value) => values.firstWhere(
    (role) => role.dbValue == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Unknown user role'),
  );
}

enum OrderStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  shipping('SHIPPING'),
  delivered('DELIVERED'),
  cancelled('CANCELLED');

  const OrderStatus(this.dbValue);

  /// Giá trị lưu trong cột `orders.status`, khớp CHECK constraint trong db_schema.dart.
  final String dbValue;

  static OrderStatus fromDb(String value) => values.firstWhere(
    (status) => status.dbValue == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Unknown order status'),
  );

  /// Luật chuyển trạng thái (UC19), chỗ DUY NHẤT định nghĩa: UI dựa vào đây để
  /// hiện nút, Repository dựa vào đây để chặn. Luồng một chiều, không nhảy bước;
  /// chỉ hủy được từ PENDING hoặc CONFIRMED.
  List<OrderStatus> get allowedNextStatuses => switch (this) {
    OrderStatus.pending => const [OrderStatus.confirmed, OrderStatus.cancelled],
    OrderStatus.confirmed => const [
      OrderStatus.shipping,
      OrderStatus.cancelled,
    ],
    OrderStatus.shipping => const [OrderStatus.delivered],
    OrderStatus.delivered || OrderStatus.cancelled => const [],
  };

  bool canTransitionTo(OrderStatus next) => allowedNextStatuses.contains(next);

  /// Trạng thái cuối: không đổi được nữa.
  bool get isFinal => allowedNextStatuses.isEmpty;
}

enum PaymentMethod {
  cod('COD'),
  bankTransfer('BANK_TRANSFER'),
  eWallet('E_WALLET');

  const PaymentMethod(this.dbValue);

  /// Giá trị lưu trong cột `orders.payment_method`.
  final String dbValue;

  static PaymentMethod fromDb(String value) => values.firstWhere(
    (method) => method.dbValue == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Unknown payment method'),
  );
}

enum ViewStatus { initial, loading, success, empty, error }

/// Kết quả `ProductRepository.deleteProduct`: xóa thật hay chỉ ngừng bán.
enum ProductDeleteOutcome { deleted, deactivated }
