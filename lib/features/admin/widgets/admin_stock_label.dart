import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/stock_badge.dart';

/// Tồn kho cho admin (blueprint mục 15): "Kho: 12" · "3 · Sắp hết" · "0 · Hết".
///
/// Luôn có số + chữ + icon, màu chỉ để nhấn mạnh — không đọc được màu vẫn
/// hiểu. Khác [StockBadge] (chữ cho khách: "Còn hàng", "Chỉ còn 3").
class AdminStockLabel extends StatelessWidget {
  const AdminStockLabel({super.key, required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, background) = switch (stock) {
      <= 0 => (
        '0 · Hết',
        Icons.block_rounded,
        AppColors.error,
        AppColors.errorSoft,
      ),
      <= StockBadge.lowStockThreshold => (
        '$stock · Sắp hết',
        Icons.warning_amber_rounded,
        AppColors.warning,
        AppColors.warningSoft,
      ),
      _ => (
        'Kho: $stock',
        Icons.check_circle_outline_rounded,
        AppColors.success,
        AppColors.successSoft,
      ),
    };

    return _AdminLabel(
      label: label,
      icon: icon,
      color: color,
      background: background,
    );
  }
}

/// Nhãn "Đang ẩn" cho sản phẩm có `is_active = 0`.
class AdminHiddenLabel extends StatelessWidget {
  const AdminHiddenLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminLabel(
      label: 'Đang ẩn',
      icon: Icons.visibility_off_outlined,
      color: AppColors.inkMuted,
      background: AppColors.productTile,
    );
  }
}

class _AdminLabel extends StatelessWidget {
  const _AdminLabel({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
