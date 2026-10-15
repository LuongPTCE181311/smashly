import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/order_item.dart';

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({super.key, required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: const BoxDecoration(
            color: AppColors.productTile,
            borderRadius: AppRadius.mdAll,
          ),
          child: Image.asset(
            item.productImage,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.sports_tennis_rounded,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: AppTextStyles.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.size.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Size ${item.size}', style: AppTextStyles.caption),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          CurrencyFormatter.format(item.lineTotal),
          style: AppTextStyles.priceSmall.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}
