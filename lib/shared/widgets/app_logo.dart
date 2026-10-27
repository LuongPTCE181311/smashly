import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Logo SMASHLY vẽ bằng code (nét ở mọi cỡ, đổi màu theo nền).
///
/// - Nền tối (Splash, header Login, header Admin): `AppLogo(onDark: true)`.
/// - Chỉ biểu tượng: `AppLogo(showWordmark: false)`.
///
/// Logo là hình nhận diện nên **không co theo cỡ chữ hệ thống**: kích thước
/// chỉ do [size] quyết định, không tràn khi người dùng phóng to chữ.
///
/// Bản PNG cùng thiết kế nằm ở `assets/images/brand/` cho slide, README.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 32,
    this.onDark = false,
    this.showWordmark = true,
  });

  /// Cạnh của biểu tượng vuông; chữ SMASHLY co giãn theo.
  final double size;
  final bool onDark;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'S',
            textScaler: TextScaler.noScaling,
            style: AppTextStyles.display.copyWith(
              fontSize: size * 0.62,
              height: 1,
              color: AppColors.onDark,
            ),
          ),
          // Chấm Volt = quả cầu đang bay.
          Positioned(
            top: size * 0.16,
            right: size * 0.16,
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: const BoxDecoration(
                color: AppColors.accentVolt,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return Semantics(label: 'SMASHLY', child: mark);

    return Semantics(
      label: 'SMASHLY',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            SizedBox(width: size * 0.3),
            Text(
              'SMASHLY',
              textScaler: TextScaler.noScaling,
              style: AppTextStyles.display.copyWith(
                fontSize: size * 0.62,
                height: 1,
                letterSpacing: size * 0.03,
                color: onDark ? AppColors.onDark : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
