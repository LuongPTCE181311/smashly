import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card.dart';

class HomeFeaturedSection extends StatelessWidget {
  const HomeFeaturedSection({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final product = products[index];

          return SizedBox(
            width: 190,
            child: ProductCard(
              product: product,
              onTap: () => onProductTap(product),
            ),
          );
        },
      ),
    );
  }
}
