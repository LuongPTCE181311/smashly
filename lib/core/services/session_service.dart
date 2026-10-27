import 'package:shared_preferences/shared_preferences.dart';

/// Lưu phiên đăng nhập trên máy (không dùng SQLite cho việc này).
///
/// - Login thành công  -> saveSession(user.id)
/// - Splash            -> getLoggedInUserId(): null = chưa đăng nhập
/// - Logout            -> clear()
class SessionService {
  static const _kIsLoggedIn = 'isLoggedIn';
  static const _kUserId = 'userId';

  Future<void> saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setInt(_kUserId, userId);
  }

  Future<int?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
    if (!loggedIn) return null;
    return prefs.getInt(_kUserId);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kUserId);
  }
}
