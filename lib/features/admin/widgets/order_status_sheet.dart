import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/order.dart';
import '../../../providers/admin_dashboard_provider.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/order_status_badge.dart';

/// Bottom sheet đổi trạng thái đơn (S13 · UC19). Chỉ hiện nút cho các trạng
/// thái hợp lệ ([OrderStatus.allowedNextStatuses]).
///
/// Trả về trạng thái mới khi đổi thành công, null nếu đóng sheet.
class OrderStatusSheet extends StatelessWidget {
  const OrderStatusSheet({super.key, required this.order});

  final Order order;

  static Future<OrderStatus?> show(BuildContext context, Order order) {
    // Sheet là route riêng, không thấy Provider của màn Dashboard nên phải
    // truyền lại bằng `.value`.
    final provider = context.read<AdminDashboardProvider>()..clearStatusError();

    return showModalBottomSheet<OrderStatus>(
      context: context,
      isScrollControlled: true,
      // Tắt kéo để đóng: kéo sheet không đi qua PopScope bên dưới.
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: OrderStatusSheet(order: order),
      ),
    );
  }

  /// Hủy đơn cần hỏi lại vì có hậu quả: hoàn tồn kho, không hoàn tác được.
  Future<void> _changeStatus(BuildContext context, OrderStatus to) async {
    if (to == OrderStatus.cancelled) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Hủy đơn ${order.orderCode}?',
        message: 'Tồn kho của các sản phẩm trong đơn sẽ được hoàn lại.',
        confirmLabel: 'Hủy đơn',
        cancelLabel: 'Giữ đơn',
        destructive: true,
        icon: Icons.cancel_outlined,
      );
      if (!confirmed || !context.mounted) return;
    }

    final updated = await context
        .read<AdminDashboardProvider>()
        .updateOrderStatus(order, to);
    if (updated && context.mounted) Navigator.of(context).pop(to);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminDashboardProvider>();
    final isSaving = provider.isUpdatingStatus;
    final error = provider.statusError;

    return PopScope(
      canPop: !isSaving,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OrderSummary(order: order),
              const SizedBox(height: AppSpacing.lg),
              if (error != null) ...[
                _ErrorBanner(message: error),
                const SizedBox(height: AppSpacing.md),
              ],
              if (order.status.isFinal)
                _FinalStatusNote(status: order.status)
              else
                for (final next in order.status.allowedNextStatuses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ActionButton(
                      status: next,
                      isLoading: provider.updatingStatus == next,
                      onPressed: isSaving
                          ? null
                          : () => _changeStatus(context, next),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mã đơn, người nhận, tổng tiền, trạng thái hiện tại.
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderCode, style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(order.receiverName, style: AppTextStyles.body),
              Text(
                CurrencyFormatter.format(order.total),
                style: AppTextStyles.priceSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OrderStatusBadge(status: order.status),
      ],
    );
  }
}

/// Nút chuyển sang [status]. Hủy đơn dùng viền đỏ, còn lại là nút chính.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.status,
    required this.isLoading,
    required this.onPressed,
  });

  final OrderStatus status;
  final bool isLoading;
  final VoidCallback? onPressed;

  String get _label => switch (status) {
    OrderStatus.confirmed => 'Xác nhận đơn',
    OrderStatus.shipping => 'Bắt đầu giao hàng',
    OrderStatus.delivered => 'Xác nhận đã giao',
    OrderStatus.cancelled => 'Hủy đơn',
    OrderStatus.pending => status.label,
  };

  @override
  Widget build(BuildContext context) {
    if (status != OrderStatus.cancelled) {
      return PrimaryButton(
        label: _label,
        icon: status.icon,
        isLoading: isLoading,
        onPressed: onPressed,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.error,
              ),
            )
          : Text(_label),
    );
  }
}

/// Đơn ở trạng thái cuối: không có nút, chỉ có dòng giải thích.
class _FinalStatusNote extends StatelessWidget {
  const _FinalStatusNote({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final state = status == OrderStatus.delivered ? 'hoàn tất' : 'hủy';

    return Text(
      'Đơn đã $state, không thể đổi trạng thái',
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
