import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/utils/password_hasher.dart';
import 'package:smashly/data/daos/user_dao.dart';
import 'package:smashly/data/models/user.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  const dao = UserDao();

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
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'findByEmail reads a seeded customer and returns null when absent',
    () async {
      final customer = await dao.findByEmail(db, 'customer@smashly.com');
      final absent = await dao.findByEmail(db, 'missing@smashly.com');

      expect(customer, isNotNull);
      expect(customer!.email, 'customer@smashly.com');
      expect(customer.role, UserRole.customer);
      expect(absent, isNull);
    },
  );

  test('findAuthByEmail returns a hash matching PasswordHasher', () async {
    final result = await dao.findAuthByEmail(db, 'customer@smashly.com');

    expect(result, isNotNull);
    expect(result!.user.email, 'customer@smashly.com');
    expect(
      result.passwordHash,
      PasswordHasher.hash('customer@smashly.com', 'Customer@123'),
    );
  });

  test('findById queries only public columns', () async {
    final recorder = _QueryRecordingExecutor(db);

    final customer = await dao.findById(recorder, 2);

    expect(customer, isNotNull);
    expect(recorder.columns, isNotNull);
    expect(recorder.columns, isNot(contains('password_hash')));
    expect(recorder.lastRows, isNotEmpty);
    expect(recorder.lastRows!.first, isNot(contains('password_hash')));
  });

  test('existsByEmail reports seeded and missing emails', () async {
    expect(await dao.existsByEmail(db, 'customer@smashly.com'), isTrue);
    expect(await dao.existsByEmail(db, 'missing@smashly.com'), isFalse);
  });

  test(
    'insert rejects a duplicate email through the UNIQUE constraint',
    () async {
      final duplicate = User(
        fullName: 'Duplicate Customer',
        email: 'customer@smashly.com',
        phone: '0901111111',
        role: UserRole.customer,
      );

      await expectLater(
        dao.insert(db, duplicate, 'unused-hash'),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'insert persists a new customer and SQLite creates a UTC timestamp',
    () async {
      const password = 'NewCustomer@123';
      const email = 'new-customer@smashly.com';
      final newUser = User(
        fullName: 'New Customer',
        email: email,
        phone: '0909876543',
        role: UserRole.customer,
        address: '1 Nguyễn Huệ, TP. Hồ Chí Minh',
      );

      final id = await dao.insert(
        db,
        newUser,
        PasswordHasher.hash(email, password),
      );
      final inserted = await dao.findById(db, id);
      final auth = await dao.findAuthByEmail(db, email);

      expect(inserted, isNotNull);
      expect(inserted!.id, id);
      expect(inserted.fullName, newUser.fullName);
      expect(inserted.email, email);
      expect(inserted.phone, newUser.phone);
      expect(inserted.role, UserRole.customer);
      expect(inserted.address, newUser.address);
      expect(inserted.createdAt, isNotNull);
      expect(inserted.createdAt!.isUtc, isTrue);
      expect(auth!.passwordHash, PasswordHasher.hash(email, password));
    },
  );

  test('updateProfile changes only the three profile fields', () async {
    final before = await db.query(
      DbSchema.users,
      where: 'email = ?',
      whereArgs: ['customer@smashly.com'],
      limit: 1,
    );
    final userId = before.single['id'] as int;
    final oldHash = before.single['password_hash'];

    final changedRows = await dao.updateProfile(
      db,
      userId: userId,
      fullName: 'Nguyễn Minh Anh Updated',
      phone: '0907654321',
      address: '99 Lê Lợi, TP. Hồ Chí Minh',
    );
    final after = await db.query(
      DbSchema.users,
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final updated = after.single;

    expect(changedRows, 1);
    expect(updated['full_name'], 'Nguyễn Minh Anh Updated');
    expect(updated['phone'], '0907654321');
    expect(updated['address'], '99 Lê Lợi, TP. Hồ Chí Minh');
    expect(updated['email'], 'customer@smashly.com');
    expect(updated['role'], 'CUSTOMER');
    expect(updated['password_hash'], oldHash);
  });

  test('all seeded created_at values use the SQLite UTC format', () async {
    final rows = await db.rawQuery('''
      SELECT created_at FROM ${DbSchema.users}
      UNION ALL SELECT created_at FROM ${DbSchema.products}
      UNION ALL SELECT created_at FROM ${DbSchema.orders}
      UNION ALL SELECT created_at FROM ${DbSchema.wishlists}
    ''');
    final format = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$');

    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row['created_at'], matches(format));
    }
  });
}

class _QueryRecordingExecutor implements DatabaseExecutor {
  _QueryRecordingExecutor(this._delegate);

  final DatabaseExecutor _delegate;
  List<String>? columns;
  List<Map<String, Object?>>? lastRows;

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    this.columns = columns;
    final rows = await _delegate.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    lastRows = rows;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
