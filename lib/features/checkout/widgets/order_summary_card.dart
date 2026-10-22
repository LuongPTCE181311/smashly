import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item.dart';

/// Tóm tắt đơn: từng món đã chọn, tạm tính, phí ship (miễn phí từ 1.000.000₫)
/// và tổng cộng.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
  });

  final List<CartItem> items;
  final int subtotal;
  final int shippingFee;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                      Text(
                        [
                          if (item.size.isNotEmpty) 'Size ${item.size}',
                          'x${item.quantity}',
                        ].join(' · '),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  CurrencyFormatter.format(item.lineTotal),
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        const Divider(height: AppSpacing.lg),
        _row('Tạm tính', CurrencyFormatter.format(subtotal)),
        const SizedBox(height: AppSpacing.sm),
        _row(
          'Phí vận chuyển',
          shippingFee == 0 ? 'Miễn phí' : CurrencyFormatter.format(shippingFee),
          valueColor: shippingFee == 0 ? AppColors.success : null,
        ),
        const Divider(height: AppSpacing.xl),
        Row(
          children: [
            const Expanded(
              child: Text('Tổng cộng', style: AppTextStyles.subtitle),
            ),
            Text(CurrencyFormatter.format(total), style: AppTextStyles.price),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Row(
    children: [
      Expanded(child: Text(label, style: AppTextStyles.body)),
      Text(value, style: AppTextStyles.body.copyWith(color: valueColor)),
    ],
  );
}
