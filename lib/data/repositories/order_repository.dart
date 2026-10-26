import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/enums.dart';
import '../../core/database/seed/seed_orders.dart' as seed;
import '../../core/utils/app_exception.dart';
import '../../core/utils/db_time.dart';
import '../daos/cart_dao.dart';
import 'cart_repository.dart';
import '../daos/order_dao.dart';
import '../models/order.dart';
import '../models/order_summary.dart';

class OrderRepository {
  const OrderRepository({
    required this._database,
    required this._orderDao,
    this._cartDao = const CartDao(),
  });

  final Future<Database> Function() _database;
  final OrderDao _orderDao;
  final CartDao _cartDao;

  /// Phí ship: miễn phí từ 1.000.000₫. Màn Checkout dùng chung hàm này để số
  /// hiển thị luôn khớp số lưu vào đơn.
  static int shippingFeeFor(int subtotal) =>
      subtotal >= seed.freeShippingFrom ? 0 : seed.shippingFee;

  /// Đặt hàng các món đang được chọn trong giỏ, trong MỘT transaction:
  /// kiểm tra + trừ kho -> tạo đơn -> chụp order_items -> xóa món đã mua khỏi
  /// giỏ. Bất kỳ bước nào lỗi (kể cả hết hàng) thì rollback toàn bộ: không có
  /// đơn nửa vời, kho và giỏ giữ nguyên. Hết hàng báo đúng tên sản phẩm.
  Future<Order> placeOrder({
    required int userId,
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    PaymentMethod paymentMethod = PaymentMethod.cod,
    String? note,
  }) async {
    if (receiverName.trim().isEmpty ||
        receiverPhone.trim().isEmpty ||
        shippingAddress.trim().isEmpty) {
      throw const AppException('Vui lòng nhập đầy đủ thông tin nhận hàng');
    }
    final trimmedNote = note?.trim();

    return _guard(
      'placeOrder',
      'Không thể đặt hàng. Vui lòng thử lại.',
      () async {
        final db = await _database();
        return db.transaction((txn) async {
          final cartId = await _cartDao.getOrCreateCartId(txn, userId);
          final items = (await _cartDao.findItems(
            txn,
            cartId,
          )).where((i) => i.isSelected).toList();
          if (items.isEmpty) {
            throw const AppException(
              'Bạn chưa chọn sản phẩm nào để thanh toán',
            );
          }

          final now = DateTime.now();
          final stamp = dbTime(now);

          for (final item in items) {
            final problem = CartRepository.sizeProblem(
              await _cartDao.findSizes(txn, item.productId),
              item.size,
            );
            if (problem != null) {
              throw AppException('"${item.name}": $problem');
            }
          }

          // Trừ kho trước: hết hàng thì ném lỗi ngay, chưa tạo gì cả.
          for (final item in items) {
            final ok = await _orderDao.decreaseStock(
              txn,
              item.productId,
              item.quantity,
              stamp,
            );
            if (!ok) {
              final stock = await _cartDao.findStock(txn, item.productId);
              throw AppException(
                stock == null
                    ? '"${item.name}" không còn được bán'
                    : stock <= 0
                    ? '"${item.name}" đã hết hàng'
                    : '"${item.name}" chỉ còn $stock sản phẩm',
              );
            }
          }

          final subtotal = items.fold<int>(0, (sum, i) => sum + i.lineTotal);
          final fee = shippingFeeFor(subtotal);
          final orderId = await _orderDao.insertOrder(
            txn,
            tempCode: 'TMP-${now.microsecondsSinceEpoch}',
            userId: userId,
            receiverName: receiverName.trim(),
            receiverPhone: receiverPhone.trim(),
            shippingAddress: shippingAddress.trim(),
            paymentMethod: paymentMethod.dbValue,
            note: trimmedNote == null || trimmedNote.isEmpty
                ? null
                : trimmedNote,
            subtotal: subtotal,
            shippingFee: fee,
            createdAt: stamp,
          );
          await _orderDao.setOrderCode(
            txn,
            orderId,
            seed.orderCode(now, orderId),
          );

          for (final item in items) {
            await _orderDao.insertItem(
              txn,
              orderId: orderId,
              productId: item.productId,
              productName: item.name,
              productImage: item.imagePath,
              unitPrice: item.price,
              quantity: item.quantity,
              size: item.size,
            );
          }

          await _cartDao.deleteSelected(txn, cartId);
          return (await _orderDao.findById(txn, orderId))!;
        });
      },
    );
  }

  Future<List<OrderSummary>> getOrderHistory(int userId) {
    return _guard(
      'getOrderHistory',
      'Không thể tải danh sách đơn hàng. Vui lòng thử lại.',
      () async {
        final db = await _database();
        return _orderDao.findSummariesByUser(db, userId);
      },
    );
  }

  Future<Order?> getOrderDetail(int orderId, {required int userId}) {
    return _guard(
      'getOrderDetail',
      'Không thể tải chi tiết đơn hàng. Vui lòng thử lại.',
      () async {
        final db = await _database();
        final order = await _orderDao.findById(db, orderId);
        if (order == null || order.userId != userId) return null;
        return order;
      },
    );
  }

  Future<T> _guard<T>(
    String action,
    String fallback,
    Future<T> Function() body,
  ) async {
    try {
      return await body();
    } on DatabaseException catch (error) {
      debugPrint('OrderRepository.$action: $error');
      throw AppException(fallback);
    }
  }
}
