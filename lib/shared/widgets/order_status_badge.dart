import 'package:flutter/material.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

extension OrderStatusStyle on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Chờ xác nhận',
    OrderStatus.confirmed => 'Đã xác nhận',
    OrderStatus.shipping => 'Đang giao',
    OrderStatus.delivered => 'Đã giao',
    OrderStatus.cancelled => 'Đã hủy',
  };

  IconData get icon => switch (this) {
    OrderStatus.pending => Icons.schedule_rounded,
    OrderStatus.confirmed => Icons.check_circle_outline_rounded,
    OrderStatus.shipping => Icons.local_shipping_outlined,
    OrderStatus.delivered => Icons.inventory_2_outlined,
    OrderStatus.cancelled => Icons.cancel_outlined,
  };

  Color get color => switch (this) {
    OrderStatus.pending => AppColors.warning,
    OrderStatus.confirmed => AppColors.info,
    OrderStatus.shipping => AppColors.violet,
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.error,
  };

  Color get softColor => switch (this) {
    OrderStatus.pending => AppColors.warningSoft,
    OrderStatus.confirmed => AppColors.infoSoft,
    OrderStatus.shipping => AppColors.violetSoft,
    OrderStatus.delivered => AppColors.successSoft,
    OrderStatus.cancelled => AppColors.errorSoft,
  };
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: AppTextStyles.caption.copyWith(color: status.color),
          ),
        ],
      ),
    );
  }
}
