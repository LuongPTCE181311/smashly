import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'db_schema.dart';
import 'seed/seed_demo_data.dart';

/// Cửa duy nhất để mở SQLite. OWNER: TV1.
///
/// Cách dùng trong DAO:
///   final db = await DatabaseHelper.instance.database;
///   final rows = await db.query(DbSchema.products);
///
/// Mỗi máy tự tạo file smashly.db của riêng mình khi chạy app lần đầu:
/// tạo 9 bảng -> chạy seedDemoData(). File .db KHÔNG được commit lên Git.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  // Lưu Future (không lưu Database) để nhiều nơi gọi cùng lúc
  // vẫn chỉ mở DB đúng một lần.
  Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _open();

  Future<String> get _path async => join(await getDatabasesPath(), DbSchema.dbName);

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
