import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/change_password_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/states/loading_state.dart';
import '../auth/logout_action.dart';
import 'widgets/change_password_sheet.dart';
import 'widgets/edit_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showDevTools = kDebugMode});

  final bool showDevTools;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;

  /// Chặn mở hai sheet hoặc dialog khi bấm nhanh.
  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(User user) => _runAction(() async {
    final auth = context.read<AuthProvider>();
    auth.clearSaveErrors();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => EditProfileSheet(user: user),
    );
    if (!mounted) return;
    final saveError = auth.saveErrorMessage;
    auth.clearSaveErrors();
    final messenger = ScaffoldMessenger.of(context);
    if (!auth.isLoggedIn) {
      if (saveError != null) {
        messenger.showSnackBar(SnackBar(content: Text(saveError)));
      }
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } else if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu')));
    }
  });

  Future<void> _changePassword(User user) => _runAction(() async {
    final auth = context.read<AuthProvider>();
    final repository = context.read<AuthRepository>();
    final outcome = await showModalBottomSheet<ChangePasswordOutcome>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ChangePasswordProvider(repository, userId: user.id!),
        child: const ChangePasswordSheet(),
      ),
    );
    if (!mounted || outcome == null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (outcome == ChangePasswordOutcome.changed) {
      messenger.showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu')));
      return;
    }

    // Tài khoản đã bị xóa ở nơi khác nên phiên hiện tại không còn hợp lệ.
    final navigator = Navigator.of(context);
    await auth.logout();
    messenger.showSnackBar(
      const SnackBar(content: Text(AuthRepository.accountGoneMessage)),
    );
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  });

  Future<void> _logout() => _runAction(() => confirmAndLogout(context));

  Future<void> _reset() => _runAction(() async {
    final auth = context.read<AuthProvider>();
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Reset dữ liệu demo?',
      message: 'Dữ liệu trên thiết bị sẽ được thay bằng dữ liệu demo.',
      confirmLabel: 'Reset',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await auth.resetDemoData();
    final error = auth.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: auth.isLoading
          ? const LoadingState()
          : user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Chưa đăng nhập', style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Đăng nhập',
                      onPressed: _busy
                          ? null
                          : () {
                              auth.clearErrors();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (_) => false,
                              );
                            },
                    ),
                  ],
                ),
              ),
            )
          : _profile(user, auth),
    );
  }

  Widget _profile(User user, AuthProvider auth) {
    final createdAt = user.createdAt;
    final disabled = _busy || auth.isSaving;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Center(
          child: CircleAvatar(
            radius: AppSpacing.xxl,
            backgroundColor: AppColors.primarySoft,
            child: Text(user.initial, style: AppTextStyles.h1),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: AppTextStyles.h1,
        ),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(child: Chip(label: Text(user.role.label))),
        if (createdAt != null)
          Text(
            'Thành viên từ ${DateFormat('dd/MM/yyyy').format(createdAt.toLocal())}',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        const SizedBox(height: AppSpacing.section),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          children: [
            const Text('Thông tin cá nhân', style: AppTextStyles.h2),
            TextButton(
              onPressed: disabled ? null : () => _edit(user),
              child: const Text('Sửa'),
            ),
          ],
        ),
        ListTile(
          leading: const Icon(Icons.phone_outlined),
          title: const Text('Số điện thoại'),
          subtitle: Text(user.phone),
        ),
        ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Địa chỉ'),
          subtitle: Text(user.address ?? 'Chưa có địa chỉ'),
        ),
        ListTile(
          leading: const Icon(Icons.lock_reset_outlined),
          title: const Text('Đổi mật khẩu'),
          trailing: const Icon(Icons.chevron_right_rounded),
          enabled: !disabled,
          onTap: () => _changePassword(user),
        ),
        const Divider(),

        if (!user.isAdmin) ...[
          const SizedBox(height: AppSpacing.lg),

          _WishlistTile(enabled: !disabled),

          const SizedBox(height: AppSpacing.section),
          const Divider(),
        ],

        if (widget.showDevTools) ...[
          ListTile(
            leading: const Icon(Icons.developer_mode),
            title: const Text('Menu dev'),
            enabled: !disabled,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.devMenu),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset demo data'),
            enabled: !disabled,
            onTap: _reset,
          ),
        ],
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: Text(
            'Đăng xuất',
            style: AppTextStyles.body.copyWith(color: AppColors.error),
          ),
          enabled: !disabled,
          onTap: _logout,
        ),
      ],
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    return Card(
      color: AppColors.surface,
      child: ListTile(
        leading: const Icon(Icons.favorite_rounded, color: AppColors.error),
        title: const Text(
          'Xem danh sách yêu thích',
          style: AppTextStyles.subtitle,
        ),
        subtitle: Text(
          wishlist.status == ViewStatus.loading ||
                  wishlist.status == ViewStatus.initial
              ? 'Đang tải...'
              : '${wishlist.products.length} sản phẩm đã lưu',
          style: AppTextStyles.caption,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        enabled: enabled,
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.wishlist);
        },
      ),
    );
  }
}
