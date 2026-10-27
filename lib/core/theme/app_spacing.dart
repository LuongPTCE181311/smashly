import 'package:flutter/material.dart';

/// Khoảng cách theo lưới 4 (blueprint mục 21). OWNER: Lượng.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Lề trái/phải của mọi màn hình.
  static const double screen = lg;

  /// Khoảng cách giữa các section (Home, Detail...).
  static const double section = xl;

  static const screenPadding = EdgeInsets.symmetric(horizontal: screen);
}

/// Bo góc: chip/ô nhỏ 8 · ô nhập/nút 12 · card 16 · sheet/hero 24.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const xlAll = BorderRadius.all(Radius.circular(xl));

  /// Bottom sheet: chỉ bo hai góc trên.
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}

/// Một mức bóng duy nhất cho card — không chồng nhiều lớp bóng.
abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0F0F172A), // ink, alpha 0.06
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];
}

/// Kích thước vùng chạm.
abstract final class AppSizes {
  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;

  /// Thanh CTA cố định đáy (Detail, Cart, Checkout).
  static const double ctaHeight = 56;
}
