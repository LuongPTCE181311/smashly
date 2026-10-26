import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/payment_method_label.dart';
import '../../data/models/order.dart';
import '../../providers/order_detail_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/secondary_button.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../../shared/widgets/states/loading_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';

/// S09 · Đặt hàng thành công. OWNER: Danh.
///
/// Mở bằng `pushReplacementNamed` từ Checkout nên Back không quay lại Checkout
/// (đơn đã đặt, giỏ đã trống). Nhận `orderId` qua arguments; đơn được nạp lại
/// từ DB bằng [OrderDetailProvider] để hiện đúng mã đơn đã lưu.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderDetailProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng thành công'),
        automaticallyImplyLeading: false,
      ),
      body: switch (provider.status) {
        ViewStatus.initial || ViewStatus.loading => const LoadingState(),
        ViewStatus.error => ErrorState(
          message: provider.errorMessage,
          onRetry: provider.load,
        ),
        ViewStatus.empty => EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Không tìm thấy đơn hàng',
          message: 'Bạn có thể xem lại trong mục Đơn hàng.',
          actionLabel: 'Tiếp tục mua sắm',
          onAction: () => AppShell.goToTab(context, AppTab.shop),
        ),
        ViewStatus.success => _SuccessContent(order: provider.order!),
      },
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            const _CheckBadge(),
            const SizedBox(height: AppSpacing.lg),
            const Text('Cảm ơn bạn đã đặt hàng!', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Chúng tôi sẽ xác nhận và giao hàng sớm nhất.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            _OrderInfoCard(order: order),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Xem đơn hàng',
              height: AppSizes.ctaHeight,
              // Thay màn thành công bằng chi tiết đơn: Back từ chi tiết về thẳng
              // app, không lòi lại màn "Đặt hàng thành công".
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                AppRoutes.orderDetail,
                arguments: order.id,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Tiếp tục mua sắm',
              onPressed: () => AppShell.goToTab(context, AppTab.shop),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.emphasis),
      curve: AppMotion.emphasisCurve,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: t, child: child),
      ),
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          color: AppColors.successSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_rounded,
          size: 56,
          color: AppColors.success,
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text('Mã đơn hàng', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(order.orderCode, style: AppTextStyles.h2),
          const Divider(height: AppSpacing.xl),
          _row('Tổng thanh toán', CurrencyFormatter.format(order.total)),
          const SizedBox(height: AppSpacing.sm),
          _row('Phương thức', order.paymentMethod.label),
          const SizedBox(height: AppSpacing.sm),
          _row('Giao tới', order.shippingAddress),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.body),
      const SizedBox(width: AppSpacing.lg),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AppTextStyles.subtitle,
        ),
      ),
    ],
  );
}
