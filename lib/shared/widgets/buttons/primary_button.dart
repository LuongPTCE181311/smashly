import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'pressable_scale.dart';

/// Nút hành động chính (Smash Blue). Mỗi màn chỉ nên có 1 nút này.
///
/// - `onPressed: null` → nút xám (form chưa hợp lệ).
/// - `isLoading: true` → hiện spinner, chặn bấm lần 2, giữ nguyên kích thước.
///
/// ```dart
/// PrimaryButton(
///   label: 'Đăng nhập',
///   isLoading: auth.isLoading,
///   onPressed: _formValid ? _submit : null,
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
    this.height = AppSizes.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  /// true = rộng hết chiều ngang cha.
  final bool expanded;

  /// 52 cho form; 56 cho thanh CTA cố định đáy ([AppSizes.ctaHeight]).
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled && !isLoading,
      label: isLoading ? '$label, đang xử lý' : null,
      child: PressableScale(
        enabled: enabled && !isLoading,
        child: IgnorePointer(
          ignoring: isLoading,
          child: FilledButton(
            // Khi loading vẫn truyền callback rỗng để nút giữ màu primary.
            onPressed: isLoading ? () {} : onPressed,
            style: FilledButton.styleFrom(
              minimumSize: Size(
                expanded ? double.infinity : AppSizes.minTouchTarget,
                height,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: isLoading ? 0 : 1, child: content),
                if (isLoading)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
