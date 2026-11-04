import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_schema.dart';
import 'seed/seed_demo_data.dart';

/// Hàm trả về DB đang mở; Repository nhận kiểu này để test truyền DB riêng.
typedef DatabaseOpener = Future<Database> Function();

/// Cửa duy nhất để mở SQLite; Repository mở DB qua [DatabaseHelper.open].
///
/// Mỗi máy tự tạo file smashly.db khi chạy lần đầu: tạo bảng rồi seed dữ
/// liệu demo. File .db không commit lên Git.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  /// Mở (hoặc lấy lại) DB dùng chung của app.
  static Future<Database> open() => instance.database;

  /// Xóa DB trên máy rồi tạo lại và seed.
  static Future<void> reset() => instance.resetDatabase();

  // Lưu Future (không lưu Database) để nhiều nơi gọi cùng lúc
  // vẫn chỉ mở DB đúng một lần.
  Future<Database>? _dbFuture;

  /// Mở lỗi thì bỏ Future đã lỗi, để lần gọi sau (nút Thử lại ở Splash) mở lại
  /// thật sự thay vì nhận lại đúng lỗi cũ.
  Future<Database> get database {
    final existing = _dbFuture;
    if (existing != null) return existing;

    final opening = _open();
    _dbFuture = opening;
    opening.then<void>(
      (_) {},
      onError: (Object _) {
        // Chỉ xóa nếu vẫn là chính lần mở này (không xóa nhầm lần mở mới hơn).
        if (identical(_dbFuture, opening)) _dbFuture = null;
      },
    );
    return opening;
  }

  Future<String> get _path async =>
      join(await getDatabasesPath(), DbSchema.dbName);

  Future<Database> _open() async {
    return openDatabase(
      await _path,
      version: DbSchema.version,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> onCreate(Database db, int version) async {
    await _createTables(db);
    await seedDemoData(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await _dropTables(db);
    await _createTables(db);
    await seedDemoData(db);
  }

  static Future<void> _createTables(DatabaseExecutor db) async {
    for (final sql in DbSchema.createStatements) {
      await db.execute(sql);
    }
  }

  static Future<void> _dropTables(DatabaseExecutor db) async {
    for (final table in DbSchema.tablesInDropOrder) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
  }

  /// Đóng DB (nếu đã mở) và quên Future đang giữ, để test sau bắt đầu sạch.
  @visibleForTesting
  Future<void> closeForTest() async {
    final current = _dbFuture;
    _dbFuture = null;
    if (current == null) return;
    try {
      await (await current).close();
    } on DatabaseException {
      // Lần mở trước đã lỗi: không có gì để đóng.
    }
  }

  /// Xóa DB trên máy này rồi tạo lại + seed. Gắn vào nút
  /// "Reset demo data" (chỉ hiện ở bản debug).
  Future<void> resetDatabase() async {
    final current = _dbFuture;
    _dbFuture = null;
    if (current != null) {
      await (await current).close();
    }
    await deleteDatabase(await _path);
    await database;
  }
}
