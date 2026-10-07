import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import 'app_tab.dart';

/// Khung customer: bottom nav 5 tab, giữ trạng thái + vị trí cuộn từng tab
/// bằng IndexedStack. Tab chỉ được dựng lần đầu khi người dùng mở tới.
///
/// Mở từ ngoài: `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false)`.
/// Đổi tab từ bất kỳ đâu (kể cả màn đã push lên trên, vd. Product Detail):
/// `AppShell.goToTab(context, AppTab.cart)`.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = AppTab.home});

  final AppTab initialTab;

  static _AppShellState? _active;

  /// Đóng các màn đang đè lên AppShell rồi chuyển sang [tab].
  static void goToTab(BuildContext context, AppTab tab) {
    Navigator.of(context).popUntil(
      (route) => AppTab.fromRoute(route.settings.name) != null || route.isFirst,
    );
    _active?._select(tab);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _tab = widget.initialTab;
  late final Set<AppTab> _opened = {_tab};

  @override
  void initState() {
    super.initState();
    AppShell._active = this;
  }

  @override
  void dispose() {
    if (AppShell._active == this) AppShell._active = null;
    super.dispose();
  }

  void _select(AppTab tab) {
    if (!mounted || tab == _tab) return;
    setState(() {
      _tab = tab;
      _opened.add(tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO(Danh): thay bằng context.watch<CartProvider>().totalQuantity khi có CartProvider.
    const cartCount = 0;

    return PopScope(
      // Back ở tab khác → về Home; Back ở Home → thoát app.
      canPop: _tab == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(AppTab.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [
            for (final tab in AppTab.values)
              _opened.contains(tab)
                  ? AppRoutes.screen(tab.routeName)
                  : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (index) => _select(AppTab.values[index]),
          destinations: [
            for (final tab in AppTab.values)
              NavigationDestination(
                label: tab.label,
                icon: _icon(tab, tab.icon, cartCount),
                selectedIcon: _icon(tab, tab.selectedIcon, cartCount),
              ),
          ],
        ),
      ),
    );
  }

  Widget _icon(AppTab tab, IconData icon, int cartCount) {
    if (tab != AppTab.cart) return Icon(icon);
    return Badge.count(
      count: cartCount,
      isLabelVisible: cartCount > 0,
      child: Icon(icon),
    );
  }
}
