import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SpecCard extends StatelessWidget {
  const SpecCard({
    super.key,
    required this.title,
    required this.value,
    required this.meaning,
    this.icon,
    this.visual,
  });

  final String title;
  final String value;
  final String meaning;
  final IconData? icon;
  final Widget? visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (visual != null) ...[
            const SizedBox(height: AppSpacing.sm),
            visual!,
          ],
          const Spacer(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            meaning,
            style: AppTextStyles.caption.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
