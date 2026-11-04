import 'package:sqflite/sqflite.dart';

import 'seed_catalog.dart';
import 'seed_orders.dart';
import 'seed_users.dart';

/// Tạo toàn bộ dữ liệu demo. Chỉ được gọi từ DatabaseHelper
/// (onCreate / onUpgrade), nên không bao giờ bị chạy hai lần.
///
/// File này chỉ gọi lần lượt, không chứa dữ liệu.
Future<void> seedDemoData(DatabaseExecutor db) async {
  final now = DateTime.now();
  await seedUsers(db, now);
  await seedCatalog(db, now);
  await seedOrders(db, now); // cần users + products có trước
}

