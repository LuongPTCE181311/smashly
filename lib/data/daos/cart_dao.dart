import 'package:sqflite/sqflite.dart';

import '../../core/database/db_schema.dart';

class CartDao {
  const CartDao();

  Future<int> createForUser(DatabaseExecutor db, int userId) {
    return db.insert(DbSchema.carts, {'user_id': userId});
  }
}
