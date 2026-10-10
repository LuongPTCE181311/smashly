import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import 'widgets/cart_item_tile.dart';
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
    final items = cart.items;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) return _SelectAllRow(cart: cart);
        final item = items[index - 1];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          onDismissed: (_) => _remove(context, item),
          child: CartItemTile(
            item: item,
            onToggle: () => _show(context, cart.toggleSelected(item)),
            onDecrease: () => _show(context, cart.changeQuantity(item, -1)),
            onIncrease: () => _show(context, cart.changeQuantity(item, 1)),
          ),
        );
      },
    );
  }

  Future<void> _remove(BuildContext context, CartItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await cart.remove(item);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${item.name}"'),
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
