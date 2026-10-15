import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_exception.dart';
import '../daos/order_dao.dart';
import '../models/order_summary.dart';

class OrderRepository {
  const OrderRepository({required this._database, required this._orderDao});

  final Future<Database> Function() _database;
  final OrderDao _orderDao;

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
