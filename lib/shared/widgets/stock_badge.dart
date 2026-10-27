import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock});

  static const lowStockThreshold = 5;

  final int stock;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, background) = switch (stock) {
      <= 0 => (
        'Hết hàng',
        Icons.remove_shopping_cart_outlined,
        AppColors.inkMuted,
        AppColors.productTile,
      ),
      <= lowStockThreshold => (
        'Chỉ còn $stock',
        Icons.warning_amber_rounded,
        AppColors.warning,
        AppColors.warningSoft,
      ),
      _ => (
        'Còn hàng',
        Icons.check_circle_rounded,
        AppColors.success,
        AppColors.successSoft,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}
