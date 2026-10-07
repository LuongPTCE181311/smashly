import 'package:flutter/material.dart';

/// Thời lượng + curve chuẩn cho animation (blueprint mục 22). OWNER: Lượng.
///
/// Luật: không quá 1 animation `emphasis` trên một màn cùng lúc; danh sách
/// dài chỉ animate lần tải đầu; luôn qua [AppMotion.of] để tôn trọng cài đặt
/// giảm chuyển động của máy.
abstract final class AppMotion {
  /// Nhấn nút, đổi màu chip, checkbox.
  static const fast = Duration(milliseconds: 150);

  /// Đổi số lượng, đổi nội dung, AnimatedSwitcher.
  static const normal = Duration(milliseconds: 250);

  /// Chuyển màn, mở sheet.
  static const page = Duration(milliseconds: 320);

  /// Badge nảy, check thành công, đếm số dashboard (dùng ít).
  static const emphasis = Duration(milliseconds: 600);

  static const fastCurve = Curves.easeOut;
  static const normalCurve = Curves.easeOutCubic;
  static const pageCurve = Curves.easeOutCubic;
  static const emphasisCurve = Curves.easeOutBack;

  /// Tỉ lệ co khi nhấn nút.
  static const double pressedScale = 0.97;

  /// Trả về [Duration.zero] nếu người dùng bật "giảm chuyển động".
  ///
  /// ```dart
  /// AnimatedScale(duration: AppMotion.of(context, AppMotion.fast), ...)
  /// ```
  static Duration of(BuildContext context, Duration duration) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduceMotion ? Duration.zero : duration;
  }
}
