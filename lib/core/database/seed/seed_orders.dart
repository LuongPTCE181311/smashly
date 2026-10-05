import 'package:sqflite/sqflite.dart';

import '../db_schema.dart';
import 'seed_demo_data.dart';
import 'seed_users.dart';

/// OWNER: TV4.
///
/// 4 đơn mẫu cho customer@smashly.com, mỗi đơn một trạng thái, để
/// My Orders và timeline Order Detail có dữ liệu ngay từ đầu.
/// Ngày tính lùi từ lúc seed -> demo hôm nào cũng trông "mới".
/// Đơn đặt trực tiếp khi demo sẽ là PENDING -> đủ cả 5 trạng thái.
///
/// Lưu ý: đơn seed KHÔNG trừ tồn kho (chỉ checkout thật mới trừ).

const int freeShippingFrom = 1000000;
const int shippingFee = 30000;

Future<void> seedOrders(DatabaseExecutor db, DateTime now) async {
  const user = SeedUserIds.customer;
  const receiver = 'Nguyễn Minh Anh';
  const phone = '0901234567';
  const address = '12 Lê Lợi, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh';

  final orders = [
    _SeedOrder(
      id: 1,
      status: 'DELIVERED',
      payment: 'COD',
      createdAt: now.subtract(const Duration(days: 14)),
      items: [_SeedItem(2, 1), _SeedItem(20, 2)], // Astrox 77 Pro + BG66
      confirmedAfter: const Duration(hours: 2),
      shippedAfter: const Duration(days: 1),
      deliveredAfter: const Duration(days: 3),
    ),
    _SeedOrder(
      id: 2,
      status: 'SHIPPING',
      payment: 'E_WALLET',
      createdAt: now.subtract(const Duration(days: 3)),
      items: [_SeedItem(10, 1, size: '42')], // Power Cushion 65 Z3
      confirmedAfter: const Duration(hours: 1),
      shippedAfter: const Duration(days: 1),
    ),
    _SeedOrder(
      id: 3,
      status: 'CONFIRMED',
      payment: 'BANK_TRANSFER',
      createdAt: now.subtract(const Duration(days: 1)),
      items: [_SeedItem(13, 1, size: 'L')], // Game Shirt (có phí ship)
      confirmedAfter: const Duration(hours: 3),
    ),
    _SeedOrder(
      id: 4,
      status: 'CANCELLED',
      payment: 'COD',
      createdAt: now.subtract(const Duration(days: 7)),
      items: [_SeedItem(5, 1)], // Astrox 01 Ability
      cancelledAfter: const Duration(hours: 3),
    ),
  ];

  for (final o in orders) {
    // Snapshot tên/ảnh/giá từ bảng products tại thời điểm "mua".
    var subtotal = 0;
    final itemRows = <Map<String, Object?>>[];
    for (final item in o.items) {
      final rows = await db.query(
        DbSchema.products,
        columns: ['name', 'image_path', 'price'],
        where: 'id = ?',
        whereArgs: [item.productId],
      );
      final p = rows.first;
      final price = p['price'] as int;
      subtotal += price * item.quantity;
      itemRows.add({
        'order_id': o.id,
        'product_id': item.productId,
        'product_name': p['name'],
        'product_image': p['image_path'],
        'unit_price': price,
        'quantity': item.quantity,
        'size': item.size,
      });
    }
    final fee = subtotal >= freeShippingFrom ? 0 : shippingFee;

    DateTime? after(Duration? d) => d == null ? null : o.createdAt.add(d);
    String? time(DateTime? t) => t == null ? null : dbTime(t);

    await db.insert(DbSchema.orders, {
      'id': o.id,
      'order_code': orderCode(o.createdAt, o.id),
      'user_id': user,
      'status': o.status,
      'receiver_name': receiver,
      'receiver_phone': phone,
      'shipping_address': address,
      'payment_method': o.payment,
      'subtotal': subtotal,
      'shipping_fee': fee,
      'total': subtotal + fee,
      'created_at': dbTime(o.createdAt),
      'confirmed_at': time(after(o.confirmedAfter)),
      'shipped_at': time(after(o.shippedAfter)),
      'delivered_at': time(after(o.deliveredAfter)),
      'cancelled_at': time(after(o.cancelledAfter)),
    });
    for (final row in itemRows) {
      await db.insert(DbSchema.orderItems, row);
    }
  }

  // Giỏ hàng của customer có sẵn 1 món (để demo chọn/bỏ chọn).
  await db.insert(DbSchema.cartItems, {
    'cart_id': SeedUserIds.customer,
    'product_id': 19, // Yonex Super Grap
    'quantity': 1,
    'is_selected': 1,
    'added_at': dbTime(now),
  });
}

/// Mã đơn dễ đọc: SML-20261005-0007. Checkout thật cũng dùng hàm này.
String orderCode(DateTime date, int sequence) {
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${date.year}${two(date.month)}${two(date.day)}';
  return 'SML-$day-${sequence.toString().padLeft(4, '0')}';
}

class _SeedOrder {
  const _SeedOrder({
    required this.id,
    required this.status,
    required this.payment,
    required this.createdAt,
    required this.items,
    this.confirmedAfter,
    this.shippedAfter,
    this.deliveredAfter,
    this.cancelledAfter,
  });

  final int id;
  final String status;
  final String payment;
  final DateTime createdAt;
  final List<_SeedItem> items;
  final Duration? confirmedAfter;
  final Duration? shippedAfter;
  final Duration? deliveredAfter;
  final Duration? cancelledAfter;
}

class _SeedItem {
  const _SeedItem(this.productId, this.quantity, {this.size});
  final int productId;
  final int quantity;
  final String? size;
}
