import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/order_summary.dart';
import '../../../shared/widgets/buttons/pressable_scale.dart';
import '../../../shared/widgets/order_status_badge.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.summary, required this.onTap});

  final OrderSummary summary;
  final VoidCallback onTap;

  String get _itemsLabel {
    final first = summary.firstItem;
    if (first == null) return 'Không có sản phẩm';
    final others = summary.otherItemCount;
    if (others > 0) return '${first.productName} và $others sản phẩm khác';
    return first.productName;
  }

  @override
  Widget build(BuildContext context) {
    final order = summary.order;
    final first = summary.firstItem;

    return PressableScale(
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.orderCode, style: AppTextStyles.subtitle),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            DateFormatter.dateTime(order.createdAt),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: const BoxDecoration(
                        color: AppColors.productTile,
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: first == null
                          ? const Icon(
                              Icons.receipt_long_outlined,
                              color: AppColors.inkMuted,
                            )
                          : Image.asset(
                              first.productImage,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.sports_tennis_rounded,
                                color: AppColors.inkMuted,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _itemsLabel,
                        style: AppTextStyles.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Tổng tiền', style: AppTextStyles.caption),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          CurrencyFormatter.format(order.total),
                          style: AppTextStyles.priceSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
