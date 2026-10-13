import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product.dart';

class ProductImageHeader extends StatelessWidget {
  const ProductImageHeader({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.45;

    return SliverAppBar(
      pinned: true,
      expandedHeight: height,
      backgroundColor: AppColors.productTile,
      surfaceTintColor: Colors.transparent,
      leading: const Padding(
        padding: EdgeInsets.all(AppSpacing.xs),
        child: _CircleBackButton(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  kToolbarHeight,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: Image.asset(
                  product.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.sports_tennis_rounded,
                    size: 96,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              if (product.hasDiscount)
                Positioned(
                  left: AppSpacing.screen,
                  bottom: AppSpacing.lg,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.midnight,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      '-${product.discountPercent}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentVolt,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Quay lại',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
