import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/repositories/cart_repository.dart';
import 'cart_open_area.dart';
import 'quantity_stepper.dart';

int cartMaxQuantity(CartItem item) =>
    math.min(item.stock, CartRepository.maxQuantityPerLine);

String? cartStockWarning(CartItem item) {
  if (item.stock <= 0) return 'Đã hết hàng';
  if (item.quantity > item.stock) return 'Chỉ còn ${item.stock} sản phẩm';
  return null;
}

/// Sold-out line (stock 0): image, name, price and stepper are dimmed; the
/// checkbox and the warning stay clear so it can be unticked and explained.
bool cartIsSoldOut(CartItem item) => item.stock <= 0;

const cartSoldOutOpacity = 0.5;

Widget cartDimmed({required bool dim, required Widget child}) =>
    dim ? Opacity(opacity: cartSoldOutOpacity, child: child) : child;

/// One cart line: checkbox, image, name, size, price, quantity stepper.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDecrease,
    required this.onIncrease,
    this.onSetQuantity,
    this.onOpen,
  });

  final CartItem item;
  final VoidCallback onToggle;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  final ValueChanged<int>? onSetQuantity;

  /// Tap the image / name / price to open the product detail.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final maxQuantity = cartMaxQuantity(item);
    final warning = cartStockWarning(item);
    final soldOut = cartIsSoldOut(item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      // Transparent Material over the Container background so the ripple shows.
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.isSelected,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            CartOpenArea(
              onOpen: onOpen,
              child: cartDimmed(
                dim: soldOut,
                child: CartThumbnail(path: item.imagePath),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CartOpenArea(
                    onOpen: onOpen,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cartDimmed(
                            dim: soldOut,
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.subtitle,
                                  ),
                                  if (item.size.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Size: ${item.size}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    CurrencyFormatter.format(item.price),
                                    style: AppTextStyles.priceSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (warning != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  warning,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: cartDimmed(
                      dim: soldOut,
                      child: QuantityStepper(
                        quantity: item.quantity,
                        onDecrease: item.quantity > 1 ? onDecrease : null,
                        onIncrease: item.quantity < maxQuantity
                            ? onIncrease
                            : null,
                        max: maxQuantity,
                        onQuantityChanged: onSetQuantity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartThumbnail extends StatelessWidget {
  const CartThumbnail({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.productTile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}
