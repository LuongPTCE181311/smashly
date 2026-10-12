import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smashly/core/utils/currency_formatter.dart';

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
          Positioned.fill(
            child: Image.asset(
              'assets/images/banners/hero_astrox99.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) {
                return const ColoredBox(color: AppColors.midnight);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
                    CurrencyFormatter.format(product.price),
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
}
