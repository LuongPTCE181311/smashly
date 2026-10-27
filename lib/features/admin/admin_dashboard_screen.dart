import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/daos/admin_dashboard_dao.dart';
import '../../data/models/admin_dashboard.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/states/error_state.dart';
import '../../shared/widgets/states/loading_state.dart';
import 'widgets/dashboard_stat_card.dart';
import 'widgets/low_stock_tile.dart';
import 'widgets/recent_order_tile.dart';

/// S13 — Admin Dashboard (UC16): 4 thẻ số liệu, sắp hết hàng, 5 đơn gần đây.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<AdminDashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const _Header(),
          Expanded(child: _buildBody(context, dashboard)),
        ],
      ),
    );
  }

  // ===== BODY: loading / error / success (trống xử lý trong từng mục) =====

  Widget _buildBody(BuildContext context, AdminDashboardProvider provider) {
    final data = provider.dashboard;

    return switch (provider.status) {
      ViewStatus.initial ||
      ViewStatus.loading => const LoadingState(message: 'Đang tải số liệu...'),
      ViewStatus.error => ErrorState(
        message: provider.errorMessage,
        onRetry: provider.retry,
      ),
      // success luôn có dữ liệu; kiểm tra null chỉ để Dart biết kiểu.
      ViewStatus.empty || ViewStatus.success =>
        data == null
            ? const SizedBox.shrink()
            : _buildContent(context, provider, data),
    };
  }

  Widget _buildContent(
    BuildContext context,
    AdminDashboardProvider provider,
    AdminDashboard data,
  ) {
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: [
          const _SectionTitle(
            icon: Icons.insights_rounded,
            title: 'Tổng quan',
          ),
          const SizedBox(height: AppSpacing.md),
          _StatGrid(stats: data.stats),
          const SizedBox(height: AppSpacing.section),
          _SectionTitle(
            icon: Icons.warning_amber_rounded,
            title: 'Sắp hết hàng',
            trailing: '${data.lowStockProducts.length} sản phẩm',
          ),
          const SizedBox(height: AppSpacing.md),
          provider.hasLowStock
              ? _SectionCard(
                  children: [
                    for (final product in data.lowStockProducts)
                      LowStockTile(
                        key: ValueKey(product.id),
                        product: product,
                        onTap: () => _openForm(context, product.id),
                      ),
                  ],
                )
              : const _SectionEmpty(
                  icon: Icons.inventory_2_outlined,
                  message:
                      'Kho đang ổn: không có sản phẩm nào còn '
                      '≤ ${AdminDashboardDao.lowStockThreshold}.',
                ),
          const SizedBox(height: AppSpacing.section),
          const _SectionTitle(
            icon: Icons.receipt_long_rounded,
            title: 'Đơn gần đây',
            trailing: '5 đơn mới nhất',
          ),
          const SizedBox(height: AppSpacing.md),
          provider.hasRecentOrders
              ? _SectionCard(
                  children: [
                    for (final recent in data.recentOrders)
                      RecentOrderTile(
                        key: ValueKey(recent.order.id),
                        recentOrder: recent,
                      ),
                  ],
                )
              : const _SectionEmpty(
                  icon: Icons.receipt_long_outlined,
                  message: 'Chưa có đơn hàng nào.',
                ),
          const SizedBox(height: AppSpacing.section),
          PrimaryButton(
            label: 'Quản lý sản phẩm',
            icon: Icons.tune_rounded,
            onPressed: () => _openProducts(context),
          ),
        ],
      ),
    );
  }

  // ===== ĐIỀU HƯỚNG: quay về thì làm mới số liệu =====

  /// Mở S15 ở chế độ sửa [productId].
  Future<void> _openForm(BuildContext context, int productId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.adminProductForm,
      arguments: productId,
    );
    if (!context.mounted) return;
    context.read<AdminDashboardProvider>().refresh();
  }

  Future<void> _openProducts(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.adminProducts);
    if (!context.mounted) return;
    context.read<AdminDashboardProvider>().refresh();
  }
}

// ===== HEADER: dải Midnight "SMASHLY Admin" + avatar =====

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final fullName = context.watch<AuthProvider>().currentUser?.fullName ?? '';
    final initial = fullName.trim().isEmpty
        ? 'A'
        : fullName.trim()[0].toUpperCase();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.darkGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMASHLY Admin',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
                    Text(
                      'Bảng điều khiển',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.accentVolt,
                child: Text(
                  initial,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== 4 THẺ SỐ LIỆU (lưới 2×2) =====

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final AdminDashboardStats stats;

  static const _cardHeight = 128.0;

  @override
  Widget build(BuildContext context) {
    final cards = [
      DashboardStatCard(
        label: 'Tổng sản phẩm',
        value: stats.totalProducts,
        icon: Icons.inventory_2_outlined,
        color: AppColors.primary,
        softColor: AppColors.primarySoft,
        caption: 'Gồm cả đang ẩn',
      ),
      DashboardStatCard(
        label: 'Sắp hết hàng',
        value: stats.lowStockCount,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        softColor: AppColors.warningSoft,
        caption: 'Tồn kho ≤ ${AdminDashboardDao.lowStockThreshold}',
      ),
      DashboardStatCard(
        label: 'Đơn chờ xác nhận',
        value: stats.pendingOrderCount,
        icon: Icons.schedule_rounded,
        color: AppColors.info,
        softColor: AppColors.infoSoft,
        caption: 'Mới đặt',
      ),
      DashboardStatCard(
        label: 'Doanh thu đã giao',
        value: stats.deliveredRevenue,
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
        softColor: AppColors.successSoft,
        caption: 'Đơn đã giao',
        format: CurrencyFormatter.format,
      ),
    ];

    Widget row(Widget left, Widget right) => SizedBox(
      height: _cardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );

    return Column(
      children: [
        row(cards[0], cards[1]),
        const SizedBox(height: AppSpacing.md),
        row(cards[2], cards[3]),
      ],
    );
  }
}

// ===== KHUNG MỤC =====

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: AppTextStyles.h2)),
        if (trailing != null) Text(trailing!, style: AppTextStyles.caption),
      ],
    );
  }
}

/// Card trắng bo góc chứa các hàng, có đường kẻ giữa các hàng.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Trạng thái trống của một mục (không chiếm cả màn như EmptyState).
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

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
        children: [
          Icon(icon, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
