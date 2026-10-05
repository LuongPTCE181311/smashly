import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/database/db_debug.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mở (hoặc tạo lần đầu + seed) SQLite trước khi vẽ giao diện.
  await DatabaseHelper.instance.database;
  await debugPrintDbSummary();

  // TODO(TV1): bọc bằng MultiProvider khi có AuthProvider, CartProvider.
  runApp(const SmashlyApp());
}
