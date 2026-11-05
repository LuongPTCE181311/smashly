import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/admin_dashboard_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../dev/db_check_screen.dart';
import '../dev/dev_menu_screen.dart';
import '../dev/widget_catalog_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_product_form_screen.dart';
import '../features/admin/admin_products_screen.dart';
import '../features/auth/admin_guard.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/order_success_screen.dart';
import '../features/home/home_screen.dart';
import '../features/orders/my_orders_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/product/product_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/app_tab.dart';
import '../features/shop/shop_screen.dart';
import '../features/wishlist/wishlist_screen.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_product_form_provider.dart';
import '../providers/admin_product_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/checkout_provider.dart';
import '../providers/forgot_password_provider.dart';
import '../providers/home_provider.dart';
import '../providers/order_detail_provider.dart';
import '../providers/product_detail_provider.dart';
import '../providers/shop_provider.dart';
import 'app_page_route.dart';
import 'not_found_screen.dart';

/// Tên route và bảng route → màn hình của cả app.
///
/// Điều hướng luôn dùng hằng số, không gõ chuỗi:
/// ```dart
/// Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id);
/// ```
abstract final class AppRoutes {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword =
      '/forgot-password'; // arguments: String? email điền sẵn

  // 5 tab trong AppShell — mở route này = mở AppShell ở đúng tab đó.
  // Đang ở trong app thì đổi tab bằng AppShell.goToTab(context, AppTab.cart).
  static const home = '/home';
  static const shop = '/shop';
  static const cart = '/cart';
  static const myOrders = '/orders';
  static const profile = '/profile';

  // Màn hình yêu thích mở từ Profile.
  static const wishlist = '/wishlist';

  // Màn đẩy lên trên AppShell (có nút Back).
  static const productDetail = '/product'; // arguments: int productId
  static const checkout = '/checkout';
  static const orderSuccess = '/order-success'; // arguments: int orderId
  static const orderDetail = '/order-detail'; // arguments: int orderId

  // Admin, không có bottom nav.
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
  static const widgetCatalog = '/dev/widgets';

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
      forgotPassword => ChangeNotifierProvider<ForgotPasswordProvider>(
        create: (_) => ForgotPasswordProvider(const AuthRepository()),
        child: ForgotPasswordScreen(
          initialEmail: arguments is String ? arguments : null,
        ),
      ),

      home => ChangeNotifierProvider<HomeProvider>(
        create: (_) => HomeProvider(ProductRepository())..loadHome(),
        child: const HomeScreen(),
      ),

      shop => ChangeNotifierProvider<ShopProvider>(
        create: (_) => ShopProvider(ProductRepository())..loadInitial(),
        child: const ShopScreen(),
      ),

      cart => const CartScreen(),
      myOrders => const MyOrdersScreen(),
      profile || adminProfile => const ProfileScreen(),
      wishlist => const WishlistScreen(),
      productDetail => ChangeNotifierProvider<ProductDetailProvider>(
        create: (_) => ProductDetailProvider(
          ProductRepository(),
          arguments is int ? arguments : null,
        )..load(),
        child: const ProductDetailScreen(),
      ),
      checkout => ChangeNotifierProvider<CheckoutProvider>(
        create: (_) => CheckoutProvider(OrderRepository()),
        child: const CheckoutScreen(),
      ),
      orderSuccess => _withOrder(arguments, const OrderSuccessScreen()),
      orderDetail => _withOrder(arguments, const OrderDetailScreen()),

      adminDashboard => ChangeNotifierProvider<AdminDashboardProvider>(
        create: (_) =>
            AdminDashboardProvider(AdminDashboardRepository())..load(),
        child: const AdminDashboardScreen(),
      ),
      adminProducts => ChangeNotifierProvider<AdminProductProvider>(
        create: (_) => AdminProductProvider(ProductRepository())..loadInitial(),
        child: const AdminProductsScreen(),
      ),
      adminProductForm => ChangeNotifierProvider<AdminProductFormProvider>(
        create: (_) => AdminProductFormProvider(
          ProductRepository(),
          productId: arguments is int ? arguments : null,
        ),
        child: const AdminProductFormScreen(),
      ),

      devMenu => const DevMenuScreen(),
      dbCheck => const DbCheckScreen(),
      widgetCatalog => const WidgetCatalogScreen(),
      _ => NotFoundScreen(routeName: name),
    };
  }

  /// Nạp đơn `arguments` (int orderId) của user đang đăng nhập cho [child].
  static Widget _withOrder(Object? arguments, Widget child) {
    return ChangeNotifierProvider<OrderDetailProvider>(
      create: (context) => OrderDetailProvider(
        OrderRepository(),
        orderId: arguments is int ? arguments : null,
        userId: context.read<AuthProvider>().currentUser?.id,
      )..load(),
      child: child,
    );
  }
}
