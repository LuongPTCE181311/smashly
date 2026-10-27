import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smashly/providers/wishlist_provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/product.dart';
import '../../../shared/widgets/product_card.dart';

class HomeTrendingSection extends StatelessWidget {
  const HomeTrendingSection({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;
  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    return GridView.builder(
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (context, index) {
        final product = products[index];

        return ProductCard(
          product: product,
          heroTag: ProductCard.heroTagFor(product.id),
          onTap: () => onProductTap(product),
          isFavorite: wishlist.isFavorite(product.id),
          isWishlistLoading: wishlist.isPending(product.id),
          onWishlistTap: () async {
            final provider = context.read<WishlistProvider>();
            final success = await provider.toggleFavorite(product.id);
            if (!context.mounted) return;
            if (!success && provider.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
            }
          },
        );
      },
    );
  }
}
