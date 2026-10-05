import 'package:flutter/foundation.dart';

import 'database_helper.dart';
import 'db_schema.dart';

/// Kiểm tra nhanh DB đã tạo + seed đúng chưa (chỉ dùng khi dev).
/// Gọi tạm trong main.dart:  await debugPrintDbSummary();
/// Kết quả mong đợi: users 3, categories 10, products 22, racket_specs 9,
/// carts 2, cart_items 1, orders 4, order_items 5, wishlists 0.
Future<void> debugPrintDbSummary() async {
  if (!kDebugMode) return;
  final db = await DatabaseHelper.instance.database;
  for (final table in DbSchema.tablesInDropOrder.reversed) {
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    debugPrint('[DB] $table: ${result.first['c']}');
  }
}
