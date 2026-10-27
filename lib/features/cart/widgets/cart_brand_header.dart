import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/cart_item.dart';

class CartBrandHeader extends StatelessWidget {
  const CartBrandHeader({
    super.key,
    required this.brand,
    required this.items,
    required this.onToggle,
  });

  final String brand;
  final List<CartItem> items;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final selectedCount = items.where((i) => i.isSelected).length;
    final value = selectedCount == items.length
        ? true
        : selectedCount == 0
        ? false
        : null;

    return Row(
      children: [
        Checkbox(
          value: value,
          tristate: true,
          onChanged: (_) => onToggle(value != true),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
        const Icon(Icons.storefront_outlined, size: 20, color: AppColors.ink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle,
          ),
        ),
      ],
    );
  }
}
