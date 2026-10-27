import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';
import 'package:smashly/core/utils/app_exception.dart';
import 'package:smashly/data/models/user.dart';
import 'package:smashly/data/repositories/auth_repository.dart';
import 'package:smashly/providers/auth_provider.dart';

import '../features/auth/fake_auth_repository.dart';

const _customer = User(
  id: 2,
  fullName: 'Nguyễn Văn An',
  email: 'an@smashly.com',
  phone: '0901234567',
  role: UserRole.customer,
  address: '12 Lê Lợi, Quận 1',
);
const _updated = User(
  id: 2,
  fullName: 'Nguyễn Văn Bình',
  email: 'an@smashly.com',
  phone: '0912345678',
  role: UserRole.customer,
);

/// Trạng thái phiên phải giữ nguyên khi lưu hồ sơ thất bại (P5).
void _expectSessionUntouched(AuthProvider auth) {
  expect(auth.status, ViewStatus.success);
  expect(auth.isLoading, isFalse);
  expect(auth.currentUser, same(_customer));
  expect(auth.isLoggedIn, isTrue);
  expect(auth.errorMessage, isNull);
  expect(auth.fieldErrors, isEmpty);
}

void main() {
  late FakeAuthRepository repo;
  late AuthProvider auth;

  setUp(() async {
    repo = FakeAuthRepository()..willLogin(_customer);
    auth = AuthProvider(repo);
    addTearDown(auth.dispose);
    await auth.login(_customer.email, 'Customer@123');
    expect(auth.status, ViewStatus.success);
  });

  tearDown(() => expect(repo.unexpectedCalls, 0));

  Future<bool> save() => auth.updateProfile(
    fullName: _updated.fullName,
    phone: _updated.phone,
    address: null,
  );

  test(
    '1. lưu thành công → currentUser mới, isSaving về false, status không đổi',
    () async {
      repo.willUpdate(_updated);

      expect(await save(), isTrue);

      expect(auth.currentUser, same(_updated));
      expect(auth.isSaving, isFalse);
      expect(auth.status, ViewStatus.success);
      expect(repo.lastUpdate?.userId, _customer.id);
      expect(repo.lastUpdate?.fullName, _updated.fullName);
    },
  );

  test('2. lỗi field → saveFieldErrors; phiên giữ nguyên', () async {
    repo.willFailUpdate(
      const AppException('Số điện thoại không hợp lệ', field: 'phone'),
    );

    expect(await save(), isFalse);

    expect(auth.saveFieldErrors['phone'], 'Số điện thoại không hợp lệ');
    expect(auth.saveErrorMessage, isNull);
    expect(auth.isSaving, isFalse);
    _expectSessionUntouched(auth);
  });

  test('3. Error (không phải Exception) → câu dự phòng; không kẹt isSaving; phiên giữ nguyên', () async {
    repo.willFailUpdate(StateError('hỏng'));

    expect(await save(), isFalse);

    expect(auth.saveErrorMessage, 'Không thể lưu lúc này');
    expect(auth.isSaving, isFalse);
    _expectSessionUntouched(auth);
  });

  test('4. gọi lần 2 khi đang lưu → bỏ qua', () async {
    final pending = repo.holdUpdate();

    final first = save();
    expect(auth.isSaving, isTrue);
    expect(await save(), isFalse);
    expect(repo.updateCalls, 1);

    pending.complete(_updated);
    expect(await first, isTrue);
  });

  test(
    '5. đăng xuất trong lúc đang lưu → lưu xong không hồi sinh phiên',
    () async {
      final pending = repo.holdUpdate();

      final saving = save();
      await auth.logout();
      expect(auth.currentUser, isNull);

      pending.complete(_updated);
      await saving;

      expect(auth.currentUser, isNull);
      expect(auth.isLoggedIn, isFalse);
    },
  );

  test('6. clearSaveErrors() chỉ xóa lỗi lưu, không đụng lỗi phiên', () async {
    repo
      ..willFailLogin(const AppException('Email không hợp lệ', field: 'email'))
      ..willFailUpdate(
        const AppException('Số điện thoại không hợp lệ', field: 'phone'),
      );
    await auth.login('x', 'y');
    await save();
    expect(auth.fieldErrors['email'], isNotNull);
    expect(auth.saveFieldErrors['phone'], isNotNull);

    auth.clearSaveErrors();

    expect(auth.saveFieldErrors, isEmpty);
    expect(auth.saveErrorMessage, isNull);
    expect(auth.fieldErrors['email'], 'Email không hợp lệ');
  });

  test('7. tài khoản không còn tồn tại (P10) → đăng xuất, báo lỗi', () async {
    repo.willFailUpdate(
      const AppException(
        AuthRepository.accountGoneMessage,
        field: AuthRepository.accountGoneField,
      ),
    );

    expect(await save(), isFalse);

    expect(auth.saveErrorMessage, AuthRepository.accountGoneMessage);
    expect(auth.currentUser, isNull);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.status, ViewStatus.empty);
    expect(repo.logoutCalls, 1);
    expect(auth.isSaving, isFalse);
  });

  test('8. resetDemoData → gọi repo, phiên về empty', () async {
    await auth.resetDemoData();

    expect(repo.resetCalls, 1);
    expect(auth.currentUser, isNull);
    expect(auth.status, ViewStatus.empty);
  });

  test('9. P10 logout lỗi vẫn kết thúc đăng xuất và thoát trạng thái lưu', () async {
    repo
      ..logoutError = StateError('prefs hỏng')
      ..willFailUpdate(
        const AppException(
          AuthRepository.accountGoneMessage,
          field: AuthRepository.accountGoneField,
        ),
      );

    expect(await save(), isFalse);

    expect(repo.logoutCalls, 1);
    expect(auth.currentUser, isNull);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.status, ViewStatus.empty);
    expect(auth.isSaving, isFalse);
    expect(auth.isLoading, isFalse);
    expect(auth.saveErrorMessage, AuthRepository.accountGoneMessage);
  });

  test('10. reset lỗi xóa user và không kẹt loading', () async {
    final failingRepo = _ResetFailingRepository()..willLogin(_customer);
    final failingAuth = AuthProvider(failingRepo);
    addTearDown(failingAuth.dispose);
    await failingAuth.login(_customer.email, 'Customer@123');

    await failingAuth.resetDemoData();

    expect(failingRepo.resetCalls, 1);
    expect(failingRepo.unexpectedCalls, 0);
    expect(failingAuth.currentUser, isNull);
    expect(failingAuth.status, ViewStatus.error);
    expect(failingAuth.errorMessage, isNotNull);
    expect(failingAuth.errorMessage, isNot(isEmpty));
    expect(failingAuth.errorMessage, isNot(contains('reset failure')));
    expect(failingAuth.isLoading, isFalse);
    expect(failingAuth.isSaving, isFalse);
  });

  test('11. bỏ qua reset khi đang lưu', () async {
    final pending = repo.holdUpdate();
    final saving = save();

    await auth.resetDemoData();

    expect(repo.resetCalls, 0);
    expect(auth.currentUser, same(_customer));
    pending.complete(_updated);
    await saving;
  });

  test('12. bỏ qua reset khi phiên đang loading', () async {
    final pending = repo.holdRestore();
    final restoring = auth.restoreSession();

    await auth.resetDemoData();

    expect(repo.resetCalls, 0);
    expect(auth.isLoading, isTrue);
    pending.complete(_customer);
    await restoring;
  });

  test('13. lần lưu sau xóa lỗi field cũ trước khi nhận lỗi chung', () async {
    repo
      ..willFailUpdate(
        const AppException('Số điện thoại đã bị khóa', field: 'phone'),
      )
      ..willFailUpdate(const AppException('Không thể lưu thay đổi mới'));

    expect(await save(), isFalse);
    expect(auth.saveFieldErrors['phone'], 'Số điện thoại đã bị khóa');
    expect(auth.saveErrorMessage, isNull);

    expect(await save(), isFalse);

    expect(repo.updateCalls, 2);
    expect(auth.saveFieldErrors, isEmpty);
    expect(auth.saveErrorMessage, 'Không thể lưu thay đổi mới');
    expect(auth.isSaving, isFalse);
    _expectSessionUntouched(auth);
  });

  test('14. xóa user và thông báo trước khi repo bắt đầu reset DB', () async {
    late AuthProvider observedAuth;
    User? userAtReset = _customer;
    User? lastNotifiedUser = _customer;
    User? notifiedUserAtReset = _customer;
    final observingRepo = _ResetObservingRepository(() {
      userAtReset = observedAuth.currentUser;
      notifiedUserAtReset = lastNotifiedUser;
    })..willLogin(_customer);
    observedAuth = AuthProvider(observingRepo);
    addTearDown(observedAuth.dispose);
    await observedAuth.login(_customer.email, 'Customer@123');
    observedAuth.addListener(() {
      lastNotifiedUser = observedAuth.currentUser;
    });

    await observedAuth.resetDemoData();

    expect(observingRepo.resetCalls, 1);
    expect(observingRepo.unexpectedCalls, 0);
    expect(userAtReset, isNull);
    expect(notifiedUserAtReset, isNull);
    expect(observedAuth.status, ViewStatus.empty);
  });
}

class _ResetFailingRepository extends FakeAuthRepository {
  @override
  Future<void> resetDemoData() async {
    resetCalls++;
    throw StateError('reset failure');
  }
}

class _ResetObservingRepository extends FakeAuthRepository {
  _ResetObservingRepository(this.onReset);

  final void Function() onReset;

  @override
  Future<void> resetDemoData() async {
    onReset();
    await super.resetDemoData();
  }
}
