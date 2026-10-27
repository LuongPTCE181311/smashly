import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/payment_method_label.dart';
import '../../data/models/order.dart';
import '../../providers/order_detail_provider.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/order_status_badge.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import 'widgets/cancel_order_bar.dart';
import 'widgets/order_detail_skeleton.dart';
import 'widgets/order_item_row.dart';
import 'widgets/order_section_card.dart';
import 'widgets/order_timeline.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderDetailProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: switch (provider.status) {
        ViewStatus.initial || ViewStatus.loading => const OrderDetailSkeleton(),
        ViewStatus.error => ErrorState(
          message: provider.errorMessage,
          onRetry: provider.load,
        ),
        ViewStatus.empty => EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Không tìm thấy đơn hàng',
          message: 'Đơn hàng không tồn tại hoặc không thuộc tài khoản này.',
          actionLabel: 'Về danh sách đơn',
          onAction: () => Navigator.of(context).maybePop(),
        ),
        ViewStatus.success => _OrderDetailContent(order: provider.order!),
      },
      bottomNavigationBar:
          provider.status == ViewStatus.success && provider.canCancel
          ? CancelOrderBar(
              isLoading: provider.isCancelling,
              onCancel: () => _confirmCancel(context, provider),
            )
          : null,
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    OrderDetailProvider provider,
  ) async {
    final order = provider.order;
    if (order == null) return;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Hủy đơn hàng?',
      message:
          'Đơn ${order.orderCode} sẽ bị hủy và sản phẩm được hoàn lại kho. '
          'Bạn không thể hoàn tác thao tác này.',
      confirmLabel: 'Hủy đơn',
      cancelLabel: 'Giữ đơn',
      destructive: true,
      icon: Icons.cancel_outlined,
    );
    if (!confirmed) return;

    final error = await provider.cancelOrder();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Đã hủy đơn ${order.orderCode}'),
          backgroundColor: error == null ? null : AppColors.error,
        ),
      );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        _Header(order: order),
        const SizedBox(height: AppSpacing.md),
        OrderSectionCard(
          title: 'Trạng thái đơn hàng',
          icon: Icons.history_rounded,
          child: OrderTimeline(key: ValueKey(order.status), order: order),
        ),
        const SizedBox(height: AppSpacing.md),
        OrderSectionCard(
          title: 'Thông tin nhận hàng',
          icon: Icons.location_on_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(
                icon: Icons.person_outline_rounded,
                text: order.receiverName,
              ),
              _InfoLine(icon: Icons.phone_outlined, text: order.receiverPhone),
              _InfoLine(icon: Icons.home_outlined, text: order.shippingAddress),
              if ((order.note ?? '').isNotEmpty)
                _InfoLine(
                  icon: Icons.sticky_note_2_outlined,
                  text: order.note!,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OrderSectionCard(
          title: 'Sản phẩm (${order.totalQuantity})',
          icon: Icons.shopping_bag_outlined,
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(),
                  ),
                OrderItemRow(item: order.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OrderSectionCard(
          title: 'Thanh toán',
          icon: Icons.receipt_long_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    order.paymentMethod.icon,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      order.paymentMethod.label,
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _AmountLine(
                label: 'Tạm tính',
                value: CurrencyFormatter.format(order.subtotal),
              ),
              _AmountLine(
                label: 'Phí vận chuyển',
                value: order.shippingFee == 0
                    ? 'Miễn phí'
                    : CurrencyFormatter.format(order.shippingFee),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(),
              ),
              Row(
                children: [
                  Text('Tổng cộng', style: AppTextStyles.subtitle),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: AppTextStyles.price.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã đơn hàng', style: AppTextStyles.caption),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(order.orderCode, style: AppTextStyles.h2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Đặt lúc ${DateFormatter.dateTime(order.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OrderStatusBadge(status: order.status),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
