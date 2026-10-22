import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smashly/providers/wishlist_provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

import '../../data/models/category.dart';
import '../../data/models/product_query.dart';

import '../../providers/shop_provider.dart';
import '../../routes/app_routes.dart';

import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';

import 'widgets/shop_skeleton.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Quản lý nội dung TextField.
  final TextEditingController _searchController = TextEditingController();

  // Quản lý focus của ô search.
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Tiêu đề và ô tìm kiếm.
            _buildHeader(),

            // Danh mục cuộn ngang.
            _buildCategories(shop),

            // Số kết quả và sort.
            _buildToolbar(shop),

            // Nội dung thay đổi theo status.
            Expanded(child: _buildBody(shop)),
          ],
        ),
      ),
    );
  }

  // ==============================
  // HEADER
  // ==============================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cửa hàng', style: AppTextStyles.h1),

          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,

            // Gọi Provider mỗi khi nhập.
            onChanged: (value) {
              context.read<ShopProvider>().setKeyword(value);

              // Cập nhật nút X khi nhập.
              setState(() {});
            },

            textInputAction: TextInputAction.search,

            onSubmitted: (_) {
              _searchFocusNode.unfocus();

              // Tìm ngay khi nhấn Search.
              context.read<ShopProvider>().refresh();
            },

            decoration: InputDecoration(
              hintText: 'Tìm vợt, giày, phụ kiện...',

              prefixIcon: const Icon(Icons.search_rounded),

              // Nút X chỉ hiện khi có chữ.
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _clearSearch,
                    )
                  : null,

              filled: true,
              fillColor: AppColors.surface,

              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(color: AppColors.border),
              ),

              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(color: AppColors.accentVolt, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // CLEAR SEARCH
  // ==============================

  void _clearSearch() {
    _searchController.clear();

    context.read<ShopProvider>().setKeyword('');

    // Làm mới icon X.
    setState(() {});

    // Không gọi loadProducts ngay:
    // Provider tự debounce 300ms.
  }

  // ==============================
  // CATEGORY CHIPS
  // ==============================

  Widget _buildCategories(ShopProvider shop) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: [
          _categoryChip(
            label: 'Tất cả',
            categoryId: null,
            selected: shop.query.categoryId == null,
          ),

          for (final category in shop.categories)
            _categoryChip(
              label: _categoryName(category),
              categoryId: category.id,
              selected: shop.query.categoryId == category.id,
            ),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required int? categoryId,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,

        onSelected: (_) {
          _searchFocusNode.unfocus();

          context.read<ShopProvider>().selectCategory(categoryId);
        },

        selectedColor: AppColors.accentVolt,

        backgroundColor: AppColors.surface,

        labelStyle: AppTextStyles.caption.copyWith(
          color: selected ? AppColors.midnight : AppColors.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),

        showCheckmark: selected,
        checkmarkColor: AppColors.midnight,

        side: BorderSide(
          color: selected ? AppColors.accentVolt : AppColors.border,
        ),

        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
    );
  }

  String _categoryName(Category category) {
    return switch (category.name) {
      'Rackets' => 'Vợt',
      'Shoes' => 'Giày',
      'Shirts' => 'Áo',
      'Shorts' => 'Quần',
      'Socks' => 'Tất',
      'Bags' => 'Túi',
      'Grips' => 'Quấn cán',
      'Strings' => 'Cước',
      'Nets' => 'Lưới',
      'Accessories' => 'Phụ kiện',
      _ => category.name,
    };
  }

  // ==============================
  // RESULT COUNT + SORT
  // ==============================

  Widget _buildToolbar(ShopProvider shop) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${shop.resultCount} sản phẩm',
              style: AppTextStyles.body,
            ),
          ),

          PopupMenuButton<ProductSort>(
            tooltip: 'Sắp xếp sản phẩm',
            initialValue: shop.query.sort,

            onSelected: (sort) {
              context.read<ShopProvider>().changeSort(sort);
            },

            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ProductSort.popular,
                child: Text('Phổ biến'),
              ),
              const PopupMenuItem(
                value: ProductSort.priceAscending,
                child: Text('Giá tăng dần'),
              ),
              const PopupMenuItem(
                value: ProductSort.priceDescending,
                child: Text('Giá giảm dần'),
              ),
              const PopupMenuItem(
                value: ProductSort.ratingDescending,
                child: Text('Đánh giá cao'),
              ),
            ],

            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded, color: AppColors.inkMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _sortLabel(shop.query.sort),
                    style: AppTextStyles.caption,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(ProductSort sort) {
    return switch (sort) {
      ProductSort.popular => 'Phổ biến',
      ProductSort.priceAscending => 'Giá tăng',
      ProductSort.priceDescending => 'Giá giảm',
      ProductSort.ratingDescending => 'Đánh giá',
    };
  }

  // ==============================
  // BODY: 4 TRẠNG THÁI
  // ==============================

  Widget _buildBody(ShopProvider shop) {
    return switch (shop.status) {
      ViewStatus.initial || ViewStatus.loading => const ShopSkeleton(),

      ViewStatus.error => ErrorState(
        message: shop.errorMessage,
        onRetry: () {
          context.read<ShopProvider>().refresh();
        },
      ),

      ViewStatus.empty => EmptyState(
        icon: Icons.search_off_rounded,
        iconColor: AppColors.accentVolt,
        iconBackground: AppColors.primarySoft,
        title: 'Không tìm thấy sản phẩm',
        message: 'Thử từ khóa khác hoặc bỏ bớt bộ lọc.',
        actionLabel: 'Xóa bộ lọc',
        onAction: () {
          _searchController.clear();
          setState(() {});

          context.read<ShopProvider>().resetFilters();
        },
      ),

      ViewStatus.success => _buildProductGrid(shop),
    };
  }

  // ==============================
  // PRODUCT GRID
  // ==============================

  Widget _buildProductGrid(ShopProvider shop) {
    final wishlist = context.watch<WishlistProvider>();

    return RefreshIndicator(
      onRefresh: context.read<ShopProvider>().refresh,
      child: GridView.builder(
        key: const PageStorageKey('shop-product-grid'),
        padding: const EdgeInsets.all(AppSpacing.screen),
        itemCount: shop.products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.60,
        ),

        itemBuilder: (context, index) {
          final product = shop.products[index];
          return ProductCard(
            product: product,
            isFavorite: wishlist.isFavorite(product.id),
            isWishlistLoading: wishlist.isPending(product.id),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.productDetail,
                arguments: product.id,
              );
            },
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
