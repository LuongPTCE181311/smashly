import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/features/shell/app_tab.dart';
import 'package:smashly/providers/shell_tab_provider.dart';

void main() {
  late ShellTabProvider provider;

  setUp(() {
    provider = ShellTabProvider();
  });

  tearDown(() {
    provider.dispose();
  });

  test('select đổi tab và notify một lần; chọn lại tab cũ không notify', () {
    var calls = 0;
    provider.addListener(() => calls++);
    expect(provider.tab, AppTab.home);

    provider.select(AppTab.cart);

    expect(provider.tab, AppTab.cart);
    expect(calls, 1);

    provider.select(AppTab.cart);

    expect(provider.tab, AppTab.cart);
    expect(calls, 1);
  });

  test('attach gán tab không notify, hasShell = true', () {
    var calls = 0;
    provider.addListener(() => calls++);
    expect(provider.hasShell, isFalse);

    provider.attach(AppTab.orders);

    expect(provider.tab, AppTab.orders);
    expect(provider.hasShell, isTrue);
    expect(calls, 0);
  });

  test('detach hết shell thì hasShell = false', () {
    provider.attach(AppTab.home);
    provider.attach(AppTab.shop);

    provider.detach();

    expect(provider.hasShell, isTrue);

    provider.detach();

    expect(provider.hasShell, isFalse);
  });
}
