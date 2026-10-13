import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/price_text.dart';
import '../../../shared/widgets/rating_view.dart';
import '../../../shared/widgets/stock_badge.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.brand.toUpperCase(), style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(product.name, style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.md),
        PriceText(
          price: product.price,
          originalPrice: product.originalPrice,
          style: AppTextStyles.priceLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            RatingView(rating: product.rating, count: product.ratingCount),
            const Spacer(),
            StockBadge(stock: product.stock),
          ],
        ),
      ],
    );
  }
}
