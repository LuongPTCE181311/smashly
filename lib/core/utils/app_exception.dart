import 'package:flutter/foundation.dart' show debugPrint;

/// Lỗi kèm câu tiếng Việt để hiện cho người dùng; [field] là ô nhập bị lỗi.
class AppException implements Exception {
  const AppException(this.message, {this.field});

  final String message;
  final String? field;

  @override
  String toString() => message;
}

/// Câu báo lỗi cho người dùng: lấy câu của [AppException], lỗi khác dùng [fallback].
String errorMessageOf(Object error, String fallback) {
  if (error is AppException && error.message.isNotEmpty) return error.message;
  debugPrint('Unexpected error: $error');
  return fallback;
}
