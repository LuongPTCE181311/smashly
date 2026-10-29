import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import 'widgets/cart_brand_header.dart';
import 'widgets/cart_item_tile.dart';
import 'widgets/cart_product_group.dart';
import 'widgets/cart_skeleton.dart';
import 'widgets/cart_summary_bar.dart';

/// S07 · Giỏ hàng. OWNER: Danh.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: switch (cart.status) {
        ViewStatus.initial || ViewStatus.loading => const CartSkeleton(),
        ViewStatus.error => ErrorState(
          message: cart.errorMessage,
          onRetry: cart.load,
        ),
        ViewStatus.empty => EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Giỏ hàng đang trống',
          message: 'Thêm vài món để bắt đầu trận đấu của bạn.',
          actionLabel: 'Khám phá sản phẩm',
          onAction: () => AppShell.goToTab(context, AppTab.shop),
        ),
        ViewStatus.success => _CartList(cart: cart),
      },
      bottomNavigationBar: cart.status == ViewStatus.success
          ? CartSummaryBar(
              total: cart.selectedTotal,
              selectedCount: cart.selectedCount,
              hasUnavailable: cart.hasUnavailableSelected,
              onCheckout: () =>
                  Navigator.of(context).pushNamed(AppRoutes.checkout),
            )
          : null,
    );
  }
}

class _CartList extends StatelessWidget {
  const _CartList({required this.cart});

  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    final byBrand = <String, Map<int, List<CartItem>>>{};
    for (final item in cart.items) {
      ((byBrand[item.brand] ??= {})[item.productId] ??= []).add(item);
    }

    final entries = <Widget Function(BuildContext)>[];
    for (final MapEntry(key: brand, value: products) in byBrand.entries) {
      if (brand.isNotEmpty) {
        final brandItems = [for (final group in products.values) ...group];
        entries.add(
          (context) => CartBrandHeader(
            key: ValueKey('brand-$brand'),
            brand: brand,
            items: brandItems,
            onToggle: (selected) =>
                _show(context, _setMany(brandItems, selected)),
          ),
        );
      }
      for (final group in products.values) {
        entries.add(
          (context) => group.length > 1
              ? _groupCard(context, group)
              : _singleCard(context, group.single),
        );
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: entries.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) return _SelectAllRow(cart: cart);
        return entries[index - 1](context);
      },
    );
  }

  Widget _singleCard(BuildContext context, CartItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      movementDuration: AppMotion.of(context, AppMotion.normal),
      resizeDuration: AppMotion.of(context, AppMotion.normal),
      background: const _DeleteBackground(),
      onDismissed: (_) => _remove(context, item),
      child: CartItemTile(
        item: item,
        onToggle: () => _show(context, cart.toggleSelected(item)),
        onDecrease: () => _show(context, cart.changeQuantity(item, -1)),
        onIncrease: () => _show(context, cart.changeQuantity(item, 1)),
        onSetQuantity: (value) => _show(context, cart.setQuantity(item, value)),
        onOpen: () => _openProduct(context, item.productId),
      ),
    );
  }

  /// Vuốt phần đầu thẻ (ảnh, tên, giá) xóa cả sản phẩm; vuốt một dòng size bên
  /// trong chỉ xóa size đó (Dismissible lồng nhau: dòng size ở sâu hơn nên
  /// thắng cuộc thi cử chỉ khi vuốt bắt đầu trên dòng đó).
  Widget _groupCard(BuildContext context, List<CartItem> group) {
    return Dismissible(
      key: ValueKey('group-${group.first.productId}'),
      direction: DismissDirection.endToStart,
      movementDuration: AppMotion.of(context, AppMotion.normal),
      resizeDuration: AppMotion.of(context, AppMotion.normal),
      background: const _DeleteBackground(),
      onDismissed: (_) => _removeGroup(context, group),
      child: CartProductGroup(
        items: group,
        onToggleGroup: (selected) => _show(context, _setMany(group, selected)),
        onToggle: (item) => _show(context, cart.toggleSelected(item)),
        onDecrease: (item) => _show(context, cart.changeQuantity(item, -1)),
        onIncrease: (item) => _show(context, cart.changeQuantity(item, 1)),
        onSetQuantity: (item, value) =>
            _show(context, cart.setQuantity(item, value)),
        onRemove: (item) => _remove(context, item),
        onOpen: () => _openProduct(context, group.first.productId),
      ),
    );
  }

  /// Mở chi tiết sản phẩm bằng push nên Back (nút mũi tên hay cử chỉ hệ thống)
  /// quay về đúng tab Giỏ hàng, giữ nguyên vị trí cuộn và các món đang chọn.
  void _openProduct(BuildContext context, int productId) {
    // Đã có màn khác đè lên (bấm đúp nhanh): bỏ qua để không mở 2 lần.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    Navigator.of(context)
        .pushNamed(AppRoutes.productDetail, arguments: productId);
  }

  Future<String?> _setMany(List<CartItem> items, bool selected) async {
    String? firstError;
    for (final item in items) {
      if (item.isSelected == selected) continue;
      firstError ??= await cart.toggleSelected(item);
    }
    return firstError;
  }

  Future<void> _remove(BuildContext context, CartItem item) =>
      _removeLines(context, [item], 'Đã xóa "${item.name}"');

  Future<void> _removeGroup(BuildContext context, List<CartItem> group) =>
      _removeLines(
        context,
        group,
        'Đã xóa "${group.first.name}" (${group.length} size)',
      );

  Future<void> _removeLines(
    BuildContext context,
    List<CartItem> items,
    String message,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await cart.removeMany(items);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: _UndoContent(message: message),
          persist: false,
          duration: _undoDuration,
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () async {
              final undoError = await cart.undoRemove();
              if (undoError != null) {
                messenger.showSnackBar(SnackBar(content: Text(undoError)));
              }
            },
          ),
        ),
      );
  }
}

const _undoDuration = Duration(seconds: 4);

class _UndoContent extends StatelessWidget {
  const _UndoContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        if (!reduceMotion) ...[
          const SizedBox(height: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: _undoDuration,
            builder: (context, value, _) => ClipRRect(
              borderRadius: AppRadius.smAll,
              child: LinearProgressIndicator(
                value: value,
                minHeight: 3,
                color: AppColors.onDark,
                backgroundColor: AppColors.onDark.withValues(alpha: 0.24),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Hiện SnackBar nếu thao tác trả về lỗi (null = thành công).
Future<void> _show(BuildContext context, Future<String?> action) async {
  final messenger = ScaffoldMessenger.of(context);
  final error = await action;
  if (error != null) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(error)));
  }
}

class _SelectAllRow extends StatelessWidget {
  const _SelectAllRow({required this.cart});

  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: cart.allSelected,
          onChanged: (value) =>
              _show(context, cart.setAllSelected(value ?? false)),
        ),
        Expanded(
          child: Text(
            'Chọn tất cả (${cart.items.length})',
            style: AppTextStyles.subtitle,
          ),
        ),
      ],
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.lgAll,
      ),
      child: const Icon(Icons.delete_outline_rounded, color: AppColors.onDark),
    );
  }
}
