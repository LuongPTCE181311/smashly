import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product_detail.dart';

class ProductHighlights extends StatelessWidget {
  const ProductHighlights({super.key, required this.detail});

  final ProductDetail detail;

  List<String> get _items {
    final sizes = detail.sizes;
    return [
      'Hàng chính hãng ${detail.product.brand}',
      if (sizes.isNotEmpty)
        'Có ${sizes.length} size: ${sizes.first} – ${sizes.last}',
      'Miễn phí vận chuyển cho đơn từ 1.000.000₫',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Điểm nổi bật', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.md),
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item, style: AppTextStyles.body)),
              ],
            ),
          ),
      ],
    );
  }
}
