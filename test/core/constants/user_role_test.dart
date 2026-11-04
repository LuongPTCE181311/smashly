import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';

void main() {
  group('UserRole.label', () {
    test('customer → Khách hàng', () {
      expect(UserRole.customer.label, 'Khách hàng');
    });

    test('admin → Admin', () {
      expect(UserRole.admin.label, 'Admin');
    });
  });
}
