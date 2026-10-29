import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/models/cart_item.dart';
import 'package:smashly/data/repositories/cart_repository.dart';
import 'package:smashly/providers/cart_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Removing several cart lines at once (a whole multi-size product) and a full
/// undo: DAO -> Repository -> Provider, on real SQLite.
void main() {
  const user = 3; // newbie: empty cart
  const dao = CartDao();

  late Database db;
  late CartRepository repo;

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
    repo = CartRepository(database: () async => db, cartDao: dao);
  });

  tearDown(() => db.close());

  /// Cart: racket (2), shoe 41/42/43 (10), string (20), added in that order so the
  /// cart shows newest first: 20, 10/43, 10/42, 10/41, 2.
  Future<void> fillCart() async {
    await repo.addToCart(userId: user, productId: 2);
    await repo.addToCart(userId: user, productId: 10, size: '41');
    await repo.addToCart(userId: user, productId: 10, size: '42', quantity: 2);
    await repo.addToCart(userId: user, productId: 10, size: '43', quantity: 3);
    await repo.addToCart(userId: user, productId: 20);
  }

  Future<int> lineCount() async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbSchema.cartItems} ci '
      'JOIN ${DbSchema.carts} c ON c.id = ci.cart_id WHERE c.user_id = ?',
      [user],
    );
    return rows.first['c'] as int;
  }

  group('CartDao.deleteLines', () {
    test(
      'chỉ xóa đúng các dòng được chỉ định, trả về số dòng đã xóa',
      () async {
        await fillCart();
        final items = await repo.loadItems(user);
        final shoes = items.where((i) => i.productId == 10).toList();

        final deleted = await dao.deleteLines(db, [
          for (final i in shoes) i.id,
        ]);

        expect(deleted, 3);
        final left = await repo.loadItems(user);
        expect(left.map((i) => i.productId).toSet(), {2, 20});
      },
    );

    test('danh sách rỗng hoặc id không tồn tại: không xóa gì', () async {
      await fillCart();

      expect(await dao.deleteLines(db, const []), 0);
      expect(await dao.deleteLines(db, const [987654, 987655]), 0);
      expect(await lineCount(), 5);
    });

    test(
      'không đụng tới giỏ của người khác dù trùng id không tồn tại',
      () async {
        await fillCart();
        final other = await repo.loadItems(2); // customer: 1 seeded line

        await dao.deleteLines(db, [
          for (final i in await repo.loadItems(user)) i.id,
        ]);

        expect(await repo.loadItems(user), isEmpty);
        expect((await repo.loadItems(2)).map((i) => i.id), [
          for (final i in other) i.id,
        ]);
      },
    );
  });

  group('CartRepository.removeMany / restoreMany', () {
    test('xóa cả sản phẩm nhiều size rồi hoàn tác: đủ size, số lượng, trạng thái chọn', () async {
      await fillCart();
      final shoes = (await repo.loadItems(user))
          .where((i) => i.productId == 10)
          .toList();
      // Untick size 42 to check that the selection is kept on undo.
      await repo.setSelected(shoes.firstWhere((i) => i.size == '42'), false);
      final before = (await repo.loadItems(user))
          .where((i) => i.productId == 10)
          .toList();

      await repo.removeMany(before);
      expect(
        (await repo.loadItems(user)).where((i) => i.productId == 10),
        isEmpty,
      );

      await repo.restoreMany(user, before);
      final after = (await repo.loadItems(user))
          .where((i) => i.productId == 10)
          .toList();

      Map<String, (int, bool)> summary(List<CartItem> list) => {
        for (final i in list) i.size: (i.quantity, i.isSelected),
      };
      expect(summary(after), summary(before));
      expect(summary(after)['42'], (2, false));
    });

    test(
      'hoàn tác là tất cả hoặc không: một dòng trùng thì không chèn dòng nào',
      () async {
        await fillCart();
        final items = await repo.loadItems(user);
        final shoe41 = items.firstWhere((i) => i.size == '41');
        final shoe42 = items.firstWhere((i) => i.size == '42');
        await repo.removeMany([shoe42]);
        final before = await lineCount();

        // size 42 is missing -> can be inserted; size 41 exists -> violates UNIQUE.
        await expectLater(
          repo.restoreMany(user, [shoe42, shoe41]),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              'Không thể hoàn tác',
            ),
          ),
        );

        expect(
          await lineCount(),
          before,
          reason: 'transaction rollback, 42 không lọt vào',
        );
      },
    );

    test('lỗi ghi DB được đổi thành câu tiếng Việt', () async {
      await fillCart();
      final items = await repo.loadItems(user);
      await db.execute('DROP TABLE ${DbSchema.cartItems}');

      await expectLater(
        repo.removeMany(items),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'Không thể xóa sản phẩm',
          ),
        ),
      );
    });
  });

  group('CartProvider.removeMany', () {
    late CartProvider cart;

    setUp(() async {
      await fillCart();
      cart = CartProvider(repo)..updateUser(user);
      await pumpEventQueue();
      while (cart.items.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });

    tearDown(() => cart.dispose());

    List<CartItem> shoes() =>
        cart.items.where((i) => i.productId == 10).toList();

    test('gỡ khỏi danh sách ngay, trước khi DB trả lời', () async {
      final removing = cart.removeMany(shoes());

      expect(cart.items.map((i) => i.productId).toSet(), {2, 20});
      expect(cart.itemCount, 2);

      expect(await removing, isNull);
      expect(await lineCount(), 2);
    });

    test(
      'hoàn tác một lần đưa lại cả nhóm, đúng thứ tự cũ theo thời gian thêm',
      () async {
        final order = [for (final i in cart.items) '${i.productId}/${i.size}'];
        await cart.removeMany(shoes());
        expect(cart.canUndoRemove, isTrue);

        expect(await cart.undoRemove(), isNull);

        expect(cart.canUndoRemove, isFalse);
        expect(cart.itemCount, 5);
        expect({
          for (final i in cart.items) '${i.productId}/${i.size}',
        }, order.toSet());
        expect(
          cart.items
              .where((i) => i.productId == 10)
              .map((i) => i.quantity)
              .toList()
            ..sort(),
          [1, 2, 3],
        );
      },
    );

    test('hoàn tác lần hai không làm gì (đã dùng)', () async {
      await cart.removeMany(shoes());
      await cart.undoRemove();

      expect(await cart.undoRemove(), isNull);
      expect(cart.itemCount, 5);
    });

    test('lỗi ghi DB thật: các dòng về đúng vị trí cũ, có câu báo lỗi, không hoàn tác được', () async {
      final before = [for (final i in cart.items) i.id];
      await db.execute('DROP TABLE ${DbSchema.cartItems}');

      final error = await cart.removeMany(shoes());

      expect(error, 'Không thể xóa sản phẩm');
      expect([for (final i in cart.items) i.id], before);
      expect(cart.canUndoRemove, isFalse);
    });

    test(
      'xóa dòng không có trong giỏ: không đổi gì, không thông báo',
      () async {
        var notified = 0;
        cart.addListener(() => notified++);
        final stranger = CartItem(
          id: 99999,
          productId: 1,
          name: 'x',
          imagePath: 'x',
          price: 1,
          stock: 1,
          quantity: 1,
          size: '',
          isSelected: true,
        );

        expect(await cart.removeMany([stranger]), isNull);
        expect(await cart.removeMany(const []), isNull);

        expect(cart.itemCount, 5);
        expect(notified, 0);
        expect(cart.canUndoRemove, isFalse);
      },
    );

    test(
      'đổi tài khoản thì không còn hoàn tác được xóa của người trước',
      () async {
        await cart.removeMany(shoes());
        expect(cart.canUndoRemove, isTrue);

        cart.updateUser(2);

        expect(cart.canUndoRemove, isFalse);
        expect(await cart.undoRemove(), isNull);
      },
    );

    test('xóa một dòng lẻ vẫn dùng chung đường hoàn tác', () async {
      final one = shoes().first;

      expect(await cart.remove(one), isNull);
      expect(cart.itemCount, 4);
      await cart.undoRemove();

      expect(cart.itemCount, 5);
    });
  });
}
