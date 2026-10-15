import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/order_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/order_status_badge.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import 'widgets/my_orders_skeleton.dart';
import 'widgets/order_card.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  static const filters = <OrderStatus?>[null, ...OrderStatus.values];

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  AppTab? _lastTab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = AppShell.currentTabOf(context);
    final reopened =
        tab == AppTab.orders && _lastTab != null && _lastTab != AppTab.orders;
    _lastTab = tab;
    if (!reopened) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final showTabs =
        provider.status == ViewStatus.success ||
        (provider.status == ViewStatus.empty && provider.isSignedIn);

    return DefaultTabController(
      length: MyOrdersScreen.filters.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi'),
          bottom: showTabs
              ? TabBar(
                  isScrollable: true,
                  tabs: [
                    for (final status in MyOrdersScreen.filters)
                      Tab(text: _tabLabel(status, provider.countOf(status))),
                  ],
                )
              : null,
        ),
        body: switch (provider.status) {
          ViewStatus.initial || ViewStatus.loading => const MyOrdersSkeleton(),
          ViewStatus.error => ErrorState(
            message: provider.errorMessage,
            onRetry: provider.load,
          ),
          ViewStatus.empty when !provider.isSignedIn => const EmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Bạn chưa đăng nhập',
            message: 'Đăng nhập để xem các đơn hàng đã đặt.',
          ),
          ViewStatus.empty || ViewStatus.success => TabBarView(
            children: [
              for (final status in MyOrdersScreen.filters)
                _OrderList(status: status),
            ],
          ),
        },
      ),
    );
  }

  String _tabLabel(OrderStatus? status, int count) {
    final name = status?.label ?? 'Tất cả';
    return count > 0 ? '$name ($count)' : name;
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.status});

  final OrderStatus? status;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.ordersWith(status);

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: orders.isEmpty
          ? CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyTab(status: status),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screen),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final summary = orders[index];
                return OrderCard(
                  summary: summary,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.orderDetail,
                    arguments: summary.order.id,
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.status});

  final OrderStatus? status;

  @override
  Widget build(BuildContext context) {
    final current = status;
    if (current == null) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Chưa có đơn hàng nào',
        message: 'Đơn hàng bạn đặt sẽ xuất hiện ở đây.',
        actionLabel: 'Mua sắm ngay',
        onAction: () => AppShell.goToTab(context, AppTab.shop),
      );
    }
    return EmptyState(
      icon: current.icon,
      title: 'Chưa có đơn ${current.label.toLowerCase()}',
    );
  }
}
