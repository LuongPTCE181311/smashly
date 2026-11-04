import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/data/models/user.dart';

void main() {
  group('User.initial', () {
    for (final (fullName, expected) in [
      ('Phạm Thanh Lượng', 'L'),
      ('  nguyễn   anh  ', 'A'),
      ('SMASHLY Admin', 'A'),
      ('Bảo', 'B'),
      ('', '?'),
      ('   ', '?'),
    ]) {
      test('tên "$fullName" → "$expected"', () {
        final user = User(
          fullName: fullName,
          email: 'customer@smashly.com',
          phone: '0901234567',
          role: UserRole.customer,
        );

        expect(user.initial, expected);
      });
    }
  });
}
