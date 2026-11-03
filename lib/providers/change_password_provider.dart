import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';
import '../data/repositories/auth_repository.dart';

/// State của sheet Đổi mật khẩu (UC04.3): đang lưu và lỗi của lần lưu gần nhất.
class ChangePasswordProvider extends ChangeNotifier {
  ChangePasswordProvider(this._repository, {required this.userId});

  final AuthRepository _repository;
  final int userId;

  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = {};
  bool _accountGone = false;
  bool _disposed = false;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => UnmodifiableMapView(_fieldErrors);

  /// `true` khi tài khoản không còn tồn tại: màn Hồ sơ phải đăng xuất.
  bool get accountGone => _accountGone;

  /// Đổi mật khẩu. Trả `true` khi thành công; lỗi nằm ở [fieldErrors]
  /// hoặc [errorMessage]. Đang lưu mà gọi tiếp thì bỏ qua và trả `false`.
  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    _notify();

    try {
      await _repository.changePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } on AppException catch (error) {
      final field = error.field;
      if (field == AuthRepository.accountGoneField) {
        _accountGone = true;
        _errorMessage = error.message;
      } else if (field == null) {
        _errorMessage = error.message;
      } else {
        _fieldErrors[field] = error.message;
      }
      return false;
    } catch (error) {
      debugPrint('ChangePasswordProvider.submit: $error');
      _errorMessage = 'Không thể đổi mật khẩu lúc này';
      return false;
    } finally {
      _isSaving = false;
      _notify();
    }
  }

  /// Xóa lỗi của [field] khi người dùng gõ lại ô đó.
  void clearFieldError(String field) {
    if (_fieldErrors.remove(field) != null) _notify();
  }

  // Sheet có thể bị đóng khi đang lưu; không notify sau khi đã dispose.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
