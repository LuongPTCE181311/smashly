import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashly/core/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('1. Chưa có dữ liệu thì trả về null', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SessionService();

    expect(await service.getLoggedInUserId(), isNull);
  });

  test('2. Lưu phiên mới chỉ giữ userId và đọc lại đúng người dùng', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SessionService();

    await service.saveSession(5);

    expect(await service.getLoggedInUserId(), 5);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), unorderedEquals(['userId']));
    expect(prefs.getInt('userId'), 5);
    expect(prefs.containsKey('isLoggedIn'), isFalse);
  });

  test('3. Phiên cũ có cờ true vẫn đăng nhập và không đổi dữ liệu', () async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': true, 'userId': 2});
    final service = SessionService();

    expect(await service.getLoggedInUserId(), 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), unorderedEquals(['isLoggedIn', 'userId']));
    expect(prefs.getBool('isLoggedIn'), isTrue);
    expect(prefs.getInt('userId'), 2);
  });

  test('4. Phiên cũ có cờ false trả về null và không đổi dữ liệu', () async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': false, 'userId': 2});
    final service = SessionService();

    expect(await service.getLoggedInUserId(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), unorderedEquals(['isLoggedIn', 'userId']));
    expect(prefs.getBool('isLoggedIn'), isFalse);
    expect(prefs.getInt('userId'), 2);
  });

  test('5. Lưu lại phiên cũ cập nhật userId và xóa cờ isLoggedIn', () async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': true, 'userId': 2});
    final service = SessionService();

    await service.saveSession(7);

    expect(await service.getLoggedInUserId(), 7);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('userId'), 7);
    expect(prefs.containsKey('isLoggedIn'), isFalse);
  });

  test('6. Lưu phiên hai lần giữ người dùng của lần sau', () async {
    SharedPreferences.setMockInitialValues({});
    final service = SessionService();

    await service.saveSession(3);
    await service.saveSession(4);

    expect(await service.getLoggedInUserId(), 4);
  });

  test('7. Xóa phiên cũ loại bỏ cả hai key và trả về null', () async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': true, 'userId': 2});
    final service = SessionService();

    await service.clear();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('userId'), isFalse);
    expect(prefs.containsKey('isLoggedIn'), isFalse);
    expect(await service.getLoggedInUserId(), isNull);
  });

  test('8. Xóa phiên mới loại bỏ userId và trả về null', () async {
    SharedPreferences.setMockInitialValues({'userId': 5});
    final service = SessionService();

    await service.clear();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('userId'), isFalse);
    expect(prefs.containsKey('isLoggedIn'), isFalse);
    expect(await service.getLoggedInUserId(), isNull);
  });
}
