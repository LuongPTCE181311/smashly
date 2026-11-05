import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';
import '../data/repositories/auth_repository.dart';
import 'base_provider.dart';

/// Trạng thái của màn quên mật khẩu.
class ForgotPasswordProvider extends BaseProvider {
  ForgotPasswordProvider(this._repository);

  final AuthRepository _repository;
  bool _isSaving = false;
  String? _errorMessage;
  final Map<String, String> _fieldErrors = {};

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => UnmodifiableMapView(_fieldErrors);

  /// Gửi thông tin đặt lại mật khẩu.
  Future<String?> submit({
    required String email,
    required String phone,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_isSaving) return null;
    _isSaving = true;
    _errorMessage = null;
    _fieldErrors.clear();
    notify();

    try {
      return await _repository.resetPassword(
        email: email,
        phone: phone,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } on AppException catch (error) {
      final field = error.field;
      if (field == null) {
        _errorMessage = error.message;
      } else {
        _fieldErrors[field] = error.message;
      }
      return null;
    } catch (error) {
      debugPrint('ForgotPasswordProvider.submit: $error');
      _errorMessage = 'Không thể đặt lại mật khẩu lúc này';
      return null;
    } finally {
      _isSaving = false;
      notify();
    }
  }

  /// Xóa lỗi của ô đang sửa.
  void clearFieldError(String field) {
    if (_fieldErrors.remove(field) != null) notify();
  }
}
