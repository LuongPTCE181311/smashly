import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/validators.dart';

void main() {
  group('validateFullName', () {
    test('accepts a trimmed name with at least two characters', () {
      expect(validateFullName('  An  '), isNull);
    });

    test('rejects a name shorter than two characters', () {
      expect(validateFullName(' A '), isNotNull);
    });
  });

  group('validateEmail', () {
    test('accepts a valid email', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('rejects an invalid email', () {
      expect(validateEmail('user-at-example'), isNotNull);
    });

    test('rejects an email containing whitespace', () {
      expect(validateEmail('a b@example.com'), isNotNull);
    });
  });

  group('validatePhone', () {
    test('accepts ten digits starting with zero', () {
      expect(validatePhone('0901234567'), isNull);
    });

    test('rejects nine digits', () {
      expect(validatePhone('090123456'), isNotNull);
    });

    test('rejects ten digits that do not start with zero', () {
      expect(validatePhone('1901234567'), isNotNull);
    });

    test('rejects eleven digits', () {
      expect(validatePhone('09012345678'), isNotNull);
    });
  });

  group('validatePassword', () {
    test('accepts at least eight characters containing a letter and digit', () {
      expect(validatePassword('Abcdefg1'), isNull);
    });

    test('rejects a password shorter than eight characters', () {
      expect(validatePassword('Abc1234'), isNotNull);
    });

    test('rejects eight letters without a digit', () {
      expect(validatePassword('Abcdefgh'), isNotNull);
    });

    test('rejects eight digits without a letter', () {
      expect(validatePassword('12345678'), isNotNull);
    });
  });

  group('validateConfirmPassword', () {
    test('accepts matching passwords', () {
      expect(validateConfirmPassword('Password1', 'Password1'), isNull);
    });

    test('returns a distinct error for an empty confirmation', () {
      expect(
        validateConfirmPassword('Password1', ''),
        'Vui lòng nhập lại mật khẩu',
      );
    });

    test('returns a distinct error for a mismatched confirmation', () {
      final emptyMessage = validateConfirmPassword('Password1', '');
      final mismatchMessage =
          validateConfirmPassword('Password1', 'Password2');

      expect(
        mismatchMessage,
        'Mật khẩu xác nhận không khớp',
      );
      expect(emptyMessage, 'Vui lòng nhập lại mật khẩu');
      expect(emptyMessage, isNot(mismatchMessage));
    });
  });

  group('validateRequired', () {
    test('accepts a nonempty value', () {
      expect(validateRequired('value', 'Required'), isNull);
    });

    test('returns the supplied message for an empty value', () {
      expect(
        validateRequired('  ', 'Mật khẩu không được để trống'),
        'Mật khẩu không được để trống',
      );
    });
  });
}
