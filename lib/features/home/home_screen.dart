import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smashly/features/home/widgets/home_brands_section.dart';
import 'package:smashly/features/home/widgets/home_categories_section.dart';
import 'package:smashly/features/home/widgets/home_featured_section.dart';
import 'package:smashly/features/home/widgets/home_header.dart';
import 'package:smashly/features/home/widgets/home_trending_section.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/home_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
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
                const HomeHeader(),

                const SizedBox(height: AppSpacing.lg),

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

                HomeCategoriesSection(
                  categories: home.categories,
                  onCategoryTap: (category) {
                    AppShell.goToTab(context, AppTab.shop);
                  },
                ),

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

                  HomeFeaturedSection(
                    products: home.featuredProducts,
                    onProductTap: (product) {
                      _openProduct(context, product.id);
                    },
                  ),
                ],

                if (home.brands.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.section),

                  const SectionHeader(title: 'Top Brands'),

                  const SizedBox(height: AppSpacing.md),

                  HomeBrandsSection(
                    brands: home.brands,
                    onBrandTap: (brand) {
                      AppShell.goToTab(context, AppTab.shop);
                    },
                  ),
                ],

                if (home.trendingProducts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.section),

                  const SectionHeader(title: 'Trending Now'),

                  const SizedBox(height: AppSpacing.md),

                  HomeTrendingSection(
                    products: home.trendingProducts,
                    onProductTap: (product) {
                      _openProduct(context, product.id);
                    },
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openProduct(BuildContext context, int productId) {
    Navigator.pushNamed(context, AppRoutes.productDetail, arguments: productId);
  }
}
