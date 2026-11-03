import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/providers/change_password_provider.dart';

import '../features/auth/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ChangePasswordProvider provider;

  setUp(() {
    repository = FakeAuthRepository();
    provider = ChangePasswordProvider(repository, userId: 2);
  });

  Future<bool> submit() => provider.submit(
    currentPassword: 'Customer@123',
    newPassword: 'NewPass123',
    confirmPassword: 'NewPass123',
  );

  test('thành công trả true, không có lỗi và tắt isSaving', () async {
    expect(await submit(), isTrue);

    expect(repository.changePasswordCalls, 1);
    expect(provider.isSaving, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.fieldErrors, isEmpty);
    expect(provider.accountGone, isFalse);
  });

  test('lỗi có field nằm ở fieldErrors của đúng ô', () async {
    repository.changePasswordError = const AppException(
      'Mật khẩu hiện tại chưa đúng',
      field: 'currentPassword',
    );

    expect(await submit(), isFalse);

    expect(provider.fieldErrors, {
      'currentPassword': 'Mật khẩu hiện tại chưa đúng',
    });
    expect(provider.errorMessage, isNull);
  });

  test('lỗi không field nằm ở errorMessage', () async {
    repository.changePasswordError = const AppException(
      'Không thể đổi mật khẩu lúc này',
    );

    expect(await submit(), isFalse);

    expect(provider.errorMessage, 'Không thể đổi mật khẩu lúc này');
    expect(provider.fieldErrors, isEmpty);
  });

  test('tài khoản không còn bật accountGone', () async {
    repository.changePasswordError = const AppException(
      AuthRepository.accountGoneMessage,
      field: AuthRepository.accountGoneField,
    );

    expect(await submit(), isFalse);

    expect(provider.accountGone, isTrue);
    expect(provider.errorMessage, AuthRepository.accountGoneMessage);
    expect(provider.fieldErrors, isEmpty);
  });

  test('lỗi lạ được thay bằng câu chung', () async {
    repository.changePasswordError = StateError('boom');

    expect(await submit(), isFalse);

    expect(provider.errorMessage, 'Không thể đổi mật khẩu lúc này');
  });

  test('lần submit mới xóa lỗi cũ', () async {
    repository.changePasswordError = const AppException(
      'Mật khẩu hiện tại chưa đúng',
      field: 'currentPassword',
    );
    await submit();
    repository.changePasswordError = null;

    expect(await submit(), isTrue);

    expect(provider.fieldErrors, isEmpty);
  });

  test('clearFieldError chỉ xóa đúng ô và báo listener', () async {
    repository.changePasswordError = const AppException(
      'Mật khẩu mới phải khác mật khẩu hiện tại',
      field: 'newPassword',
    );
    await submit();
    var notified = 0;
    provider.addListener(() => notified++);

    provider.clearFieldError('currentPassword');
    provider.clearFieldError('newPassword');

    expect(provider.fieldErrors, isEmpty);
    expect(notified, 1);
  });

  test('bấm lần hai khi đang lưu bị bỏ qua', () async {
    final slow = _SlowAuthRepository();
    final slowProvider = ChangePasswordProvider(slow, userId: 2);

    final first = slowProvider.submit(
      currentPassword: 'Customer@123',
      newPassword: 'NewPass123',
      confirmPassword: 'NewPass123',
    );
    final second = await slowProvider.submit(
      currentPassword: 'Customer@123',
      newPassword: 'NewPass123',
      confirmPassword: 'NewPass123',
    );

    expect(slowProvider.isSaving, isTrue);
    expect(second, isFalse);
    slow.done.complete();
    expect(await first, isTrue);
    expect(slow.changePasswordCalls, 1);
    expect(slowProvider.isSaving, isFalse);
  });
}

class _SlowAuthRepository extends FakeAuthRepository {
  final done = Completer<void>();

  @override
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    changePasswordCalls++;
    return done.future;
  }
}
