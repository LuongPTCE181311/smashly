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

enum ViewStatus { initial, loading, success, empty, error }

/// Kết quả `ProductRepository.deleteProduct`: xóa thật hay chỉ ngừng bán.
enum ProductDeleteOutcome { deleted, deactivated }
