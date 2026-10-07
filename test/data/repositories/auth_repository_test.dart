import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:smashly/core/services/session_service.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/daos/cart_dao.dart';
import 'package:smashly/data/daos/user_dao.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SessionService sessionService;
  late AuthRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sessionService = SessionService();
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DbSchema.version,
        onConfigure: DatabaseHelper.onConfigure,
        onCreate: DatabaseHelper.onCreate,
      ),
    );
    repository = AuthRepository(
      database: () async => db,
      userDao: const UserDao(),
      cartDao: const CartDao(),
      sessionService: sessionService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('login returns customer and admin with their roles', () async {
    final customer = await repository.login(
      'customer@smashly.com',
      'Customer@123',
    );
    final admin = await repository.login('admin@smashly.com', 'Admin@123');

    expect(customer.role, UserRole.customer);
    expect(admin.role, UserRole.admin);
  });

  test('login normalizes email whitespace and case', () async {
    final user = await repository.login(
      '  Customer@Smashly.com ',
      'Customer@123',
    );

    expect(user.email, 'customer@smashly.com');
  });

  test('successful login saves the user id in session', () async {
    final user = await repository.login('customer@smashly.com', 'Customer@123');

    expect(await sessionService.getLoggedInUserId(), user.id);
  });

  test('logout after login clears the session', () async {
    await repository.login('customer@smashly.com', 'Customer@123');

    await repository.logout();

    expect(await sessionService.getLoggedInUserId(), isNull);
  });

  test('getCurrentUser after login returns the same user', () async {
    final signedInUser = await repository.login(
      'customer@smashly.com',
      'Customer@123',
    );

    final currentUser = await repository.getCurrentUser();

    expect(currentUser?.id, signedInUser.id);
    expect(currentUser?.email, signedInUser.email);
  });

  test('wrong password and absent email use the same login message', () async {
    final wrongPassword = await _captureAppException(
      () => repository.login('customer@smashly.com', 'WrongPass123'),
    );
    final absentEmail = await _captureAppException(
      () => repository.login('missing@smashly.com', 'WrongPass123'),
    );

    expect(wrongPassword.message, 'Email hoặc mật khẩu chưa đúng');
    expect(absentEmail.message, wrongPassword.message);
  });

  test(
    'login validates email format and required password before database',
    () async {
      var databaseRequested = false;
      final repositoryWithoutDatabase = AuthRepository(
        database: () async {
          databaseRequested = true;
          return db;
        },
        userDao: const UserDao(),
        cartDao: const CartDao(),
        sessionService: sessionService,
      );

      final emailError = await _captureAppException(
        () => repositoryWithoutDatabase.login('invalid-email', 'Password1'),
      );
      final passwordError = await _captureAppException(
        () => repositoryWithoutDatabase.login('customer@smashly.com', '  '),
      );

      expect(emailError.field, 'email');
      expect(passwordError.message, 'Mật khẩu không được để trống');
      expect(passwordError.field, 'password');
      expect(databaseRequested, isFalse);
    },
  );

  test(
    'register creates one customer and one cart without logging in',
    () async {
      final email = await repository.register(
        fullName: '  Minh Anh ',
        email: '  MINH.ANH@example.com ',
        phone: '0901234567',
        password: 'Password123',
        confirmPassword: 'Password123',
      );
      final users = await db.query(
        DbSchema.users,
        where: 'email = ?',
        whereArgs: [email],
      );
      final carts = await db.query(
        DbSchema.carts,
        where: 'user_id = ?',
        whereArgs: [users.single['id']],
      );

      expect(email, 'minh.anh@example.com');
      expect(users, hasLength(1));
      expect(users.single['role'], 'CUSTOMER');
      expect(carts, hasLength(1));
      expect(await sessionService.getLoggedInUserId(), isNull);
    },
  );

  test(
    'duplicate email throws field-specific AppException without inserting',
    () async {
      final before = await _countRows(db, DbSchema.users);
      final error = await _captureAppException(
        () => repository.register(
          fullName: 'Another Customer',
          email: ' CUSTOMER@SMASHLY.COM ',
          phone: '0901111111',
          password: 'Password123',
          confirmPassword: 'Password123',
        ),
      );
      final after = await _countRows(db, DbSchema.users);

      expect(error.message, 'Email này đã được đăng ký');
      expect(error.field, 'email');
      expect(after, before);
    },
  );

  test(
    'SQLite unique failure becomes the field-specific duplicate message',
    () async {
      final repositoryWithUniqueFailure = AuthRepository(
        database: () async => db,
        userDao: const _UniqueEmailUserDao(),
        cartDao: const CartDao(),
        sessionService: sessionService,
      );
      final before = await _countRows(db, DbSchema.users);

      final error = await _captureAppException(
        () => repositoryWithUniqueFailure.register(
          fullName: 'Unique Race Customer',
          email: 'customer@smashly.com',
          phone: '0903333333',
          password: 'Password123',
          confirmPassword: 'Password123',
        ),
      );
      final after = await _countRows(db, DbSchema.users);

      expect(error.message, 'Email này đã được đăng ký');
      expect(error.field, 'email');
      expect(after, before);
    },
  );

  test('cart insert failure rolls back the user insert', () async {
    final failingRepository = AuthRepository(
      database: () async => db,
      userDao: const UserDao(),
      cartDao: const _FailingCartDao(),
      sessionService: sessionService,
    );

    final usersBefore = await _countRows(db, DbSchema.users);
    final cartsBefore = await _countRows(db, DbSchema.carts);

    await expectLater(
      failingRepository.register(
        fullName: 'Rollback Customer',
        email: 'rollback@example.com',
        phone: '0902222222',
        password: 'Password123',
        confirmPassword: 'Password123',
      ),
      throwsA(isA<AppException>()),
    );
    final usersAfter = await _countRows(db, DbSchema.users);
    final cartsAfter = await _countRows(db, DbSchema.carts);

    expect(usersAfter, usersBefore);
    expect(cartsAfter, cartsBefore);
  });

  test(
    'missing user referenced by session clears session and returns null',
    () async {
      await sessionService.saveSession(999999);

      final user = await repository.getCurrentUser();

      expect(user, isNull);
      expect(await sessionService.getLoggedInUserId(), isNull);
    },
  );

  test('getCurrentUser opens the database even without a session', () async {
    // Splash dựa vào getCurrentUser để mở DB: người dùng mới (chưa có session)
    // cũng phải gặp lỗi DB ở Splash (có nút Thử lại), không phải muộn ở Login.
    var openCalls = 0;
    final countingRepository = AuthRepository(
      database: () async {
        openCalls++;
        return db;
      },
      userDao: const UserDao(),
      cartDao: const CartDao(),
      sessionService: sessionService,
    );

    final user = await countingRepository.getCurrentUser();

    expect(user, isNull);
    expect(openCalls, 1);
  });
}

Future<AppException> _captureAppException(
  Future<Object?> Function() action,
) async {
  try {
    await action();
  } on AppException catch (error) {
    return error;
  }
  throw StateError('Expected AppException');
}

Future<int> _countRows(Database db, String table) async {
  final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
  return rows.single['count'] as int;
}

class _FailingCartDao extends CartDao {
  const _FailingCartDao();

  @override
  Future<int> createForUser(DatabaseExecutor db, int userId) async {
    return super.createForUser(db, 999999);
  }
}

class _UniqueEmailUserDao extends UserDao {
  const _UniqueEmailUserDao();

  @override
  Future<bool> existsByEmail(DatabaseExecutor db, String email) async => false;
}
