import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Semantics(
      label: 'Đang tải sản phẩm',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          Container(height: imageHeight, color: AppColors.productTile),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: 72, height: 12),
                const SizedBox(height: AppSpacing.sm),
                _block(width: double.infinity, height: 24),
                const SizedBox(height: AppSpacing.sm),
                _block(width: 180, height: 24),
                const SizedBox(height: AppSpacing.lg),
                _block(width: 140, height: 28),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(child: _block(height: 96)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _block(height: 96)),
                  ],
                ),
              ],
            ),
          ),
        ],
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
