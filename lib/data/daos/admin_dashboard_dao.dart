import 'package:sqflite/sqflite.dart';

import '../../core/constants/enums.dart';
import '../../core/database/db_schema.dart';
import '../models/admin_dashboard.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Truy vấn tổng hợp cho Admin Dashboard (S13 · UC16). OWNER: Trọng.
///
/// Chỉ đọc. Không dùng lại OrderDao (SML-064, Danh) để không phụ thuộc vào
/// file đang được sửa; chỉ dùng chung model [Order].
class AdminDashboardDao {
  const AdminDashboardDao();

  /// Ngưỡng "sắp hết hàng", bằng `StockBadge.lowStockThreshold`.
  static const lowStockThreshold = 5;

  /// Điều kiện dùng CHUNG cho thẻ "Sắp hết hàng" và danh sách bên dưới,
  /// để số trên thẻ luôn bằng số dòng trong danh sách.
  static const _lowStockWhere =
      'is_active = 1 AND stock <= $lowStockThreshold';

  /// 4 số liệu trong một câu SELECT (mỗi thẻ là một subquery COUNT / SUM).
  Future<AdminDashboardStats> getStats(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        (SELECT COUNT(*) FROM ${DbSchema.products}) AS total_products,
        (SELECT COUNT(*) FROM ${DbSchema.products} WHERE $_lowStockWhere)
          AS low_stock_count,
        (SELECT COUNT(*) FROM ${DbSchema.orders} WHERE status = ?)
          AS pending_order_count,
        (SELECT COALESCE(SUM(total), 0) FROM ${DbSchema.orders}
          WHERE status = ?) AS delivered_revenue
      ''',
      [OrderStatus.pending.dbValue, OrderStatus.delivered.dbValue],
    );

    return AdminDashboardStats.fromMap(rows.first);
  }

  /// Sản phẩm đang bán có tồn kho ≤ [lowStockThreshold], ít hàng nhất lên đầu.
  Future<List<Product>> getLowStockProducts(DatabaseExecutor db) async {
    final rows = await db.query(
      DbSchema.products,
      where: _lowStockWhere,
      orderBy: 'stock ASC, name ASC',
    );

    return rows.map(Product.fromMap).toList();
  }

  /// [limit] đơn mới nhất của mọi khách, kèm tên tài khoản đặt đơn.
  Future<List<AdminRecentOrder>> getRecentOrders(
    DatabaseExecutor db, {
    int limit = 5,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT o.*, u.full_name AS customer_name
      FROM ${DbSchema.orders} AS o
      LEFT JOIN ${DbSchema.users} AS u ON u.id = o.user_id
      ORDER BY o.created_at DESC, o.id DESC
      LIMIT ?
      ''',
      [limit],
    );

    return rows
        .map(
          (row) => AdminRecentOrder(
            order: Order.fromMap(row),
            customerName:
                row['customer_name'] as String? ??
                row['receiver_name'] as String,
          ),
        )
        .toList();
  }
}
