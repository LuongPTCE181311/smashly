import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Chỉ ADMIN thấy [child]; người khác được đưa về Login (không đổi session) khi route đang ở trên cùng.
class AdminGuard extends StatefulWidget {
  const AdminGuard({super.key, required this.child});

  final Widget child;

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  // Bật ngay khi hẹn để nhiều lần build trong một frame chỉ push Login một lần.
  bool _redirected = false;

  void _scheduleRedirect() {
    if (_redirected) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().isAdmin ||
          ModalRoute.isCurrentOf(context) != true) {
        // Hủy lần này để guard hẹn lại khi route lộ ra hoặc quyền đổi.
        _redirected = false;
        return;
      }
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final isCurrent = ModalRoute.isCurrentOf(context) == true;
    if (isAdmin) return widget.child;
    if (isCurrent) _scheduleRedirect();
    return const Scaffold();
  }
}
