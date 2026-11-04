import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/providers/base_provider.dart';

class _TestProvider extends BaseProvider {}

void main() {
  test('notify gọi listener khi chưa dispose', () {
    final provider = _TestProvider();
    addTearDown(provider.dispose);
    var calls = 0;
    provider.addListener(() => calls++);

    provider.notify();

    expect(calls, 1);
    expect(provider.isDisposed, isFalse);
  });

  test('notify sau dispose không ném lỗi', () {
    final provider = _TestProvider();

    provider.dispose();

    expect(provider.isDisposed, isTrue);
    expect(provider.notify, returnsNormally);
  });
}
