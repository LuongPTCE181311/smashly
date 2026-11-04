import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';

import 'app_exception.dart';

/// Chạy [body]; lỗi SQLite được ghi log [tag] rồi đổi thành [AppException]([fallback]).
Future<T> runDb<T>(
  String tag,
  String fallback,
  Future<T> Function() body,
) async {
  try {
    return await body();
  } on DatabaseException catch (error) {
    debugPrint('$tag: $error');
    throw AppException(fallback);
  }
}
