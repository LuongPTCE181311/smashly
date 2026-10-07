import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../shared/widgets/app_logo.dart';
import 'app_routes.dart';

/// MÀN DEV: mở nhanh mọi route để test khi chưa có luồng Splash → Login.
/// Tạm đứng ở vị trí Splash; khi Hào làm xong Splash vẫn mở được qua
/// `AppRoutes.devMenu`. Không đưa vào demo.
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  static const _sections = <(String, List<(String, String, Object?)>)>[
    (
      'Auth · Hào',
      [
        ('S02 · Login', AppRoutes.login, null),
        ('S03 · Register', AppRoutes.register, null),
      ],
    ),
    (
      'Customer (mở AppShell ở tab tương ứng)',
      [
        ('S04 · Home', AppRoutes.home, null),
        ('S05 · Shop', AppRoutes.shop, null),
        ('S07 · Cart', AppRoutes.cart, null),
        ('S10 · My Orders', AppRoutes.myOrders, null),
        ('S12 · Profile', AppRoutes.profile, null),
      ],
    ),
    (
      'Màn đẩy lên trên AppShell',
      [
        ('S06 · Product Detail (id 1)', AppRoutes.productDetail, 1),
        ('S08 · Checkout', AppRoutes.checkout, null),
        ('S09 · Order Success (id 1)', AppRoutes.orderSuccess, 1),
        ('S11 · Order Detail (id 1)', AppRoutes.orderDetail, 1),
      ],
    ),
    (
      'Admin · Trọng',
      [
        ('S13 · Admin Dashboard', AppRoutes.adminDashboard, null),
        ('S14 · Admin Products', AppRoutes.adminProducts, null),
        ('S15 · Product Form (thêm mới)', AppRoutes.adminProductForm, null),
        ('S15 · Product Form (sửa id 1)', AppRoutes.adminProductForm, 1),
      ],
    ),
    (
      'Debug',
      [('Kiểm tra SQLite (số dòng mỗi bảng)', AppRoutes.dbCheck, null)],
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
