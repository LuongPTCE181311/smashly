import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/buttons/primary_button.dart';

/// Thanh cố định đáy màn Giỏ hàng: tổng tiền các món đã chọn + nút Thanh toán.
class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({
    super.key,
    required this.total,
    required this.selectedCount,
    required this.hasUnavailable,
    required this.onCheckout,
  });

  final int total;
  final int selectedCount;

  /// Có món đang chọn hết hàng / vượt tồn kho.
  final bool hasUnavailable;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final canCheckout = selectedCount > 0 && !hasUnavailable;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasUnavailable)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Bỏ chọn hoặc giảm số lượng món hết hàng để thanh toán.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng cộng', style: AppTextStyles.caption),
                      Text(
                        CurrencyFormatter.format(total),
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  label: 'Thanh toán ($selectedCount)',
                  expanded: false,
                  height: AppSizes.ctaHeight,
                  onPressed: canCheckout ? onCheckout : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
