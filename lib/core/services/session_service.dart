import 'package:shared_preferences/shared_preferences.dart';

/// Lưu phiên đăng nhập trên máy bằng id người dùng.
class SessionService {
  static const _kLegacyIsLoggedIn = 'isLoggedIn';
  static const _kUserId = 'userId';

  /// Lưu id người dùng vừa đăng nhập và bỏ cờ của bản cũ.
  Future<void> saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kUserId, userId);
    await prefs.remove(_kLegacyIsLoggedIn);
  }

  /// Đọc id người dùng đang đăng nhập và hỗ trợ dữ liệu của bản cũ.
  Future<int?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Bản cũ lưu thêm cờ isLoggedIn; chỉ coi là đăng xuất khi cờ đó ghi rõ false.
    if (prefs.getBool(_kLegacyIsLoggedIn) == false) return null;
    return prefs.getInt(_kUserId);
  }

  /// Xóa id người dùng và cờ đăng nhập của bản cũ.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kLegacyIsLoggedIn);
  }
}
