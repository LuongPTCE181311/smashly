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
