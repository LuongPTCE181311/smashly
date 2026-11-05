import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/providers/forgot_password_provider.dart';

import '../features/auth/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late ForgotPasswordProvider provider;

  setUp(() {
    repository = FakeAuthRepository();
    provider = ForgotPasswordProvider(repository);
  });
  tearDown(() {
    if (!provider.isDisposed) provider.dispose();
  });

  Future<String?> submit() => provider.submit(
    email: ' Customer@Smashly.COM ',
    phone: ' 0901234567 ',
    newPassword: 'NewPass123',
    confirmPassword: 'NewPass123',
  );

  test('P1. thành công trả email và chuyển đủ tham số', () async {
    expect(await submit(), 'customer@smashly.com');
    expect(repository.resetPasswordCalls, 1);
    expect(repository.lastResetPassword, (
      email: ' Customer@Smashly.COM ',
      phone: ' 0901234567 ',
      newPassword: 'NewPass123',
      confirmPassword: 'NewPass123',
    ));
    expect(provider.isSaving, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.fieldErrors, isEmpty);
  });

  test('P2. lỗi có field nằm đúng ô', () async {
    repository.resetPasswordError = const AppException(
      'SĐT sai',
      field: 'phone',
    );
    expect(await submit(), isNull);
    expect(provider.fieldErrors, {'phone': 'SĐT sai'});
    expect(provider.errorMessage, isNull);
    expect(provider.isSaving, isFalse);
  });

  test('P3. lỗi chung không gắn ô', () async {
    repository.resetPasswordError = const AppException(
      AuthRepository.resetMismatchMessage,
    );
    expect(await submit(), isNull);
    expect(provider.errorMessage, AuthRepository.resetMismatchMessage);
    expect(provider.fieldErrors, isEmpty);
    expect(provider.isSaving, isFalse);
  });

  test('P4. bắt StateError và tắt loading', () async {
    repository.resetPasswordError = StateError('boom');
    expect(await submit(), isNull);
    expect(provider.errorMessage, 'Không thể đặt lại mật khẩu lúc này');
    expect(provider.isSaving, isFalse);
  });

  test('P5. submit mới xóa cả lỗi chung và lỗi ô ngay khi chờ', () async {
    for (final error in [
      const AppException('SĐT sai', field: 'phone'),
      const AppException(AuthRepository.resetMismatchMessage),
    ]) {
      repository.resetPasswordError = error;
      await submit();
      if (error.field == null) {
        expect(provider.errorMessage, error.message);
      } else {
        expect(provider.fieldErrors[error.field], error.message);
      }
      repository.resetPasswordError = null;
      final hold = Completer<String>();
      repository.resetPasswordHold = hold;
      final pending = submit();
      try {
        expect(provider.isSaving, isTrue);
        expect(provider.errorMessage, isNull);
        expect(provider.fieldErrors, isEmpty);
      } finally {
        hold.complete('customer@smashly.com');
        await pending;
        repository.resetPasswordHold = null;
      }
    }
  });

  test('P6. clearFieldError chỉ xóa ô có lỗi và báo listener', () async {
    repository.resetPasswordError = const AppException(
      'SĐT sai',
      field: 'phone',
    );
    await submit();
    expect(provider.fieldErrors, {'phone': 'SĐT sai'});
    var notifications = 0;
    provider.addListener(() => notifications++);
    provider.clearFieldError('email');
    expect(notifications, 0);
    expect(provider.fieldErrors, {'phone': 'SĐT sai'});
    provider.clearFieldError('phone');
    expect(provider.fieldErrors, isEmpty);
    expect(notifications, 1);
    provider.clearFieldError('phone');
    expect(notifications, 1);
  });

  test('P7. submit lần hai bị bỏ qua khi đang lưu', () async {
    final hold = Completer<String>();
    repository.resetPasswordHold = hold;
    final first = submit();
    try {
      expect(provider.isSaving, isTrue);
      expect(await submit(), isNull);
      expect(repository.resetPasswordCalls, 1);
    } finally {
      hold.complete('customer@smashly.com');
      expect(await first, 'customer@smashly.com');
    }
    expect(provider.isSaving, isFalse);
  });

  test('P8. dispose trong khi chờ không ném khi hoàn tất', () async {
    final hold = Completer<String>();
    repository.resetPasswordHold = hold;
    var notifications = 0;
    provider.addListener(() => notifications++);
    final pending = submit();
    provider.dispose();
    final before = notifications;
    hold.complete('customer@smashly.com');
    expect(await pending, 'customer@smashly.com');
    expect(repository.resetPasswordCalls, 1);
    expect(notifications, before);
  });
}
