import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:smashly/core/database/database_helper.dart';
import 'package:smashly/core/database/db_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late String originalDatabasesPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    originalDatabasesPath = await databaseFactory.getDatabasesPath();
    tempDir = await Directory.systemTemp.createTemp('smashly_db_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeForTest();
    await databaseFactory.setDatabasesPath(originalDatabasesPath);
    await tempDir.delete(recursive: true);
  });

  test('mở DB lỗi thật → gọi lại mở được (không giữ Future đã lỗi)', () async {
    // Một THƯ MỤC trùng tên file DB: SQLite không mở được → lỗi thật, không tự tạo.
    final blocker = Directory(p.join(tempDir.path, DbSchema.dbName));
    await blocker.create();

    await expectLater(
      DatabaseHelper.instance.database,
      throwsA(isA<DatabaseException>()),
    );

    // Người dùng "giải phóng" chỗ chắn rồi bấm Thử lại.
    await blocker.delete();
    final db = await DatabaseHelper.instance.database;

    expect(db.isOpen, isTrue);
    final users = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbSchema.users}',
    );
    expect(users.first['c'], 3, reason: 'onCreate + seed đã chạy');
  });
}
