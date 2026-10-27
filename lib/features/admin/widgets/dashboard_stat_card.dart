import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Một thẻ số liệu trên Admin Dashboard: nhãn, icon, số đếm từ 0 lên.
///
/// [format] đổi số thành chữ hiển thị (ví dụ định dạng VND). Số chỉ chạy lại
/// hiệu ứng khi giá trị đổi, nên làm mới mà số giữ nguyên thì không nháy.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.softColor,
    this.caption,
    this.format = _plain,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color softColor;

  /// Dòng chú thích nhỏ dưới số (ví dụ "Tồn kho ≤ 5").
  final String? caption;
  final String Function(int value) format;

  static String _plain(int value) => '$value';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${format(value)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
              ],
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: AppMotion.emphasis,
              curve: AppMotion.normalCurve,
              builder: (_, animated, _) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  format(animated.round()),
                  style: AppTextStyles.h1.copyWith(color: color),
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
