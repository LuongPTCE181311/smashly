import 'dart:async';
import 'dart:collection';

import 'package:smashly/data/models/user.dart';
import 'package:smashly/data/repositories/auth_repository.dart';

/// Repository giả cho widget test màn Auth, dùng với `AuthProvider` thật.
///
/// `implements` (không `extends`): AuthRepository thêm method public thì file
/// này lỗi biên dịch, buộc cập nhật fake thay vì âm thầm gọi code thật.
class FakeAuthRepository implements AuthRepository {
  final _loginResults = Queue<Future<User> Function()>();
  final _restoreResults = Queue<Future<User?> Function()>();

  int loginCalls = 0;
  int registerCalls = 0;
  int restoreCalls = 0;

  /// Số lần `login`/`getCurrentUser` bị gọi mà chưa lập trình kết quả. Lỗi trả
  /// về khi đó bị `AuthProvider` (`catch (error)`) nuốt thành banner/trạng thái
  /// lỗi, nên test phải tự kiểm số này bằng 0 trong tearDown.
  int unexpectedCalls = 0;

  /// Lỗi `register` sẽ ném; `null` = thành công, trả email đã chuẩn hóa.
  Object? registerError;

  /// Lần `login` kế tiếp trả [user].
  void willLogin(User user) => _loginResults.add(() async => user);

  /// Lần `login` kế tiếp ném [error] (AppException hoặc lỗi bất kỳ).
  void willFailLogin(Object error) =>
      _loginResults.add(() async => throw error);

  /// Lần `login` kế tiếp treo cho tới khi test gọi `complete`/`completeError`.
  Completer<User> holdLogin() {
    final completer = Completer<User>();
    _loginResults.add(() => completer.future);
    return completer;
  }

  @override
  Future<User> login(String email, String password) {
    loginCalls++;
    if (_loginResults.isEmpty) {
      unexpectedCalls++;
      return Future.error(
        StateError(
          'FakeAuthRepository: login lần $loginCalls chưa được lập trình',
        ),
      );
    }
    return _loginResults.removeFirst()();
  }

  @override
  Future<String> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    registerCalls++;
    final error = registerError;
    if (error != null) throw error;
    return email.trim().toLowerCase();
  }

  /// Lần `getCurrentUser` kế tiếp trả [user] (`null` = không có session).
  void willRestore(User? user) => _restoreResults.add(() async => user);

  /// Lần `getCurrentUser` kế tiếp ném [error].
  void willFailRestore(Object error) =>
      _restoreResults.add(() async => throw error);

  /// Lần `getCurrentUser` kế tiếp treo (mô phỏng DB mở chậm).
  Completer<User?> holdRestore() {
    final completer = Completer<User?>();
    _restoreResults.add(() => completer.future);
    return completer;
  }

  @override
  Future<User?> getCurrentUser() {
    restoreCalls++;
    if (_restoreResults.isEmpty) {
      unexpectedCalls++;
      return Future.error(
        StateError(
          'FakeAuthRepository: getCurrentUser lần $restoreCalls chưa được lập trình',
        ),
      );
    }
    return _restoreResults.removeFirst()();
  }

  @override
  Future<void> logout() async {}
}
