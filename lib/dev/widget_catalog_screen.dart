import 'package:flutter/material.dart';

import '../core/constants/enums.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../shared/widgets/app_dialog.dart';
import '../shared/widgets/app_logo.dart';
import '../shared/widgets/buttons/primary_button.dart';
import '../shared/widgets/buttons/secondary_button.dart';
import '../shared/widgets/category_card.dart';
import '../shared/widgets/inputs/app_text_field.dart';
import '../shared/widgets/order_status_badge.dart';
import '../shared/widgets/price_text.dart';
import '../shared/widgets/product_card.dart';
import '../shared/widgets/rating_view.dart';
import '../shared/widgets/states/empty_state.dart';
import '../shared/widgets/states/error_state.dart';
import '../shared/widgets/states/loading_state.dart';
import '../shared/widgets/stock_badge.dart';

class WidgetCatalogScreen extends StatelessWidget {
  const WidgetCatalogScreen({super.key});

  static const _colors = <(String, Color)>[
    ('primary', AppColors.primary),
    ('primaryDark', AppColors.primaryDark),
    ('primarySoft', AppColors.primarySoft),
    ('accentVolt', AppColors.accentVolt),
    ('midnight', AppColors.midnight),
    ('navy', AppColors.navy),
    ('ink', AppColors.ink),
    ('inkMuted', AppColors.inkMuted),
    ('background', AppColors.background),
    ('surface', AppColors.surface),
    ('productTile', AppColors.productTile),
    ('border', AppColors.border),
    ('success', AppColors.success),
    ('warning', AppColors.warning),
    ('error', AppColors.error),
    ('info', AppColors.info),
    ('violet', AppColors.violet),
  ];

  static final _textStyles = <(String, TextStyle)>[
    ('display', AppTextStyles.display),
    ('h1', AppTextStyles.h1),
    ('h2', AppTextStyles.h2),
    ('subtitle', AppTextStyles.subtitle),
    ('body', AppTextStyles.body),
    ('label', AppTextStyles.label),
    ('caption', AppTextStyles.caption),
    ('button', AppTextStyles.button),
    ('priceLarge', AppTextStyles.priceLarge),
    ('price', AppTextStyles.price),
    ('priceSmall', AppTextStyles.priceSmall),
  ];

  static const _product = Product(
    id: 9001,
    categoryId: 1,
    name: 'Victor Auraspeed 90K II',
    brand: 'Victor',
    price: 3890000,
    originalPrice: 4390000,
    stock: 3,
    rating: 4.8,
    ratingCount: 126,
    description: '',
    imagePath: 'assets/images/products/rackets/racket_victor_auraspeed90k2.png',
    isFeatured: true,
    isActive: true,
  );

  static const _outOfStock = Product(
    id: 9002,
    categoryId: 2,
    name: 'Yonex Power Cushion 65 Z3',
    brand: 'Yonex',
    price: 2890000,
    stock: 0,
    rating: 4.6,
    ratingCount: 88,
    description: '',
    imagePath: 'assets/images/products/shoes/shoe_yonex_65z3.png',
    sizes: '40,41,42',
    isFeatured: false,
    isActive: true,
  );

  static const _categories = [
    Category(
      id: 1,
      name: 'Vợt',
      iconPath: 'assets/images/categories/rackets.png',
      sortOrder: 1,
    ),
    Category(
      id: 2,
      name: 'Giày',
      iconPath: 'assets/images/categories/shoes.png',
      sortOrder: 2,
    ),
  ];

  void _showResult(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDialog(
    BuildContext context, {
    required bool destructive,
  }) async {
    final ok = await AppDialog.confirm(
      context,
      title: destructive ? 'Hủy đơn hàng?' : 'Lưu thay đổi?',
      message: destructive
          ? 'Đơn hàng sẽ bị hủy và sản phẩm được hoàn lại kho.'
          : 'Thông tin mới sẽ được cập nhật vào tài khoản.',
      confirmLabel: destructive ? 'Hủy đơn' : 'Lưu',
      cancelLabel: destructive ? 'Giữ đơn' : 'Hủy',
      destructive: destructive,
      icon: destructive ? Icons.cancel_outlined : Icons.save_outlined,
    );
    if (!context.mounted) return;
    _showResult(context, 'AppDialog.confirm trả về $ok');
  }

  @override
  Widget build(BuildContext context) {
    void noop() => _showResult(context, 'Đã bấm');

    return Scaffold(
      appBar: AppBar(title: const Text('Widget Catalog')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          const _Section('Màu · AppColors'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (name, color) in _colors)
                _ColorSwatch(name: name, color: color),
            ],
          ),
          const _Section('Kiểu chữ · AppTextStyles'),
          for (final (name, style) in _textStyles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('$name · ${style.fontSize!.toInt()}', style: style),
            ),
          const _Section('PrimaryButton'),
          _Labeled(
            'Bình thường',
            PrimaryButton(label: 'Đặt hàng', onPressed: noop),
          ),
          _Labeled(
            'Có icon',
            PrimaryButton(
              label: 'Thêm vào giỏ',
              icon: Icons.add_shopping_cart_rounded,
              onPressed: noop,
            ),
          ),
          const _Labeled(
            'Khóa (onPressed: null)',
            PrimaryButton(label: 'Chọn size', onPressed: null),
          ),
          _Labeled(
            'Đang xử lý (isLoading: true)',
            PrimaryButton(label: 'Đặt hàng', isLoading: true, onPressed: noop),
          ),
          const _Section('SecondaryButton'),
          _Labeled(
            'Bình thường',
            SecondaryButton(label: 'Tiếp tục mua sắm', onPressed: noop),
          ),
          const _Labeled(
            'Khóa (onPressed: null)',
            SecondaryButton(label: 'Tiếp tục mua sắm', onPressed: null),
          ),
          const _Section('AppTextField'),
          const _Labeled(
            'Có gợi ý + icon',
            AppTextField(
              label: 'Email',
              hint: 'ban@smashly.com',
              prefixIcon: Icons.mail_outline_rounded,
            ),
          ),
          const _Labeled(
            'Mật khẩu (nút ẩn/hiện)',
            AppTextField(
              label: 'Mật khẩu',
              isPassword: true,
              prefixIcon: Icons.lock_outline_rounded,
            ),
          ),
          const _Labeled(
            'Lỗi từ Repository (errorText)',
            AppTextField(
              label: 'Email',
              errorText: 'Email này đã được đăng ký',
            ),
          ),
          const _Labeled(
            'Khóa (enabled: false)',
            AppTextField(label: 'Số điện thoại', enabled: false),
          ),
          const _Section('StockBadge'),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StockBadge(stock: 0),
              StockBadge(stock: 3),
              StockBadge(stock: 24),
            ],
          ),
          const _Section('OrderStatusBadge'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final status in OrderStatus.values)
                OrderStatusBadge(status: status),
            ],
          ),
          const _Section('PriceText · RatingView'),
          const _Labeled('Giá thường', PriceText(price: 2890000)),
          const _Labeled(
            'Có giảm giá',
            PriceText(price: 3890000, originalPrice: 4390000),
          ),
          const _Labeled('Đánh giá', RatingView(rating: 4.8, count: 126)),
          const _Section('ProductCard · CategoryCard'),
          SizedBox(
            height: 280,
            child: Row(
              children: [
                Expanded(
                  child: ProductCard(product: _product, onTap: noop),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ProductCard(
                    product: _outOfStock,
                    onTap: noop,
                    onWishlistTap: noop,
                    isFavorite: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final category in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: CategoryCard(category: category, onTap: noop),
                ),
            ],
          ),
          const _Section('AppDialog.confirm'),
          _Labeled(
            'Thường',
            SecondaryButton(
              label: 'Mở dialog',
              onPressed: () => _openDialog(context, destructive: false),
            ),
          ),
          _Labeled(
            'Nguy hiểm (destructive: true)',
            SecondaryButton(
              label: 'Mở dialog hủy đơn',
              onPressed: () => _openDialog(context, destructive: true),
            ),
          ),
          const _Section('LoadingState · EmptyState · ErrorState'),
          const _StateBox(child: LoadingState(message: 'Đang tải đơn hàng...')),
          _StateBox(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có đơn hàng',
              message: 'Đơn hàng bạn đặt sẽ xuất hiện ở đây.',
              actionLabel: 'Mua sắm ngay',
              onAction: noop,
            ),
          ),
          _StateBox(
            child: ErrorState(
              message: 'Không thể tải danh sách đơn hàng. Vui lòng thử lại.',
              onRetry: noop,
            ),
          ),
          _StateBox(
            dark: true,
            child: ErrorState(
              title: 'Không khởi tạo được dữ liệu',
              onDark: true,
              onRetry: noop,
            ),
          ),
          const _Section('AppLogo'),
          const _Labeled('Nền sáng', AppLogo()),
          const _Labeled('Nền tối', _DarkBox(child: AppLogo(onDark: true))),
          const _Labeled('Chỉ biểu tượng', AppLogo(showWordmark: false)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.section,
        bottom: AppSpacing.md,
      ),
      child: Text(title, style: AppTextStyles.h2),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: AppSizes.minTouchTarget,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(name, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          color: dark ? null : AppColors.surface,
          gradient: dark ? AppColors.darkGradient : null,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

class _DarkBox extends StatelessWidget {
  const _DarkBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: AppRadius.lgAll,
      ),
      child: child,
    );
  }
}
