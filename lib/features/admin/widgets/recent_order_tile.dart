import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/admin_dashboard.dart';
import '../../../shared/widgets/order_status_badge.dart';

/// Một hàng trong mục "Đơn gần đây": mã đơn, khách, ngày, tổng tiền, trạng thái.
class RecentOrderTile extends StatelessWidget {
  const RecentOrderTile({super.key, required this.recentOrder});

  final AdminRecentOrder recentOrder;

  @override
  Widget build(BuildContext context) {
    final order = recentOrder.order;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderCode, style: AppTextStyles.subtitle),
                const SizedBox(height: 2),
                Text(
                  recentOrder.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body,
                ),
                Text(
                  DateFormatter.dateTime(order.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(order.total),
                style: AppTextStyles.priceSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              OrderStatusBadge(status: order.status),
            ],
          ),
        ],
      ),
    );
  }
}
