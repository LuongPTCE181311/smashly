import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/data/daos/order_dao.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/repositories/order_repository.dart';
import 'package:smashly/data/repositories/product_repository.dart';
import 'package:smashly/features/admin/admin_products_screen.dart';
import 'package:smashly/features/checkout/checkout_screen.dart';
import 'package:smashly/features/checkout/order_success_screen.dart';
import 'package:smashly/features/home/home_screen.dart';
import 'package:smashly/features/orders/my_orders_screen.dart';
import 'package:smashly/features/orders/order_detail_screen.dart';
import 'package:smashly/features/shop/shop_screen.dart';
import 'package:smashly/features/product/product_detail_screen.dart';
import 'package:smashly/providers/admin_product_provider.dart';
import 'package:smashly/providers/auth_provider.dart';
import 'package:smashly/providers/checkout_provider.dart';
import 'package:smashly/providers/home_provider.dart';
import 'package:smashly/providers/order_detail_provider.dart';
import 'package:smashly/providers/order_provider.dart';
import 'package:smashly/providers/product_detail_provider.dart';
import 'package:smashly/providers/shop_provider.dart';

import '../core/database/db_check_screen.dart';
import '../features/auth/admin_guard.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/app_tab.dart';
import 'app_page_route.dart';
import 'dev_menu_screen.dart';
import 'placeholder_screen.dart';

/// Tên route + bảng "tên route → màn hình" của cả app. OWNER: Lượng.
///
/// Đủ 15 màn ngay từ đầu, màn chưa làm trỏ tới [PlaceholderScreen].
/// Làm xong màn của mình → **chỉ thay đúng dòng placeholder của mình** trong
/// [screen], không thêm/xóa route khác (tránh conflict).
///
/// Điều hướng luôn dùng hằng số, không gõ chuỗi:
/// ```dart
/// Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id);
/// Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
/// ```
abstract final class AppRoutes {
  // Auth (Hào)
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // 5 tab trong AppShell — mở route này = mở AppShell ở đúng tab đó.
  // Đang ở trong app thì đổi tab bằng AppShell.goToTab(context, AppTab.cart).
  static const home = '/home';
  static const shop = '/shop';
  static const cart = '/cart';
  static const myOrders = '/orders';
  static const profile = '/profile';

  // Màn đẩy lên trên AppShell (có nút Back).
  static const productDetail = '/product'; // arguments: int productId
  static const checkout = '/checkout';
  static const orderSuccess = '/order-success'; // arguments: int orderId
  static const orderDetail = '/order-detail'; // arguments: int orderId

  // Admin (Trọng) — không có bottom nav.
  static const adminDashboard = '/admin';
  static const adminProducts = '/admin/products';
  static const adminProductForm =
      '/admin/product-form'; // arguments: int? productId (null = thêm mới)
  static const adminProfile =
      '/admin/profile'; // cùng màn Profile, mở từ menu avatar admin
  static const _adminOnly = {adminDashboard, adminProducts, adminProductForm};

  // Chỉ dùng khi dev.
  static const devMenu = '/dev';
  static const dbCheck = '/dev/db';

  /// Truyền vào `MaterialApp.onGenerateRoute`.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? splash;
    final tab = AppTab.fromRoute(name);
    return AppPageRoute(
      settings: settings,
      builder: (_) => tab != null
          ? AppShell(initialTab: tab)
          : _adminOnly.contains(name)
          ? AdminGuard(child: screen(name, settings.arguments))
          : screen(name, settings.arguments),
    );
  }

  /// Màn hình ứng với [name]. AppShell cũng gọi hàm này để dựng 5 tab.
  ///
  /// Đọc arguments theo kiểu đã ghi ở hằng số, ví dụ:
  /// `productDetail => ProductDetailScreen(productId: arguments! as int),`
  static Widget screen(String name, [Object? arguments]) {
    return switch (name) {
      splash => const SplashScreen(),
      login => LoginScreen(
        initialEmail: arguments is String ? arguments : null,
      ),
      register => const RegisterScreen(),

      home => ChangeNotifierProvider<HomeProvider>(
        create: (context) {
          // Bước 1: Tạo DAO
          const productDao = ProductDao();
          // Bước 2: Tạo Repository
          final repository = ProductRepository(
            database: () => DatabaseHelper.instance.database,
            productDao: productDao,
          );
          // Bước 3: Tạo Provider
          final provider = HomeProvider(repository);
          // Bước 4: Bắt đầu tải dữ liệu
          provider.loadHome();
          // Bước 5: Trả Provider cho ChangeNotifierProvider
          return provider;
        },
        // Bước 6: Hiển thị HomeScreen
        child: const HomeScreen(),
      ),

      shop => ChangeNotifierProvider<ShopProvider>(
        create: (_) {
          // DAO làm việc trực tiếp với SQLite.
          const productDao = ProductDao();

          // Repository kết nối DAO và DatabaseHelper.
          final repository = ProductRepository(
            database: () => DatabaseHelper.instance.database,
            productDao: productDao,
          );

          // Provider giữ state của Shop.
          final provider = ShopProvider(repository);

          // Tải dữ liệu ban đầu.
          provider.loadInitial();

          return provider;
        },
        child: const ShopScreen(),
      ),

      cart => const CartScreen(),
      myOrders => ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
        create: (_) => OrderProvider(
          OrderRepository(
            database: () => DatabaseHelper.instance.database,
            orderDao: const OrderDao(),
          ),
        ),
        update: (_, auth, orders) => orders!..updateUser(auth.currentUser?.id),
        child: const MyOrdersScreen(),
      ),
      profile || adminProfile => const ProfileScreen(),

      productDetail => ChangeNotifierProvider<ProductDetailProvider>(
        create: (_) => ProductDetailProvider(
          ProductRepository(
            database: () => DatabaseHelper.instance.database,
            productDao: const ProductDao(),
          ),
          arguments is int ? arguments : null,
        )..load(),
        child: const ProductDetailScreen(),
      ),
      checkout => ChangeNotifierProvider<CheckoutProvider>(
        create: (_) => CheckoutProvider(
          OrderRepository(
            database: () => DatabaseHelper.instance.database,
            orderDao: const OrderDao(),
          ),
        ),
        child: const CheckoutScreen(),
      ),
      orderSuccess => _withOrder(arguments, const OrderSuccessScreen()),
      orderDetail => _withOrder(arguments, const OrderDetailScreen()),

      adminDashboard => const PlaceholderScreen(
        code: 'S13',
        title: 'Admin Dashboard',
        owner: 'Trọng',
      ),
      adminProducts => ChangeNotifierProvider<AdminProductProvider>(
        create: (_) => AdminProductProvider(
          ProductRepository(
            database: () => DatabaseHelper.instance.database,
            productDao: const ProductDao(),
          ),
        )..loadInitial(),
        child: const AdminProductsScreen(),
      ),
      adminProductForm => const PlaceholderScreen(
        code: 'S15',
        title: 'Thêm / sửa sản phẩm',
        owner: 'Trọng',
      ),

      devMenu => const DevMenuScreen(),
      dbCheck => const DbCheckScreen(),
      _ => PlaceholderScreen(
        code: '404',
        title: 'Không tìm thấy màn "$name"',
        owner: '—',
      ),
    };
  }

  /// Nạp đơn `arguments` (int orderId) của user đang đăng nhập cho [child].
  static Widget _withOrder(Object? arguments, Widget child) {
    return ChangeNotifierProvider<OrderDetailProvider>(
      create: (context) => OrderDetailProvider(
        OrderRepository(
          database: () => DatabaseHelper.instance.database,
          orderDao: const OrderDao(),
        ),
        orderId: arguments is int ? arguments : null,
        userId: context.read<AuthProvider>().currentUser?.id,
      )..load(),
      child: child,
    );
  }
}
