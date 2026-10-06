import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/database/db_debug.dart';
import 'core/services/session_service.dart';
import 'data/daos/cart_dao.dart';
import 'data/daos/user_dao.dart';
import 'data/repositories/auth_repository.dart';
import 'providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tạm mở DB trước runApp; khi có SplashScreen, việc mở DB chuyển vào Splash
  // để lỗi khởi tạo hiện được thông báo + nút Thử lại.
  await DatabaseHelper.instance.database;
  await debugPrintDbSummary();

  final authRepository = AuthRepository(
    database: () => DatabaseHelper.instance.database,
    userDao: const UserDao(),
    cartDao: const CartDao(),
    sessionService: SessionService(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
      ],
      child: const SmashlyApp(),
    ),
  );
}
