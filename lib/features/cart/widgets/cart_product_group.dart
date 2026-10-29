import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item.dart';
import 'cart_item_tile.dart';
import 'cart_open_area.dart';
import 'quantity_stepper.dart';

class CartProductGroup extends StatelessWidget {
  const CartProductGroup({
    super.key,
    required this.items,
    required this.onToggleGroup,
    required this.onToggle,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSetQuantity,
    required this.onRemove,
    this.onOpen,
  });

  /// Tap the image / name / price in the card header to open the product detail.
  final VoidCallback? onOpen;
  final List<CartItem> items;
  final ValueChanged<bool> onToggleGroup;
  final ValueChanged<CartItem> onToggle;
  final ValueChanged<CartItem> onDecrease;
  final ValueChanged<CartItem> onIncrease;
  final void Function(CartItem item, int quantity) onSetQuantity;
  final ValueChanged<CartItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final first = items.first;
    // Stock is per product, so every size sells out at the same time.
    final soldOut = cartIsSoldOut(first);
    final selectedCount = items.where((i) => i.isSelected).length;
    final groupValue = selectedCount == items.length
        ? true
        : selectedCount == 0
        ? false
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transparent Material over the card background so the ripple shows.
          Material(
            type: MaterialType.transparency,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: groupValue,
                  tristate: true,
                  onChanged: (_) => onToggleGroup(groupValue != true),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
                CartOpenArea(
                  onOpen: onOpen,
                  child: cartDimmed(
                    dim: soldOut,
                    child: CartThumbnail(path: first.imagePath),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CartOpenArea(
                    onOpen: onOpen,
                    child: cartDimmed(
                      dim: soldOut,
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              first.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${items.length} size trong giỏ',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              CurrencyFormatter.format(first.price),
                              style: AppTextStyles.priceSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xl),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _VariantRow(
              item: items[i],
              onToggle: () => onToggle(items[i]),
              onDecrease: () => onDecrease(items[i]),
              onIncrease: () => onIncrease(items[i]),
              onSetQuantity: (quantity) => onSetQuantity(items[i], quantity),
              onRemove: () => onRemove(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.item,
    required this.onToggle,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSetQuantity,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onToggle;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<int> onSetQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final maxQuantity = cartMaxQuantity(item);
    final warning = cartStockWarning(item);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      movementDuration: AppMotion.of(context, AppMotion.normal),
      resizeDuration: AppMotion.of(context, AppMotion.normal),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.mdAll,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.onDark,
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: ColoredBox(
        color: AppColors.surface,
        child: Row(
          children: [
            Checkbox(
              value: item.isSelected,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cartDimmed(
                    dim: cartIsSoldOut(item),
                    child: Text(
                      'Size: ${item.size}',
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                  if (warning != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            warning,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            cartDimmed(
              dim: cartIsSoldOut(item),
              child: QuantityStepper(
                quantity: item.quantity,
                onDecrease: item.quantity > 1 ? onDecrease : null,
                onIncrease: item.quantity < maxQuantity ? onIncrease : null,
                max: maxQuantity,
                onQuantityChanged: onSetQuantity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
