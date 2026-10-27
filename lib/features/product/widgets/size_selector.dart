import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SizeSelector extends StatelessWidget {
  const SizeSelector({
    super.key,
    required this.sizes,
    required this.selected,
    required this.onSelected,
  });

  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Chọn size', style: AppTextStyles.h2),
            const SizedBox(width: AppSpacing.sm),
            if (selected == null)
              Text(
                'Bắt buộc',
                style: AppTextStyles.caption.copyWith(color: AppColors.warning),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final size in sizes)
              ChoiceChip(
                label: Text(size),
                selected: size == selected,
                onSelected: (_) => onSelected(size),
                showCheckmark: false,
                labelStyle: AppTextStyles.label.copyWith(
                  color: size == selected ? AppColors.primary : AppColors.ink,
                ),
                side: BorderSide(
                  color: size == selected
                      ? AppColors.primary
                      : AppColors.border,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
