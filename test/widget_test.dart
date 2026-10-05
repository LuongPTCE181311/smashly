import 'package:flutter_test/flutter_test.dart';

import 'package:smashly/core/database/seed/seed_orders.dart';
import 'package:smashly/core/utils/password_hasher.dart';

// Test thuần Dart (không cần SQLite). Chạy: flutter test
void main() {
  group('PasswordHasher', () {
    test('cùng email + mật khẩu thì ra cùng hash', () {
      final a = PasswordHasher.hash('customer@smashly.com', 'Customer@123');
      final b = PasswordHasher.hash('  CUSTOMER@smashly.com ', 'Customer@123');
      expect(a, b);
    });

    test('sai mật khẩu thì verify = false', () {
      final h = PasswordHasher.hash('customer@smashly.com', 'Customer@123');
      expect(PasswordHasher.verify('customer@smashly.com', 'wrong', h), isFalse);
      expect(PasswordHasher.verify('customer@smashly.com', 'Customer@123', h), isTrue);
    });

    test('không lưu mật khẩu dạng chữ thường', () {
      final h = PasswordHasher.hash('admin@smashly.com', 'Admin@123');
      expect(h.contains('Admin@123'), isFalse);
      expect(h.length, 64);
    });
  });

  test('orderCode có dạng SML-YYYYMMDD-NNNN', () {
    expect(orderCode(DateTime(2026, 10, 5), 7), 'SML-20261005-0007');
  });
}
