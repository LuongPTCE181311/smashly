import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/app_dialog.dart';

/// Xác nhận và đăng xuất dùng chung cho Hồ sơ khách và Dashboard admin.
Future<void> confirmAndLogout(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final confirmed = await AppDialog.confirm(
    context,
    title: 'Đăng xuất?',
    message: 'Bạn có muốn đăng xuất khỏi tài khoản này?',
    confirmLabel: 'Đăng xuất',
    destructive: true,
  );
  if (!context.mounted || !confirmed) return;
  await auth.logout();
  if (!context.mounted) return;
  if (auth.status == ViewStatus.empty) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.errorMessage ?? 'Không thể đăng xuất lúc này'),
      ),
    );
  }
}
