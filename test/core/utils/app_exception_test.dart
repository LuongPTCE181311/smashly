import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/app_exception.dart';

void main() {
  const fallback = 'Có lỗi xảy ra. Vui lòng thử lại.';

  test('AppException có câu → trả đúng câu', () {
    expect(
      errorMessageOf(const AppException('Không tìm thấy sản phẩm'), fallback),
      'Không tìm thấy sản phẩm',
    );
  });

  test('AppException câu rỗng → trả fallback', () {
    expect(errorMessageOf(const AppException(''), fallback), fallback);
  });

  test('StateError → trả fallback', () {
    expect(errorMessageOf(StateError('x'), fallback), fallback);
  });
}
