import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../models/user.dart';

class UserDao {
  const UserDao();

  /// Mọi cột trừ `password_hash`; chỉ các hàm `findAuth…` được đọc hash.
  static const _publicColumns = [
    'id',
    'full_name',
    'email',
    'phone',
    'role',
    'address',
    'created_at',
  ];

  Future<User?> findById(DatabaseExecutor db, int id) async {
    final rows = await db.query(
      DbSchema.users,
      columns: _publicColumns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<User?> findByEmail(DatabaseExecutor db, String email) async {
    final rows = await db.query(
      DbSchema.users,
      columns: _publicColumns,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  /// Người dùng theo email kèm hash mật khẩu, dùng khi đăng nhập.
  Future<({User user, String passwordHash})?> findAuthByEmail(
    DatabaseExecutor db,
    String email,
  ) => _findAuth(db, 'email = ?', email);

  /// Người dùng theo id kèm hash mật khẩu, dùng khi đổi mật khẩu.
  Future<({User user, String passwordHash})?> findAuthById(
    DatabaseExecutor db,
    int id,
  ) => _findAuth(db, 'id = ?', id);

  Future<({User user, String passwordHash})?> _findAuth(
    DatabaseExecutor db,
    String where,
    Object value,
  ) async {
    final rows = await db.query(
      DbSchema.users,
      columns: [..._publicColumns, 'password_hash'],
      where: where,
      whereArgs: [value],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    return (
      user: User.fromMap(row),
      passwordHash: row['password_hash'] as String,
    );
  }

  Future<bool> existsByEmail(DatabaseExecutor db, String email) async {
    final rows = await db.query(
      DbSchema.users,
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> insert(DatabaseExecutor db, User user, String passwordHash) {
    return db.insert(DbSchema.users, {
      'full_name': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'password_hash': passwordHash,
      'role': user.role.dbValue,
      'address': user.address,
    });
  }

  Future<int> updateProfile(
    DatabaseExecutor db, {
    required int userId,
    required String fullName,
    required String phone,
    required String? address,
  }) {
    return db.update(
      DbSchema.users,
      {'full_name': fullName, 'phone': phone, 'address': address},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Ghi hash mật khẩu mới. Trả về số dòng đã sửa (0 = không có user này).
  Future<int> updatePasswordHash(
    DatabaseExecutor db,
    int userId,
    String passwordHash,
  ) {
    return db.update(
      DbSchema.users,
      {'password_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
