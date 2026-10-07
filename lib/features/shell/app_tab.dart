import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

/// 5 tab của bottom nav customer, theo thứ tự hiển thị.
enum AppTab {
  home(AppRoutes.home, 'Trang chủ', Icons.home_outlined, Icons.home_rounded),
  shop(
    AppRoutes.shop,
    'Cửa hàng',
    Icons.storefront_outlined,
    Icons.storefront_rounded,
  ),
  cart(
    AppRoutes.cart,
    'Giỏ hàng',
    Icons.shopping_bag_outlined,
    Icons.shopping_bag_rounded,
  ),
  orders(
    AppRoutes.myOrders,
    'Đơn hàng',
    Icons.receipt_long_outlined,
    Icons.receipt_long_rounded,
  ),
  profile(
    AppRoutes.profile,
    'Tài khoản',
    Icons.person_outline_rounded,
    Icons.person_rounded,
  );

  const AppTab(this.routeName, this.label, this.icon, this.selectedIcon);

  final String routeName;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Tab ứng với tên route, `null` nếu route không phải tab.
  static AppTab? fromRoute(String? name) {
    for (final tab in values) {
      if (tab.routeName == name) return tab;
    }
    return null;
  }
}
