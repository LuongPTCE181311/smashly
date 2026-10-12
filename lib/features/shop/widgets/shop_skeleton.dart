import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ShopSkeleton extends StatelessWidget {
  const ShopSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.60,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Khung ảnh sản phẩm.
              const Expanded(
                child: ColoredBox(
                  color: AppColors.productTile,
                  child: SizedBox(width: double.infinity),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(60),
                    const SizedBox(height: AppSpacing.sm),
                    _line(double.infinity),
                    const SizedBox(height: AppSpacing.sm),
                    _line(100),
                    const SizedBox(height: AppSpacing.sm),
                    _line(85),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _line(double width) {
    return Container(
      width: width,
      height: 12,
      decoration: const BoxDecoration(
        color: AppColors.productTile,
        borderRadius: AppRadius.smAll,
      ),
    );
  }
}
