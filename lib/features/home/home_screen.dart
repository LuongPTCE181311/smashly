import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/home_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/category_card.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import 'widgets/brand_tile.dart';
import 'widgets/hero_banner.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/play_style_section.dart';
import 'widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (home.status) {
          ViewStatus.initial || ViewStatus.loading => const HomeSkeleton(),

          ViewStatus.error => ErrorState(
            message: home.errorMessage,
            onRetry: () {
              context.read<HomeProvider>().loadHome(force: true);
            },
          ),

          ViewStatus.empty => EmptyState(
            icon: Icons.sports_tennis_rounded,
            title: 'Chưa có sản phẩm',
            message: 'Danh mục sản phẩm đang được cập nhật.',
            actionLabel: 'Tải lại',
            onAction: () {
              context.read<HomeProvider>().loadHome(force: true);
            },
          ),

          ViewStatus.success => _HomeContent(home: home),
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.home});

  final HomeProvider home;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<HomeProvider>().refresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _header(context),

                const SizedBox(height: AppSpacing.lg),

                _search(context),

                if (home.heroProduct != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  HeroBanner(
                    product: home.heroProduct!,
                    onTap: () => _openProduct(context, home.heroProduct!.id),
                  ),
                ],

                const SizedBox(height: AppSpacing.section),

                SectionHeader(
                  title: 'Danh mục',
                  actionLabel: 'Xem tất cả',
                  onAction: () => AppShell.goToTab(context, AppTab.shop),
                ),

                const SizedBox(height: AppSpacing.md),

                _categories(context),

                const SizedBox(height: AppSpacing.section),

                const SectionHeader(title: 'Shop by Play Style'),

                const SizedBox(height: AppSpacing.md),

                PlayStyleSection(
                  onSelected: (style) {
                    // Khi ShopProvider có ProductQuery:
                    // mở Shop với initialQuery.playStyle = style.
                    AppShell.goToTab(context, AppTab.shop);
                  },
                ),

                if (home.featuredProducts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.section),

                  SectionHeader(
                    title: 'Featured Rackets',
                    actionLabel: 'Xem tất cả',
                    onAction: () => AppShell.goToTab(context, AppTab.shop),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _featured(context),
                ],

                if (home.brands.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.section),

                  const SectionHeader(title: 'Top Brands'),

                  const SizedBox(height: AppSpacing.md),

                  _brands(context),
                ],

                if (home.trendingProducts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.section),

                  const SectionHeader(title: 'Trending Now'),

                  const SizedBox(height: AppSpacing.md),

                  _trending(context),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào bạn 👋', style: AppTextStyles.caption),
              Text('Elevate Your Game.', style: AppTextStyles.h1),
            ],
          ),
        ),
        IconButton(
          onPressed: () => AppShell.goToTab(context, AppTab.cart),
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      ],
    );
  }

  Widget _search(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: () {
          AppShell.goToTab(context, AppTab.shop);
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Tìm vợt, giày, phụ kiện...',
                style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categories(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: home.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, index) {
          final category = home.categories[index];

          return CategoryCard(
            category: category,
            onTap: () {
              AppShell.goToTab(context, AppTab.shop);
            },
          );
        },
      ),
    );
  }

  Widget _featured(BuildContext context) {
    return SizedBox(
      height: 330,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: home.featuredProducts.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, index) {
          final product = home.featuredProducts[index];

          return SizedBox(
            width: 190,
            child: ProductCard(
              product: product,
              onTap: () => _openProduct(context, product.id),
            ),
          );
        },
      ),
    );
  }

  Widget _brands(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: home.brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, index) {
          final brand = home.brands[index];

          return BrandTile(
            brand: brand,
            onTap: () {
              AppShell.goToTab(context, AppTab.shop);
            },
          );
        },
      ),
    );
  }

  Widget _trending(BuildContext context) {
    return GridView.builder(
      itemCount: home.trendingProducts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (_, index) {
        final product = home.trendingProducts[index];

        return ProductCard(
          product: product,
          onTap: () => _openProduct(context, product.id),
        );
      },
    );
  }

  void _openProduct(BuildContext context, int productId) {
    Navigator.pushNamed(context, AppRoutes.productDetail, arguments: productId);
  }
}
