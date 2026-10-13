import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/product_detail.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import 'widgets/add_to_cart_bar.dart';
import 'widgets/product_description.dart';
import 'widgets/product_detail_skeleton.dart';
import 'widgets/product_highlights.dart';
import 'widgets/product_image_header.dart';
import 'widgets/product_info_section.dart';
import 'widgets/racket_spec_section.dart';
import 'widgets/size_selector.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  static const addedFeedback = Duration(milliseconds: 800);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _justAdded = false;
  Timer? _addedTimer;

  @override
  void dispose() {
    _addedTimer?.cancel();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final provider = context.read<ProductDetailProvider>();
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final error = await provider.addToCart(cart);
    if (!mounted) return;

    messenger.hideCurrentSnackBar();
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _justAdded = true);
    _addedTimer?.cancel();
    _addedTimer = Timer(ProductDetailScreen.addedFeedback, () {
      if (mounted) setState(() => _justAdded = false);
    });

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng'),
        action: SnackBarAction(
          label: 'Xem giỏ',
          onPressed: () => AppShell.goToTab(context, AppTab.cart),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductDetailProvider>();
    final detail = provider.detail;

    return Scaffold(
      appBar: provider.status == ViewStatus.success ? null : AppBar(),
      body: switch (provider.status) {
        ViewStatus.initial ||
        ViewStatus.loading => const ProductDetailSkeleton(),
        ViewStatus.error => ErrorState(
          message: provider.errorMessage,
          onRetry: provider.load,
        ),
        ViewStatus.empty => EmptyState(
          icon: Icons.remove_shopping_cart_outlined,
          title: 'Sản phẩm không còn bán',
          message: 'Sản phẩm này đã ngừng bán hoặc không tồn tại.',
          actionLabel: 'Về cửa hàng',
          onAction: () => AppShell.goToTab(context, AppTab.shop),
        ),
        ViewStatus.success => _DetailContent(
          detail: detail!,
          selectedSize: provider.selectedSize,
          onSizeSelected: provider.selectSize,
        ),
      },
      bottomNavigationBar: provider.status == ViewStatus.success
          ? AddToCartBar(
              quantity: provider.quantity,
              label: _buttonLabel(provider),
              icon: _justAdded
                  ? Icons.check_rounded
                  : Icons.add_shopping_cart_rounded,
              isLoading: provider.isAdding,
              onDecrease: provider.canDecrease ? provider.decrease : null,
              onIncrease: provider.canIncrease ? provider.increase : null,
              onAdd: provider.canAddToCart ? _addToCart : null,
            )
          : null,
    );
  }

  String _buttonLabel(ProductDetailProvider provider) {
    if (provider.isOutOfStock) return 'Hết hàng';
    if (_justAdded) return 'Đã thêm';
    if (provider.isSizeMissing) return 'Chọn size';
    return 'Thêm vào giỏ';
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  final ProductDetail detail;
  final String? selectedSize;
  final ValueChanged<String> onSizeSelected;

  @override
  Widget build(BuildContext context) {
    final spec = detail.racketSpec;

    return CustomScrollView(
      slivers: [
        ProductImageHeader(product: detail.product),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          sliver: SliverList.list(
            children: [
              ProductInfoSection(product: detail.product),
              const SizedBox(height: AppSpacing.section),
              if (spec != null)
                RacketSpecSection(spec: spec)
              else
                ProductHighlights(detail: detail),
              if (detail.sizes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.section),
                SizeSelector(
                  sizes: detail.sizes,
                  selected: selectedSize,
                  onSelected: onSizeSelected,
                ),
              ],
              if (detail.product.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.section),
                ProductDescription(text: detail.product.description),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
