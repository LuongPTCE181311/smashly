import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/core/utils/db_guard.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const tag = 'TestRepository.load';
  const fallback = 'Không thể tải dữ liệu';
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  test('body thành công → trả đúng giá trị', () async {
    final result = await runDb(tag, fallback, () async => 42);
    expect(result, 42);
  });

  test('lỗi SQLite thật → AppException có câu fallback', () async {
    await expectLater(
      runDb(tag, fallback, () => db.rawQuery('SELECT * FROM missing_table')),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          fallback,
        ),
      ),
    );
  });

  test('AppException → ném lại đúng instance', () async {
    const error = AppException('giữ nguyên');

    await expectLater(
      runDb<void>(tag, fallback, () async => throw error),
      throwsA(same(error)),
    );
  });

  test('StateError → ném lại nguyên vẹn', () async {
    final error = StateError('x');

    await expectLater(
      runDb<void>(tag, fallback, () async => throw error),
      throwsA(same(error)),
    );
  });
}
