import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Banner lỗi chung trong card Auth (vd. "Email hoặc mật khẩu chưa đúng").
/// Có icon + chữ, không chỉ dựa vào màu; `liveRegion` để trình đọc màn hình đọc ngay.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          // TODO(theme): xin Lượng token errorSoft thay cho alpha tự chọn.
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
