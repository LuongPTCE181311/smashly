import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../models/user.dart';

class UserDao {
  const UserDao();

  /// Mọi cột trừ `password_hash`; chỉ [findAuthByEmail] được đọc hash.
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

  Future<({User user, String passwordHash})?> findAuthByEmail(
    DatabaseExecutor db,
    String email,
  ) async {
    final rows = await db.query(
      DbSchema.users,
      columns: [..._publicColumns, 'password_hash'],
      where: 'email = ?',
      whereArgs: [email],
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
}
