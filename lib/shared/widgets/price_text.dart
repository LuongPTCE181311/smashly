import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';

class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    this.originalPrice,
    this.style,
  });

  final int price;
  final int? originalPrice;
  final TextStyle? style;

  bool get _hasDiscount => originalPrice != null && originalPrice! > price;

  int get _discountPercent =>
      (((originalPrice! - price) / originalPrice!) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          CurrencyFormatter.format(price),
          style: style ?? AppTextStyles.price,
        ),
        if (_hasDiscount) ...[
          Text(
            CurrencyFormatter.format(originalPrice!),
            style: AppTextStyles.caption.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: const BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: AppRadius.smAll,
            ),
            child: Text(
              '-$_discountPercent%',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
