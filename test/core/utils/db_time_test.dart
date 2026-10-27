import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/db_time.dart';

void main() {
  group('dbTime', () {
    test('round-trips a fixed UTC time at second precision', () {
      final original = DateTime.utc(2026, 10, 6, 11, 52);

      expect(parseDbTime(dbTime(original)), original);
    });

    test('converts a local time to UTC before formatting', () {
      final local = DateTime(2026, 10, 6, 1);

      expect(dbTime(local), dbTime(local.toUtc()));
    });

    test('formats a fixed UTC time like SQLite CURRENT_TIMESTAMP', () {
      expect(
        dbTime(DateTime.utc(2026, 10, 5, 18)),
        '2026-10-05 18:00:00',
      );
    });
  });

  test('lexical timestamp order matches chronological order', () {
    final earlier = DateTime.utc(2026, 10, 5, 18);
    final later = DateTime.utc(2026, 10, 6, 11, 52);

    expect(dbTime(earlier).compareTo(dbTime(later)), lessThan(0));
  });

  group('parseDbTime', () {
    test('treats SQLite timestamp strings as UTC', () {
      expect(parseDbTime('2026-10-06 11:52:00').isUtc, isTrue);
    });

    test('accepts legacy ISO strings containing T', () {
      expect(
        parseDbTime('2026-10-06T11:52:00'),
        DateTime.utc(2026, 10, 6, 11, 52),
      );
    });
  });
}
