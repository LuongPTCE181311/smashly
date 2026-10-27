import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

/// Chỉ ADMIN thấy child; người khác về Login khi route đang ở trên cùng.
/// Không thay đổi session.
class AdminGuard extends StatefulWidget {
  const AdminGuard({super.key, required this.child});

  final Widget child;

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  bool _redirectScheduled = false;
  bool _redirected = false;

  void _scheduleRedirect() {
    if (_redirectScheduled || _redirected) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectScheduled = false;
      if (!mounted || _redirected) return;
      if (context.read<AuthProvider>().isAdmin ||
          ModalRoute.isCurrentOf(context) != true) {
        return;
      }
      _redirected = true;
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
