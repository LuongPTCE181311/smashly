import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/wishlist_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../../shared/widgets/states/loading_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text('Danh sách yêu thích')),

      body: switch (wishlist.status) {
        ViewStatus.initial || ViewStatus.loading => const LoadingState(),

        ViewStatus.error => ErrorState(
          message: wishlist.errorMessage,
          onRetry: () {
            context.read<WishlistProvider>().load();
          },
        ),

        ViewStatus.empty => _buildEmpty(context),

        ViewStatus.success =>
          wishlist.products.isEmpty
              ? _buildEmpty(context)
              : _buildProductGrid(context, wishlist),
      },
    );
  }

  // Trạng thái chưa có sản phẩm yêu thích.
  Widget _buildEmpty(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_border_rounded,
      title: 'Chưa có sản phẩm yêu thích',
      message:
          'Hãy nhấn biểu tượng trái tim trên sản phẩm '
          'để lưu những món đồ bạn yêu thích.',
      actionLabel: 'Khám phá sản phẩm',
      onAction: () {
        AppShell.goToTab(context, AppTab.shop);
      },
    );
  }

  // Hiển thị tất cả sản phẩm yêu thích.
  Widget _buildProductGrid(BuildContext context, WishlistProvider wishlist) {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<WishlistProvider>().load();
      },

      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.screen),

        itemCount: wishlist.products.length,

        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.58,
        ),

        itemBuilder: (context, index) {
          final product = wishlist.products[index];

          return ProductCard(
            product: product,

            isFavorite: wishlist.isFavorite(product.id),

            isWishlistLoading: wishlist.isPending(product.id),

            // Nhấn vào card để xem chi tiết.
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.productDetail,
                arguments: product.id,
              );
            },

            // Nhấn tim để bỏ yêu thích.
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
      ),
    );
  }
}
