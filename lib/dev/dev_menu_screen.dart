import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../routes/app_routes.dart';
import '../shared/widgets/app_logo.dart';

/// Màn dev: mở nhanh mọi route để kiểm tay; mở bằng --dart-define=START_ROUTE=/dev.
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  static const _sections = <(String, List<(String, String, Object?)>)>[
    (
      'Auth',
      [
        ('Login', AppRoutes.login, null),
        ('Register', AppRoutes.register, null),
      ],
    ),
    (
      'Customer (mở AppShell ở tab tương ứng)',
      [
        ('Home', AppRoutes.home, null),
        ('Shop', AppRoutes.shop, null),
        ('Cart', AppRoutes.cart, null),
        ('My Orders', AppRoutes.myOrders, null),
        ('Profile', AppRoutes.profile, null),
      ],
    ),
    (
      'Màn đẩy lên trên AppShell',
      [
        ('Product Detail (id 1)', AppRoutes.productDetail, 1),
        ('Checkout', AppRoutes.checkout, null),
        ('Order Success (id 1)', AppRoutes.orderSuccess, 1),
        ('Order Detail (id 1)', AppRoutes.orderDetail, 1),
      ],
    ),
    (
      'Admin',
      [
        ('Admin Dashboard', AppRoutes.adminDashboard, null),
        ('Admin Products', AppRoutes.adminProducts, null),
        ('Product Form (thêm mới)', AppRoutes.adminProductForm, null),
        ('Product Form (sửa id 1)', AppRoutes.adminProductForm, 1),
      ],
    ),
    (
      'Debug',
      [
        ('Kiểm tra SQLite (số dòng mỗi bảng)', AppRoutes.dbCheck, null),
        (
          'Widget Catalog (mọi component dùng chung)',
          AppRoutes.widgetCatalog,
          null,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppLogo(size: 28)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              0,
            ),
            child: Text(
              'Menu dev — mở nhanh từng màn để test.',
              style: AppTextStyles.caption,
            ),
          ),
          for (final (title, items) in _sections) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xl,
                AppSpacing.screen,
                AppSpacing.sm,
              ),
              child: Text(title, style: AppTextStyles.subtitle),
            ),
            for (final (label, route, args) in items)
              ListTile(
                title: Text(label, style: AppTextStyles.body),
                subtitle: Text(route, style: AppTextStyles.caption),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.pushNamed(context, route, arguments: args),
              ),
          ],
        ],
      ),
    );
  }
}
