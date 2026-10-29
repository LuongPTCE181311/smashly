import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Data-layer performance of the cart with a very large cart (more than a user
/// can really build) to catch full table scans or N+1 loops early.
///
/// The time limits are deliberately loose (to run on slow machines / CI); the main
/// checks are that the query plan uses indexes and DB calls do not grow with N.
void main() {
  const user = 3; // newbie: empty cart
  const lines = 3000;

  late Database db;
  late CartRepository repo;
  late int cartId;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbSchema.version,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: DatabaseHelper.onCreate,
      ),
    );
    repo = CartRepository(database: () async => db, cartDao: const CartDao());
    cartId = await const CartDao().getOrCreateCartId(db, user);
    await _fill(db, cartId, lines);
  });

  tearDown(() => db.close());

  test(
    'đọc giỏ $lines dòng chỉ trong một truy vấn, đủ và đúng thứ tự',
    () async {
      final watch = Stopwatch()..start();
      final items = await repo.loadItems(user);
      watch.stop();

      debugPrint(
        '[perf] loadItems($lines dòng): ${watch.elapsedMilliseconds} ms',
      );
      expect(items, hasLength(lines));
      expect(items.every((i) => i.name.isNotEmpty && i.price > 0), isTrue);
      expect(watch.elapsedMilliseconds, lessThan(3000));
    },
  );

  test('truy vấn giỏ dùng chỉ mục, không quét toàn bảng cart_items', () async {
    final plan = await db.rawQuery(
      'EXPLAIN QUERY PLAN '
      'SELECT ci.id, p.name FROM ${DbSchema.cartItems} ci '
      'JOIN ${DbSchema.products} p ON p.id = ci.product_id '
      'WHERE ci.cart_id = ? ORDER BY ci.added_at DESC, ci.id DESC',
      [cartId],
    );
    final detail = plan.map((r) => r['detail'] as String).join('\n');
    debugPrint('[perf] kế hoạch truy vấn:\n$detail');

    expect(detail, contains('SEARCH ci'));
    expect(detail, isNot(contains('SCAN ci')));
    expect(detail, isNot(contains('SCAN p')), reason: 'JOIN dùng khóa chính');
  });

  test('tra dòng trùng khi thêm vào giỏ vẫn dùng chỉ mục UNIQUE', () async {
    final plan = await db.rawQuery(
      'EXPLAIN QUERY PLAN '
      'SELECT ci.id FROM ${DbSchema.cartItems} ci '
      'WHERE ci.cart_id = ? AND ci.product_id = ? AND ci.size = ?',
      [cartId, 5, 's1'],
    );
    final detail = plan.map((r) => r['detail'] as String).join('\n');

    expect(detail, contains('SEARCH ci'));
    expect(detail, isNot(contains('SCAN ci')));
  });

  test(
    'thêm vào giỏ lớn: thời gian mỗi lần không phụ thuộc kích thước giỏ',
    () async {
      const rounds = 30;
      final watch = Stopwatch()..start();
      for (var i = 0; i < rounds; i++) {
        // Always hits an existing line (accumulate path); product 19 has stock 80.
        await repo.addToCart(userId: user, productId: 19);
      }
      watch.stop();
      final perCall = watch.elapsedMilliseconds / rounds;

      debugPrint(
        '[perf] addToCart trong giỏ $lines dòng: '
        '${perCall.toStringAsFixed(1)} ms/lần',
      );
      expect(perCall, lessThan(200));
      final row = await db.query(
        DbSchema.cartItems,
        where: 'cart_id = ? AND product_id = ? AND size = ?',
        whereArgs: [cartId, 19, ''],
      );
      // _fill already created this line with quantity 1.
      expect(row.single['quantity'], 1 + rounds);
    },
  );

  test(
    'đổi trạng thái chọn cả giỏ là một lệnh UPDATE, không lặp theo dòng',
    () async {
      final watch = Stopwatch()..start();
      await repo.setAllSelected(user, false);
      watch.stop();

      debugPrint(
        '[perf] setAllSelected($lines dòng): ${watch.elapsedMilliseconds} ms',
      );
      final selected = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM ${DbSchema.cartItems} '
        'WHERE cart_id = ? AND is_selected = 1',
        [cartId],
      );
      expect(selected.first['c'], 0);
      expect(watch.elapsedMilliseconds, lessThan(1000));
    },
  );
}

/// Inserts [count] different cart lines (product x size) with one batch.
Future<void> _fill(Database db, int cartId, int count) async {
  final products = await db.query(DbSchema.products, columns: ['id']);
  final batch = db.batch();
  var n = 0;
  for (var size = 0; n < count; size++) {
    for (final p in products) {
      if (n >= count) break;
      batch.insert(DbSchema.cartItems, {
        'cart_id': cartId,
        'product_id': p['id'],
        // The no-size '' line appears once per product, the rest are s1, s2, ...
        'size': size == 0 ? '' : 's$size',
        'quantity': 1,
      });
      n++;
    }
  }
  await batch.commit(noResult: true);
}
