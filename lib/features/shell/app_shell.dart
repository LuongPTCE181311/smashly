import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/shell_tab_provider.dart';
import '../../routes/app_routes.dart';
import '../cart/widgets/cart_badge_icon.dart';
import 'app_tab.dart';

/// Khung khách với bottom nav 5 tab, giữ trạng thái từng tab bằng IndexedStack.
/// Đổi tab từ màn khác bằng [goToTab].
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  /// Đóng các màn đang đè lên AppShell rồi chuyển sang [tab]; không có AppShell thì không làm gì.
  static void goToTab(BuildContext context, AppTab tab) {
    final tabs = context.read<ShellTabProvider>();
    if (!tabs.hasShell) return;
    // AppShell luôn là route đầu: vào app bằng pushNamedAndRemoveUntil hoặc pushReplacement.
    Navigator.of(context).popUntil((route) => route.isFirst);
    tabs.select(tab);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ShellTabProvider _tabs;
  late final Set<AppTab> _opened = {widget.initialTab};

  @override
  void initState() {
    super.initState();
    _tabs = context.read<ShellTabProvider>()..attach(widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellTabProvider>().tab;
    _opened.add(tab);
    final cartCount = context.select<CartProvider, int>(
      (cart) => cart.itemCount,
    );

    return PopScope(
      // Back ở tab khác → về Home; Back ở Home → thoát app.
      canPop: tab == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _tabs.select(AppTab.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: tab.index,
          children: [
            for (final destination in AppTab.values)
              HeroMode(
                enabled: destination == tab,
                child: _opened.contains(destination)
                    ? AppRoutes.screen(destination.routeName)
                    : const SizedBox.shrink(),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (index) => _tabs.select(AppTab.values[index]),
          destinations: [
            for (final destination in AppTab.values)
              NavigationDestination(
                label: destination.label,
                icon: _icon(destination, destination.icon, cartCount),
                selectedIcon: _icon(
                  destination,
                  destination.selectedIcon,
                  cartCount,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _icon(AppTab tab, IconData icon, int cartCount) {
    if (tab != AppTab.cart) return Icon(icon);
    return CartBadgeIcon(icon: icon, count: cartCount);
  }
}
