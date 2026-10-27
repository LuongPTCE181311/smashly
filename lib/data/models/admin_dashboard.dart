import 'order.dart';
import 'product.dart';

/// 4 thẻ số liệu của Admin Dashboard (S13 · UC16).
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.pendingOrderCount,
    required this.deliveredRevenue,
  });

  /// Mọi sản phẩm trong bảng, gồm cả đang ẩn (khớp danh sách Admin Products).
  final int totalProducts;

  /// Sản phẩm đang bán có tồn kho ≤ 5 (kể cả 0).
  final int lowStockCount;

  /// Đơn có status = PENDING.
  final int pendingOrderCount;

  /// Tổng `orders.total` (VND) của các đơn DELIVERED.
  final int deliveredRevenue;

  factory AdminDashboardStats.fromMap(Map<String, Object?> map) {
    return AdminDashboardStats(
      totalProducts: map['total_products'] as int,
      lowStockCount: map['low_stock_count'] as int,
      pendingOrderCount: map['pending_order_count'] as int,
      deliveredRevenue: map['delivered_revenue'] as int,
    );
  }
}

/// Một dòng "Đơn gần đây": đơn hàng + tên tài khoản đặt đơn (users.full_name).
class AdminRecentOrder {
  const AdminRecentOrder({required this.order, required this.customerName});

  final Order order;
  final String customerName;
}

/// Toàn bộ dữ liệu một lần tải Dashboard.
class AdminDashboard {
  const AdminDashboard({
    required this.stats,
    required this.lowStockProducts,
    required this.recentOrders,
  });

  final AdminDashboardStats stats;
  final List<Product> lowStockProducts;
  final List<AdminRecentOrder> recentOrders;
}
