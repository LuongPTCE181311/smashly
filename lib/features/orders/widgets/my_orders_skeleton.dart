import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class MyOrdersSkeleton extends StatelessWidget {
  const MyOrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải đơn hàng',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _block(width: 160, height: 16),
                  const Spacer(),
                  _block(width: 88, height: 24),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _block(width: 120, height: 12),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _block(width: 56, height: 56),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _block(height: 14)),
                  const SizedBox(width: AppSpacing.md),
                  _block(width: 80, height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.border,
        borderRadius: AppRadius.smAll,
      ),
    );
  }
}
