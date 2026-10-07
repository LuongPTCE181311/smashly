import 'package:flutter/material.dart';

/// Bảng màu SMASHLY (blueprint mục 21). OWNER: Lượng.
///
/// Màn hình chỉ dùng token ở đây, không viết `Color(0xFF...)` trực tiếp.
/// Cần màu mới → đề xuất qua PR sửa file này.
abstract final class AppColors {
  // Hành động: một màu duy nhất cho mọi CTA chính.
  static const primary = Color(0xFF1F4BFF); // Smash Blue
  static const primaryDark = Color(0xFF1636C7); // nút đang nhấn
  static const primarySoft = Color(0xFFE8EDFF); // nền chip đang chọn, nền icon

  // Chỉ dùng cho badge nhỏ trên nền tối (NEW, -15%).
  static const accentVolt = Color(0xFFC6F23A);

  // Nền tối: hero, Splash, header Login, header Admin.
  static const midnight = Color(0xFF0B1220);
  static const navy = Color(0xFF16213A);

  // Chữ.
  static const ink = Color(0xFF0F172A);
  static const inkMuted = Color(0xFF64748B);
  static const onDark = Colors.white;

  /// Chữ phụ trên nền tối (tagline, mô tả): trắng 72%.
  static const onDarkMuted = Color(0xB8FFFFFF);

  /// Nền nhạt trên nền tối (rãnh thanh tiến trình, nền icon): trắng 12%.
  static const onDarkSubtle = Color(0x1FFFFFFF);

  // Bề mặt.
  static const background = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const productTile = Color(0xFFEEF2F7);
  static const border = Color(0xFFE2E8F0);

  // Trạng thái — luôn đi kèm icon + chữ, không chỉ dựa vào màu.
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0EA5E9);

  /// Nền nhạt của khối lỗi (banner, nền icon lỗi): error 8%.
  static const errorSoft = Color(0x14DC2626);

  /// Gradient duy nhất của app: midnight → navy, góc 135°.
  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnight, navy],
  );
}
