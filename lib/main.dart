import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/services/session_service.dart';
import 'data/daos/cart_dao.dart';
import 'data/daos/user_dao.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // DB chưa mở ở đây: Splash mở qua AuthProvider.restoreSession() để lỗi khởi
  // tạo hiện "Không khởi tạo được dữ liệu" + nút Thử lại thay vì app trắng.
  final authRepository = AuthRepository(
    database: () => DatabaseHelper.instance.database,
    userDao: const UserDao(),
    cartDao: const CartDao(),
    sessionService: SessionService(),
  );
  final cartRepository = CartRepository(
    database: () => DatabaseHelper.instance.database,
    cartDao: const CartDao(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(cartRepository),
          update: (_, auth, cart) => cart!..updateUser(auth.currentUser?.id),
        ),
      ],
      child: const SmashlyApp(),
    ),
  );
}
