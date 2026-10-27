import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Dialog xác nhận dùng chung. Nút hành động nằm bên phải; hành động nguy
/// hiểm (`destructive: true`) tô đỏ.
///
/// Gọi qua [AppDialog.confirm], trả về `true` khi người dùng bấm xác nhận,
/// `false` khi bấm Hủy, bấm ra ngoài hoặc Back:
///
/// ```dart
/// final ok = await AppDialog.confirm(
///   context,
///   title: 'Đăng xuất?',
///   message: 'Bạn sẽ cần đăng nhập lại để tiếp tục mua sắm.',
///   confirmLabel: 'Đăng xuất',
///   destructive: true,
/// );
/// if (!ok || !context.mounted) return;
/// ```
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Đồng ý',
    this.cancelLabel = 'Hủy',
    this.destructive = false,
    this.icon,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  /// Icon trên tiêu đề (vd. `Icons.logout_rounded`, `Icons.delete_outline`).
  final IconData? icon;

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Đồng ý',
    String cancelLabel = 'Hủy',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.primary;

    return AlertDialog(
      icon: icon == null ? null : Icon(icon, color: accent, size: 32),
      title: Text(title, textAlign: icon == null ? null : TextAlign.center),
      content: message == null
          ? null
          : Text(
              message!,
              style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
            ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            minimumSize: const Size(96, AppSizes.minTouchTarget),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
