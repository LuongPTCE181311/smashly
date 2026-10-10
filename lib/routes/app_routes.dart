import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/data/daos/product_dao.dart';
import 'package:smashly/data/repositories/product_repository.dart';
import 'package:smashly/features/home/home_screen.dart';
import 'package:smashly/providers/home_provider.dart';

import '../core/database/db_check_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
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
      register => const PlaceholderScreen(
        code: 'S03',
        title: 'Register',
        owner: 'Hào',
      ),

      home => ChangeNotifierProvider(
        create: (_) => HomeProvider(
          ProductRepository(
            database: () => DatabaseHelper.instance.database,
            productDao: const ProductDao(),
          ),
        )..loadHome(),
        child: const HomeScreen(),
      ),
      shop => const PlaceholderScreen(code: 'S05', title: 'Shop', owner: 'Kha'),
      cart => const PlaceholderScreen(
        code: 'S07',
        title: 'Giỏ hàng',
        owner: 'Danh',
      ),
      myOrders => const PlaceholderScreen(
        code: 'S10',
        title: 'Đơn hàng của tôi',
        owner: 'Lượng',
      ),
      profile || adminProfile => const PlaceholderScreen(
        code: 'S12',
        title: 'Tài khoản',
        owner: 'Hào',
      ),

      productDetail => const PlaceholderScreen(
        code: 'S06',
        title: 'Chi tiết sản phẩm',
        owner: 'Lượng',
      ),
      checkout => const PlaceholderScreen(
        code: 'S08',
        title: 'Thanh toán',
        owner: 'Danh',
      ),
      orderSuccess => const PlaceholderScreen(
        code: 'S09',
        title: 'Đặt hàng thành công',
        owner: 'Danh',
      ),
      orderDetail => const PlaceholderScreen(
        code: 'S11',
        title: 'Chi tiết đơn hàng',
        owner: 'Lượng',
      ),

      adminDashboard => const PlaceholderScreen(
        code: 'S13',
        title: 'Admin Dashboard',
        owner: 'Trọng',
      ),
      adminProducts => const PlaceholderScreen(
        code: 'S14',
        title: 'Quản lý sản phẩm',
        owner: 'Trọng',
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
}
