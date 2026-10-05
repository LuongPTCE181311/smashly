import 'package:sqflite/sqflite.dart';

import '../../utils/password_hasher.dart';
import '../db_schema.dart';
import 'seed_demo_data.dart';

/// OWNER: TV1.
///
/// | id | Email                 | Mật khẩu     | Role     |
/// |----|-----------------------|--------------|----------|
/// | 1  | admin@smashly.com     | Admin@123    | ADMIN    |
/// | 2  | customer@smashly.com  | Customer@123 | CUSTOMER |
/// | 3  | newbie@smashly.com    | Newbie@123   | CUSTOMER |
///
/// Id cố định để seed khác (giỏ hàng, đơn hàng) tham chiếu được.
class SeedUserIds {
  SeedUserIds._();
  static const int admin = 1;
  static const int customer = 2;
  static const int newbie = 3;
}

Future<void> seedUsers(DatabaseExecutor db, DateTime now) async {
  final users = [
    {
      'id': SeedUserIds.admin,
      'full_name': 'SMASHLY Admin',
      'email': 'admin@smashly.com',
      'password': 'Admin@123',
      'phone': '0900000000',
      'role': 'ADMIN',
      'address': null,
    },
    {
      'id': SeedUserIds.customer,
      'full_name': 'Nguyễn Minh Anh',
      'email': 'customer@smashly.com',
      'password': 'Customer@123',
      'phone': '0901234567',
      'role': 'CUSTOMER',
      'address': '12 Lê Lợi, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
    },
    {
      'id': SeedUserIds.newbie,
      'full_name': 'Trần Gia Bảo',
      'email': 'newbie@smashly.com',
      'password': 'Newbie@123',
      'phone': '0912345678',
      'role': 'CUSTOMER',
      'address': null,
    },
  ];

  for (final u in users) {
    final email = u['email'] as String;
    await db.insert(DbSchema.users, {
      'id': u['id'],
      'full_name': u['full_name'],
      'email': email,
      'phone': u['phone'],
      'password_hash': PasswordHasher.hash(email, u['password'] as String),
      'role': u['role'],
      'address': u['address'],
      'created_at': dbTime(now),
    });

    // Mỗi customer có đúng một giỏ hàng (cart.id = user.id cho dễ nhớ).
    if (u['role'] == 'CUSTOMER') {
      await db.insert(DbSchema.carts, {
        'id': u['id'],
        'user_id': u['id'],
        'updated_at': dbTime(now),
      });
    }
  }
}
