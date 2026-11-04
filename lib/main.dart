import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/wishlist_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/shell_tab_provider.dart';
import 'providers/wishlist_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // DB chưa mở ở đây: Splash mở qua AuthProvider.restoreSession() để lỗi khởi
  // tạo hiện "Không khởi tạo được dữ liệu" + nút Thử lại thay vì app trắng.
  final authRepository = AuthRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => ShellTabProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(CartRepository()),
          update: (_, auth, cart) => cart!..updateUser(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(WishlistRepository()),
          update: (_, auth, wishlist) =>
              wishlist!..updateUser(auth.currentUser?.id),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(OrderRepository()),
          update: (_, auth, orders) =>
              orders!..updateUser(auth.currentUser?.id),
        ),
      ],
      child: const SmashlyApp(),
    ),
  );
}
