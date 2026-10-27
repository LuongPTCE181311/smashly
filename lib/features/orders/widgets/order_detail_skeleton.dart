import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  static const _cardHeights = [72.0, 220.0, 96.0, 140.0];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải chi tiết đơn hàng',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        itemCount: _cardHeights.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, index) => Container(
          height: _cardHeights[index],
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          alignment: Alignment.topLeft,
          child: Container(
            width: 140,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.border,
              borderRadius: AppRadius.smAll,
            ),
          ),
        ),
      ),
    );
  }
}
