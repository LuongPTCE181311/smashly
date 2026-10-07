import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../buttons/primary_button.dart';

/// Trạng thái "không có dữ liệu": minh họa + tiêu đề + câu giải thích + CTA.
///
/// ```dart
/// EmptyState(
///   icon: Icons.shopping_bag_outlined,
///   title: 'Giỏ hàng đang trống',
///   message: 'Giỏ hàng đang chờ một món thật xịn.',
///   actionLabel: 'Khám phá sản phẩm',
///   onAction: () => AppShell.goToTab(context, AppTab.shop),
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.imagePath,
    this.actionLabel,
    this.onAction,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySoft,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// Ảnh minh họa trong `assets/images/states/`; thiếu ảnh thì dùng [icon].
  final String? imagePath;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final iconBadge = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
      child: Icon(icon, size: 44, color: iconColor),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath == null)
              iconBadge
            else
              Image.asset(
                imagePath!,
                height: 160,
                errorBuilder: (_, _, _) => iconBadge,
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
