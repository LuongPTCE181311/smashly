import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'empty_state.dart';

/// Trạng thái lỗi toàn màn + nút "Thử lại".
///
/// ```dart
/// ViewStatus.error => ErrorState(
///   message: provider.errorMessage,
///   onRetry: provider.load,
/// ),
/// ```
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Đã có lỗi xảy ra',
    this.message,
    this.onRetry,
    this.retryLabel = 'Thử lại',
    this.onDark = false,
  });

  final String title;

  /// Thường là `provider.errorMessage` (câu tiếng Việt từ AppException).
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// true khi đặt trên nền tối (Splash, header tối): chữ trắng, icon trắng.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      onDark: onDark,
      icon: Icons.error_outline_rounded,
      iconColor: onDark ? AppColors.onDark : AppColors.error,
      iconBackground: onDark ? AppColors.onDarkSubtle : AppColors.errorSoft,
      title: title,
      message: message ?? 'Vui lòng thử lại sau ít phút.',
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
    );
  }
}
