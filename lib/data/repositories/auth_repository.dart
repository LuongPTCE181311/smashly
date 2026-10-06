import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/enums.dart';
import '../../core/services/session_service.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/password_hasher.dart';
import '../../core/utils/validators.dart';
import '../daos/cart_dao.dart';
import '../daos/user_dao.dart';
import '../models/user.dart';

class AuthRepository {
  const AuthRepository({
    required this._database,
    required this._userDao,
    required this._cartDao,
    required this._sessionService,
  });

  final Future<Database> Function() _database;
  final UserDao _userDao;
  final CartDao _cartDao;
  final SessionService _sessionService;

  Future<User> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final emailError = validateEmail(normalizedEmail);
    if (emailError != null) {
      throw AppException(emailError, field: 'email');
    }
    final passwordError = validateRequired(
      password,
      'Mật khẩu không được để trống',
    );
    if (passwordError != null) {
      throw AppException(passwordError, field: 'password');
    }

    try {
      final db = await _database();
      final auth = await _userDao.findAuthByEmail(db, normalizedEmail);
      if (auth == null ||
          !PasswordHasher.verify(
            normalizedEmail,
            password,
            auth.passwordHash,
          )) {
        throw const AppException('Email hoặc mật khẩu chưa đúng');
      }

      final userId = auth.user.id;
      if (userId == null) {
        throw const AppException('Không thể tạo phiên đăng nhập');
      }
      await _sessionService.saveSession(userId);
      return auth.user;
    } on DatabaseException catch (error) {
      debugPrint('AuthRepository.login: $error');
      throw const AppException('Không thể đăng nhập lúc này');
    }
  }

  Future<String> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final normalizedFullName = fullName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = phone.trim();

    final validations = <String, String?>{
      'fullName': validateFullName(normalizedFullName),
      'email': validateEmail(normalizedEmail),
      'phone': validatePhone(normalizedPhone),
      'password': validatePassword(password),
      'confirmPassword': validateConfirmPassword(password, confirmPassword),
    };
    for (final entry in validations.entries) {
      final message = entry.value;
      if (message != null) throw AppException(message, field: entry.key);
    }

    try {
      final db = await _database();
      return await db.transaction((txn) async {
        if (await _userDao.existsByEmail(txn, normalizedEmail)) {
          throw const AppException('Email này đã được đăng ký', field: 'email');
        }

        final user = User(
          fullName: normalizedFullName,
          email: normalizedEmail,
          phone: normalizedPhone,
          role: UserRole.customer,
        );
        final userId = await _userDao.insert(
          txn,
          user,
          PasswordHasher.hash(normalizedEmail, password),
        );
        await _cartDao.createForUser(txn, userId);
        return normalizedEmail;
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AppException('Email này đã được đăng ký', field: 'email');
      }
      debugPrint('AuthRepository.register: $error');
      throw const AppException('Không thể tạo tài khoản lúc này');
    }
  }

  Future<User?> getCurrentUser() async {
    final userId = await _sessionService.getLoggedInUserId();
    if (userId == null) return null;

    try {
      final db = await _database();
      final user = await _userDao.findById(db, userId);
      if (user == null) await _sessionService.clear();
      return user;
    } on DatabaseException catch (error) {
      debugPrint('AuthRepository.getCurrentUser: $error');
      throw const AppException('Không thể khôi phục phiên đăng nhập');
    }
  }

  Future<void> logout() => _sessionService.clear();
}
