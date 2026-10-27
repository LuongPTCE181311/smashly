import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';

enum PasswordStrength { weak, medium, strong }

/// Chỉ đánh giá tiêu chí bổ sung sau khi mật khẩu qua luật đăng ký.
PasswordStrength? passwordStrength(String password) {
  if (password.isEmpty) return null;
  if (validatePassword(password) != null) return PasswordStrength.weak;

  final criteria = [
    password.length >= 12,
    RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password),
    RegExp(r'[^A-Za-z0-9]').hasMatch(password),
  ];
  return criteria.where((met) => met).length >= 2
      ? PasswordStrength.strong
      : PasswordStrength.medium;
}

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);
    if (strength == null) return const SizedBox.shrink();

    final label = switch (strength) {
      PasswordStrength.weak => 'Yếu',
      PasswordStrength.medium => 'Trung bình',
      PasswordStrength.strong => 'Mạnh',
    };
    const colors = [AppColors.error, AppColors.warning, AppColors.success];

    return Semantics(
      label: 'Độ mạnh mật khẩu: $label',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var index = 0; index < colors.length; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.smAll,
                    child: ColoredBox(
                      color: index <= strength.index
                          ? colors[index]
                          : AppColors.border,
                      child: const SizedBox(height: AppSpacing.xs),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
