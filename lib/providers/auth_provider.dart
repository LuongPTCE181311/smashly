import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/constants/enums.dart';
import '../core/utils/app_exception.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

/// Quản lý trạng thái xác thực, phiên đăng nhập và cập nhật hồ sơ.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authRepository);

  final AuthRepository _authRepository;

  ViewStatus _status = ViewStatus.initial;
  User? _currentUser;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = {};

  bool _isSaving = false;
  String? _saveErrorMessage;
  final Map<String, String> _saveFieldErrors = {};

  ViewStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => UnmodifiableMapView(_fieldErrors);
  bool get isLoading => _status == ViewStatus.loading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  bool get isSaving => _isSaving;
  String? get saveErrorMessage => _saveErrorMessage;
  Map<String, String> get saveFieldErrors =>
      UnmodifiableMapView(_saveFieldErrors);

  void clearSaveErrors() {
    if (_saveErrorMessage == null && _saveFieldErrors.isEmpty) return;
    _saveErrorMessage = null;
    _saveFieldErrors.clear();
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String? address,
  }) async {
    final userId = _currentUser?.id;
    if (isSaving || userId == null) return false;

    _isSaving = true;
    _saveErrorMessage = null;
    _saveFieldErrors.clear();
    notifyListeners();

    try {
      final user = await _authRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        address: address,
      );
      // Không hồi sinh phiên nếu user đã đăng xuất trong lúc chờ lưu.
      if (_currentUser?.id == userId) _currentUser = user;
      return true;
    } catch (error) {
      final field = error is AppException ? error.field : null;
      final message = errorMessageOf(error, 'Không thể lưu lúc này');
      if (field == AuthRepository.accountGoneField) {
        if (_currentUser?.id != userId) return false;
        _saveErrorMessage = message;
        await _endSessionQuietly();
      } else if (field == null) {
        _saveErrorMessage = message;
      } else {
        _saveFieldErrors[field] = message;
      }
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Tài khoản đã mất nên phiên phải kết thúc kể cả khi xóa phiên lưu trên máy lỗi.
  Future<void> _endSessionQuietly() async {
    try {
      await _authRepository.logout();
    } catch (error) {
      debugPrint('AuthProvider._endSessionQuietly: $error');
    }
    _currentUser = null;
    _status = ViewStatus.empty;
  }

  Future<void> resetDemoData() async {
    if (isLoading || isSaving) return;
    _beginLoading();
    _currentUser = null;
    notifyListeners();
    try {
      await _authRepository.resetDemoData();
      _status = ViewStatus.empty;
    } catch (error) {
      _handleError(error, 'Không thể đặt lại dữ liệu demo lúc này');
    } finally {
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    if (isLoading) return;
    _beginLoading();
    try {
      _currentUser = await _authRepository.getCurrentUser();
      _status = _currentUser == null ? ViewStatus.empty : ViewStatus.success;
    } catch (error) {
      _handleError(error, 'Không thể khôi phục phiên đăng nhập');
    }
    notifyListeners();
  }

  Future<User?> login(String email, String password) async {
    if (isLoading) return null;
    _beginLoading();
    User? user;
    try {
      user = await _authRepository.login(email, password);
      _currentUser = user;
      _status = ViewStatus.success;
    } catch (error) {
      _handleError(error, 'Không thể đăng nhập lúc này');
    }
    notifyListeners();
    return user;
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    if (isLoading) return null;
    _beginLoading();
    String? registeredEmail;
    try {
      registeredEmail = await _authRepository.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
      );
      _status = ViewStatus.success;
    } catch (error) {
      _handleError(error, 'Không thể tạo tài khoản lúc này');
    }
    notifyListeners();
    return registeredEmail;
  }

  Future<void> logout() async {
    if (isLoading) return;
    _beginLoading();
    try {
      await _authRepository.logout();
      _currentUser = null;
      _status = ViewStatus.empty;
    } catch (error) {
      _handleError(error, 'Không thể đăng xuất lúc này');
    }
    notifyListeners();
  }

  /// Gọi trong event handler (onTap, onPressed) trước khi chuyển màn,
  /// không gọi trong build/initState/dispose.
  void clearErrors() {
    if (_errorMessage == null && _fieldErrors.isEmpty) return;
    _errorMessage = null;
    _fieldErrors.clear();
    if (_status == ViewStatus.error) {
      _status = _currentUser == null ? ViewStatus.initial : ViewStatus.success;
    }
    notifyListeners();
  }

  void _beginLoading() {
    _errorMessage = null;
    _fieldErrors.clear();
    _status = ViewStatus.loading;
    notifyListeners();
  }

  /// Bắt mọi lỗi, kể cả Error (TypeError, ArgumentError): nếu để lọt, status
  /// kẹt ở loading và cờ chặn bấm 2 lần sẽ khóa form vĩnh viễn.
  void _handleError(Object error, String fallback) {
    _status = ViewStatus.error;
    final field = error is AppException ? error.field : null;
    final message = errorMessageOf(error, fallback);
    if (field == null) {
      _errorMessage = message;
    } else {
      _fieldErrors[field] = message;
    }
  }
}
