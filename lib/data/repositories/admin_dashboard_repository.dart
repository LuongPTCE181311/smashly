import 'package:flutter/foundation.dart' show debugPrint;

import '../../core/constants/enums.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_exception.dart';
import '../daos/admin_dashboard_dao.dart';
import '../daos/order_dao.dart';
import '../models/admin_dashboard.dart';
import '../models/order.dart';
import 'order_repository.dart';

/// Dữ liệu Admin Dashboard (S13 · UC16). OWNER: Trọng.
class AdminDashboardRepository {
  const AdminDashboardRepository({
    this._database = DatabaseHelper.open,
    this._dashboardDao = const AdminDashboardDao(),
    this._orderDao = const OrderDao(),
  });

  final DatabaseOpener _database;
  final AdminDashboardDao _dashboardDao;
  final OrderDao _orderDao;

  /// UC19: đổi trạng thái một đơn trong "Đơn gần đây". Luật nghiệp vụ nằm ở
  /// [OrderRepository.updateStatus], ở đây chỉ chuyển tiếp để Dashboard chỉ cần
  /// một Repository.
  Future<Order> updateOrderStatus(Order order, OrderStatus to) {
    return OrderRepository(
      database: _database,
      orderDao: _orderDao,
    ).updateStatus(order.id, from: order.status, to: to);
  }

  /// Đọc số liệu, danh sách sắp hết hàng và 5 đơn gần đây trong cùng một
  /// transaction, để thẻ số liệu và hai danh sách nhìn cùng một trạng thái DB.
  Future<AdminDashboard> getDashboard() async {
    try {
      final db = await _database();
      return await db.transaction((txn) async {
        final stats = await _dashboardDao.getStats(txn);
        final lowStock = await _dashboardDao.getLowStockProducts(txn);
        final recentOrders = await _dashboardDao.getRecentOrders(txn);
        return AdminDashboard(
          stats: stats,
          lowStockProducts: lowStock,
          recentOrders: recentOrders,
        );
      });
    } catch (error) {
      debugPrint('AdminDashboardRepository.getDashboard: $error');
      throw const AppException(
        'Không thể tải bảng điều khiển. Vui lòng thử lại.',
      );
    }
  }
}
