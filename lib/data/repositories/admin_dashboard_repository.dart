import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_exception.dart';
import '../daos/admin_dashboard_dao.dart';
import '../models/admin_dashboard.dart';

/// Dữ liệu Admin Dashboard (S13 · UC16). OWNER: Trọng.
class AdminDashboardRepository {
  const AdminDashboardRepository({
    required this._database,
    required this._dashboardDao,
  });

  final Future<Database> Function() _database;
  final AdminDashboardDao _dashboardDao;

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
