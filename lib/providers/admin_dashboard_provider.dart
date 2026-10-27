import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/admin_dashboard.dart';
import '../data/repositories/admin_dashboard_repository.dart';

/// State của màn Admin Dashboard (S13 · UC16): 4 thẻ số liệu, sắp hết hàng,
/// 5 đơn gần đây.
///
/// Dashboard luôn có 4 thẻ nên không có [ViewStatus.empty] toàn màn; "trống"
/// chỉ xảy ra ở từng mục (xem [hasLowStock], [hasRecentOrders]).
class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider(this._repository);

  final AdminDashboardRepository _repository;

  ViewStatus _status = ViewStatus.initial;
  AdminDashboard? _dashboard;
  String? _errorMessage;

  // Số thứ tự lần tải, tránh kết quả cũ ghi đè kết quả mới.
  int _requestId = 0;

  bool _disposed = false;

  // ===== GETTERS =====

  ViewStatus get status => _status;
  AdminDashboard? get dashboard => _dashboard;
  String? get errorMessage => _errorMessage;

  bool get hasLowStock => _dashboard?.lowStockProducts.isNotEmpty ?? false;
  bool get hasRecentOrders => _dashboard?.recentOrders.isNotEmpty ?? false;

  // ===== TẢI DỮ LIỆU =====

  /// Tải toàn bộ dashboard. [showLoading] = false khi kéo để làm mới hoặc
  /// quay lại từ Form, để màn không nháy sang trạng thái loading.
  Future<void> load({bool showLoading = true}) async {
    if (_disposed) return;

    final requestId = ++_requestId;

    if (showLoading) {
      _status = ViewStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _repository.getDashboard();
      if (_disposed || requestId != _requestId) return;

      _dashboard = result;
      _status = ViewStatus.success;
      _errorMessage = null;
    } on AppException catch (e) {
      if (_disposed || requestId != _requestId) return;

      _status = ViewStatus.error;
      _errorMessage = e.message;
    }

    notifyListeners();
  }

  /// Pull to refresh và quay lại từ Form sản phẩm.
  Future<void> refresh() => load(showLoading: false);

  /// Nút "Thử lại" ở trạng thái lỗi.
  Future<void> retry() => load();

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }
}
