import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/providers/auth_provider.dart';

void main() {
  const admin = User(
    id: 7,
    fullName: 'Smashly Admin',
    email: 'admin@smashly.com',
    phone: '0900000000',
    role: UserRole.admin,
  );

  test('successful login sets success status, user, and admin state', () async {
    final repository = _FakeAuthRepository(user: admin);
    final provider = AuthProvider(repository);

    final result = await provider.login('admin@smashly.com', 'Admin@123');

    expect(result, admin);
    expect(provider.status, ViewStatus.success);
    expect(provider.currentUser, admin);
    expect(provider.isAdmin, isTrue);
  });

  test('field AppException populates field error without general message', () async {
    const error = AppException('Email không đúng định dạng', field: 'email');
    final repository = _FakeAuthRepository(user: admin, loginError: error);
    final provider = AuthProvider(repository);

    await provider.login('bad-email', 'Admin@123');

    expect(provider.fieldErrors['email'], error.message);
    expect(provider.errorMessage, isNull);
    expect(provider.status, ViewStatus.error);
  });

  test('StateError sets error status and fallback message', () async {
    final repository = _FakeAuthRepository(
      user: admin,
      loginError: StateError('simulated failure'),
    );
    final provider = AuthProvider(repository);

    await provider.login('admin@smashly.com', 'Admin@123');

    expect(provider.status, ViewStatus.error);
    expect(provider.status, isNot(ViewStatus.loading));
    expect(provider.errorMessage, 'Không thể đăng nhập lúc này');
  });

  test('second concurrent login is ignored while the first is loading', () async {
    final completer = Completer<User>();
    final repository = _FakeAuthRepository(
      user: admin,
      loginHandler: (_, _) => completer.future,
    );
    final provider = AuthProvider(repository);

    final firstLogin = provider.login('admin@smashly.com', 'Admin@123');
    final secondLogin = provider.login('admin@smashly.com', 'Admin@123');

    expect(repository.loginCalls, 1);
    expect(await secondLogin, isNull);

    completer.complete(admin);
    expect(await firstLogin, admin);
  });

  test('logout clears current user and sets empty status', () async {
    final repository = _FakeAuthRepository(user: admin);
    final provider = AuthProvider(repository);
    await provider.login('admin@smashly.com', 'Admin@123');

    await provider.logout();

    expect(provider.currentUser, isNull);
    expect(provider.status, ViewStatus.empty);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    required this.user,
    this.loginError,
    this.loginHandler,
  });

  final User user;
  final Object? loginError;
  final Future<User> Function(String email, String password)? loginHandler;
  int loginCalls = 0;

  @override
  Future<User> login(String email, String password) {
    loginCalls++;
    final handler = loginHandler;
    if (handler != null) return handler(email, password);
    final error = loginError;
    if (error != null) return Future<User>.error(error);
    return Future<User>.value(user);
  }

  @override
  Future<String> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async => email;

  @override
  Future<User?> getCurrentUser() async => user;

  @override
  Future<void> logout() async {}
}
