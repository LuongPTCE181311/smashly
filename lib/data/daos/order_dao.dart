import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_summary.dart';

class OrderDao {
  const OrderDao();

  Future<List<OrderSummary>> findSummariesByUser(
    DatabaseExecutor db,
    int userId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        o.*,
        (SELECT COUNT(*) FROM ${DbSchema.orderItems} WHERE order_id = o.id)
          AS item_count,
        fi.id AS first_id,
        fi.product_id AS first_product_id,
        fi.product_name AS first_product_name,
        fi.product_image AS first_product_image,
        fi.unit_price AS first_unit_price,
        fi.quantity AS first_quantity,
        fi.size AS first_size
      FROM ${DbSchema.orders} AS o
      LEFT JOIN ${DbSchema.orderItems} AS fi
        ON fi.id = (
          SELECT MIN(id) FROM ${DbSchema.orderItems} WHERE order_id = o.id
        )
      WHERE o.user_id = ?
      ORDER BY o.created_at DESC, o.id DESC
      ''',
      [userId],
    );

    return rows.map(_summaryFromRow).toList();
  }

  Future<Order?> findById(DatabaseExecutor db, int orderId) async {
    final rows = await db.query(
      DbSchema.orders,
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final items = await findItems(db, orderId);
    return Order.fromMap(rows.first, items: items);
  }

  Future<List<OrderItem>> findItems(DatabaseExecutor db, int orderId) async {
    final rows = await db.query(
      DbSchema.orderItems,
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );

    return rows.map(OrderItem.fromMap).toList();
  }

  /// Thêm đơn PENDING và trả về id. Mã đơn cần id nên truyền mã tạm,
  /// gọi [setOrderCode] ngay sau đó (trong cùng transaction).
  Future<int> insertOrder(
    DatabaseExecutor db, {
    required String tempCode,
    required int userId,
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    required String paymentMethod,
    required String? note,
    required int subtotal,
    required int shippingFee,
    required String createdAt,
  }) {
    return db.insert(DbSchema.orders, {
      'order_code': tempCode,
      'user_id': userId,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'note': note,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'total': subtotal + shippingFee,
      'created_at': createdAt,
    });
  }

  Future<int> setOrderCode(DatabaseExecutor db, int orderId, String code) {
    return db.update(
      DbSchema.orders,
      {'order_code': code},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  /// Chụp lại tên/ảnh/giá lúc mua: đổi giá hay xóa sản phẩm sau này không làm
  /// sai đơn cũ.
  Future<int> insertItem(
    DatabaseExecutor db, {
    required int orderId,
    required int productId,
    required String productName,
    required String productImage,
    required int unitPrice,
    required int quantity,
    required String size,
  }) {
    return db.insert(DbSchema.orderItems, {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'unit_price': unitPrice,
      'quantity': quantity,
      'size': size,
    });
  }

  /// Trừ kho nếu còn đủ; trả false khi sản phẩm ngừng bán / không đủ hàng.
  /// Điều kiện nằm trong câu UPDATE nên không bao giờ trừ quá tồn kho.
  Future<bool> decreaseStock(
    DatabaseExecutor db,
    int productId,
    int quantity,
    String updatedAt,
  ) async {
    final changed = await db.rawUpdate(
      'UPDATE ${DbSchema.products} SET stock = stock - ?, updated_at = ? '
      'WHERE id = ? AND is_active = 1 AND stock >= ?',
      [quantity, updatedAt, productId, quantity],
    );
    return changed == 1;
  }

  OrderSummary _summaryFromRow(Map<String, Object?> row) {
    final firstId = row['first_id'] as int?;

    return OrderSummary(
      order: Order.fromMap(row),
      itemCount: row['item_count'] as int,
      firstItem: firstId == null
          ? null
          : OrderItem.fromMap({
              'id': firstId,
              'order_id': row['id'],
              'product_id': row['first_product_id'],
              'product_name': row['first_product_name'],
              'product_image': row['first_product_image'],
              'unit_price': row['first_unit_price'],
              'quantity': row['first_quantity'],
              'size': row['first_size'],
            }),
    );
  }
}
