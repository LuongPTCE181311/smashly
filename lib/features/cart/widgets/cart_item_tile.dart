import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item.dart';
import 'quantity_stepper.dart';

/// Một dòng giỏ hàng: ô chọn, ảnh, tên, size, giá, stepper số lượng.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CartItem item;
  final VoidCallback onToggle;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final soldOut = item.stock <= 0;
    final overStock = !soldOut && item.quantity > item.stock;
    final warning = soldOut
        ? 'Đã hết hàng'
        : overStock
        ? 'Chỉ còn ${item.stock} sản phẩm'
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isSelected,
            onChanged: (_) => onToggle(),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
          _Thumbnail(path: item.imagePath),
          const SizedBox(width: AppSpacing.md),
          Expanded(
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
                  Text('Size: ${item.size}', style: AppTextStyles.caption),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CurrencyFormatter.format(item.price),
                  style: AppTextStyles.priceSmall,
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
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: QuantityStepper(
                    quantity: item.quantity,
                    onDecrease: item.quantity > 1 ? onDecrease : null,
                    onIncrease: item.quantity < item.stock ? onIncrease : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

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
