enum UserRole {
  customer('CUSTOMER'),
  admin('ADMIN');

  const UserRole(this.dbValue);

  /// Giá trị lưu trong cột `users.role`, khớp CHECK constraint trong db_schema.dart.
  final String dbValue;

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
