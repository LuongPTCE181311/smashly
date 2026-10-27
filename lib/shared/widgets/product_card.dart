import 'package:flutter/material.dart';
import 'package:smashly/core/theme/app_motion.dart';
import 'package:smashly/core/utils/currency_formatter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onWishlistTap,
    this.isFavorite = false,
    this.isWishlistLoading = false,
    this.heroTag,
  });

  static String heroTagFor(int productId) => 'product-$productId';

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onWishlistTap;
  final bool isFavorite;
  final bool isWishlistLoading;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.productTile,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _withHero(
                        Image.asset(
                          product.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.sports_tennis_rounded,
                            size: 56,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (product.hasDiscount)
                    Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
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

                  if (onWishlistTap != null)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: IconButton(
                        tooltip: isFavorite
                            ? 'Bỏ khỏi yêu thích'
                            : 'Thêm vào yêu thích',
                        onPressed: isWishlistLoading ? null : onWishlistTap,
                        icon: AnimatedSwitcher(
                          duration: AppMotion.normal,
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(isFavorite),
                            color: isFavorite
                                ? AppColors.error
                                : AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: AppTextStyles.caption,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating} (${product.ratingCount})',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    CurrencyFormatter.format(product.price),
                    style: AppTextStyles.priceSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _withHero(Widget child) {
    final tag = heroTag;
    if (tag == null) return child;
    return Hero(tag: tag, child: child);
  }
}
