import '../../core/constants/enums.dart';
import '../../core/utils/db_time.dart';

/// Không chứa `password_hash`: hash chỉ được đọc qua `UserDao.findAuthByEmail`
/// và chỉ Repository dùng, để thông tin đăng nhập không đi lên Provider/UI.
class User {
  const User({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.address,
    this.createdAt,
  });

  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? address;
  final DateTime? createdAt;

  bool get isAdmin => role == UserRole.admin;

  factory User.fromMap(Map<String, Object?> map) => User(
    id: map['id'] as int,
    fullName: map['full_name'] as String,
    email: map['email'] as String,
    phone: map['phone'] as String,
    role: UserRole.fromDb(map['role'] as String),
    address: map['address'] as String?,
    createdAt: parseDbTime(map['created_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'role': role.dbValue,
    'address': address,
    if (createdAt != null) 'created_at': dbTime(createdAt!),
  };
}
