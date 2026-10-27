import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Băm mật khẩu bằng SHA-256 trước khi lưu vào SQLite.
/// Không bao giờ lưu mật khẩu dạng chữ thường.
///
/// Email được trộn vào (làm "muối") để hai người cùng mật khẩu
/// vẫn có hai chuỗi hash khác nhau.
class PasswordHasher {
  PasswordHasher._();

  static String hash(String email, String password) {
    final input = '${email.trim().toLowerCase()}:$password';
    return sha256.convert(utf8.encode(input)).toString();
  }

  static bool verify(String email, String password, String storedHash) {
    return hash(email, password) == storedHash;
  }
}
