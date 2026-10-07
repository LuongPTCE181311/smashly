import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_logo.dart';

/// Header tối của Login/Register: gradient + logo + tiêu đề.
///
/// Chiều cao do màn quyết định (vd. 40% chiều cao màn hình). Nội dung co lại
/// bằng `FittedBox` khi header thấp (bàn phím mở, chữ phóng to) thay vì tràn.
/// Chừa [overlap] ở đáy cho card trắng đè lên.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.height,
    required this.title,
    this.subtitle,
    this.overlap = AppSpacing.xxl,
  });

  final double height;
  final String title;
  final String? subtitle;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(gradient: AppColors.darkGradient),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        overlap,
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 40, onDark: true),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: AppTextStyles.h1.copyWith(color: AppColors.onDark),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.body.copyWith(
                      // TODO(theme): xin Lượng token onDarkMuted thay cho alpha tự chọn.
                      color: AppColors.onDark.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
