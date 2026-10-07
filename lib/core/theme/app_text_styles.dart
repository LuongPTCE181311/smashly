import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tên font family, khớp khai báo `fonts:` trong pubspec.yaml.
abstract final class AppFonts {
  /// Tiêu đề, giá, nút — hình khối thể thao, hiện đại.
  static const jakarta = 'PlusJakartaSans';

  /// Nội dung — dễ đọc ở cỡ nhỏ.
  static const inter = 'Inter';
}

/// Kiểu chữ (blueprint mục 21). OWNER: Lượng.
///
/// Màn hình không viết `fontSize: 17`; dùng style ở đây, cần đổi màu thì
/// `AppTextStyles.body.copyWith(color: AppColors.inkMuted)`.
/// `height` = line height / size theo bảng typography.
abstract final class AppTextStyles {
  /// 32/38 — tên hero, Order Success.
  static const display = TextStyle(
    fontFamily: AppFonts.jakarta,
    fontWeight: FontWeight.w800,
    fontSize: 32,
    height: 38 / 32,
    color: AppColors.ink,
  );

  /// 24/30 — tiêu đề màn hình.
  static const h1 = TextStyle(
    fontFamily: AppFonts.jakarta,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 30 / 24,
    color: AppColors.ink,
  );

  /// 20/26 — tiêu đề section.
  static const h2 = TextStyle(
    fontFamily: AppFonts.jakarta,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 26 / 20,
    color: AppColors.ink,
  );

  /// 16/22 — tên sản phẩm ở Detail, tiêu đề card.
  static const subtitle = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 22 / 16,
    color: AppColors.ink,
  );

  /// 14/20 — nội dung, mô tả.
  static const body = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    color: AppColors.ink,
  );

  /// 12/16 — brand, ngày, nhãn phụ.
  static const caption = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    color: AppColors.inkMuted,
  );

  /// 15/20 — mọi nút.
  static const button = TextStyle(
    fontFamily: AppFonts.jakarta,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 20 / 15,
  );

  /// Giá: Jakarta 800, chữ số thẳng hàng. Cỡ 16 (card), 20 (mặc định), 24 (Detail).
  static const priceSmall = TextStyle(
    fontFamily: AppFonts.jakarta,
    fontWeight: FontWeight.w800,
    fontSize: 16,
    height: 1.25,
    color: AppColors.ink,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static final price = priceSmall.copyWith(fontSize: 20);
  static final priceLarge = priceSmall.copyWith(fontSize: 24);
}
