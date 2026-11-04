import 'package:flutter/foundation.dart';

import '../features/shell/app_tab.dart';

/// Tab đang chọn ở thanh điều hướng dưới của khách.
class ShellTabProvider extends ChangeNotifier {
  AppTab _tab = AppTab.home;
  int _openShells = 0;

  AppTab get tab => _tab;

  /// `true` khi có AppShell đang mở trong stack.
  bool get hasShell => _openShells > 0;

  /// AppShell gọi khi được dựng, để mở đúng tab của route.
  void attach(AppTab tab) {
    _openShells++;
    // Gọi trong initState khi cây đang build nên chỉ gán, không notify.
    _tab = tab;
  }

  /// AppShell gọi khi bị hủy.
  void detach() => _openShells--;

  /// Chuyển sang [tab].
  void select(AppTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }
}
