import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: AppRadius.xlAll,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -20,
            width: 190,
            height: 210,
            child: Image.asset(
              product.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.sports_tennis_rounded,
                  size: 120,
                  color: AppColors.onDarkMuted,
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: SizedBox(
              width: 190,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentVolt,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      'FEATURED',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.midnight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.onDark,
                      fontSize: 26,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    _formatPrice(product.price),
                    style: AppTextStyles.price.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  FilledButton(onPressed: onTap, child: const Text('Khám phá')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    final value = price.toString();

    return '${value.replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (_) => '.')}₫';
  }
}
