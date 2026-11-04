import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_rules.dart';
import '../../core/constants/enums.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/db_guard.dart';
import '../../core/utils/db_time.dart';
import '../../core/utils/order_code.dart';
import '../daos/cart_dao.dart';
import 'cart_repository.dart';
import '../daos/order_dao.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/order_summary.dart';

class OrderRepository {
  const OrderRepository({
    this._database = DatabaseHelper.open,
    this._orderDao = const OrderDao(),
    this._cartDao = const CartDao(),
  });

  final DatabaseOpener _database;
  final OrderDao _orderDao;
  final CartDao _cartDao;

  /// Phí ship của đơn có tạm tính [subtotal]; Checkout dùng chung để số hiển thị khớp số lưu.
  static int shippingFeeFor(int subtotal) =>
      subtotal >= AppRules.freeShippingFrom ? 0 : AppRules.shippingFee;

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

    return runDb(
      'OrderRepository.placeOrder',
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
          await _orderDao.setOrderCode(txn, orderId, orderCode(now, orderId));

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
    return runDb(
      'OrderRepository.getOrderHistory',
      'Không thể tải danh sách đơn hàng. Vui lòng thử lại.',
      () async {
        final db = await _database();
        return _orderDao.findSummariesByUser(db, userId);
      },
    );
  }

  Future<Order?> getOrderDetail(int orderId, {required int userId}) {
    return runDb(
      'OrderRepository.getOrderDetail',
      'Không thể tải chi tiết đơn hàng. Vui lòng thử lại.',
      () async {
        final db = await _database();
        final order = await _orderDao.findById(db, orderId);
        if (order == null || order.userId != userId) return null;
        return order;
      },
    );
  }

  Future<Order> cancelOrder(int orderId, {required int userId}) {
    return runDb(
      'OrderRepository.cancelOrder',
      'Không thể hủy đơn hàng. Vui lòng thử lại.',
      () async {
        final db = await _database();
        return db.transaction((txn) async {
          final order = await _orderDao.findById(txn, orderId);
          if (order == null || order.userId != userId) {
            throw const AppException('Không tìm thấy đơn hàng');
          }

          final stamp = dbTime(DateTime.now());
          final cancelled = await _orderDao.cancelPendingOrder(
            txn,
            orderId,
            stamp,
          );
          if (!cancelled) {
            throw const AppException(
              'Đơn hàng đã được xác nhận nên không thể hủy',
            );
          }

          await _restoreStock(txn, order.items, stamp);

          return (await _orderDao.findById(txn, orderId))!;
        });
      },
    );
  }

  /// Admin đổi trạng thái đơn (UC19). Luật chuyển nằm ở
  /// [OrderStatus.allowedNextStatuses]. Chạy trong MỘT transaction vì nhánh hủy
  /// ghi 2 bảng: hoàn kho lỗi thì trạng thái đơn cũng được rollback.
  Future<Order> updateStatus(
    int orderId, {
    required OrderStatus from,
    required OrderStatus to,
  }) async {
    if (!from.canTransitionTo(to)) {
      throw const AppException('Không thể chuyển đơn sang trạng thái này');
    }

    return runDb(
      'OrderRepository.updateStatus',
      'Không thể cập nhật trạng thái đơn hàng. Vui lòng thử lại.',
      () async {
        final db = await _database();
        return db.transaction((txn) async {
          final stamp = dbTime(DateTime.now());
          final updated = await _orderDao.updateStatus(
            txn,
            orderId,
            from: from,
            to: to,
            changedAt: stamp,
          );
          if (!updated) {
            throw const AppException(
              'Đơn đã được cập nhật ở nơi khác, vui lòng tải lại',
            );
          }

          final order = (await _orderDao.findById(txn, orderId))!;
          if (to == OrderStatus.cancelled) {
            await _restoreStock(txn, order.items, stamp);
          }
          return order;
        });
      },
    );
  }

  /// Cộng lại kho cho từng dòng đơn. Sản phẩm đã bị xóa (product_id null) thì
  /// bỏ qua.
  Future<void> _restoreStock(
    DatabaseExecutor txn,
    List<OrderItem> items,
    String stamp,
  ) async {
    for (final item in items) {
      final productId = item.productId;
      if (productId == null) continue;
      await _orderDao.increaseStock(txn, productId, item.quantity, stamp);
    }
  }
}
