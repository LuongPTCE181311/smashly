import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SpecMeter extends StatelessWidget {
  const SpecMeter({
    super.key,
    required this.count,
    required this.activeIndex,
    this.fillToActive = true,
    this.startLabel,
    this.endLabel,
  });

  final int count;
  final int activeIndex;
  final bool fillToActive;
  final String? startLabel;
  final String? endLabel;

  bool _isOn(int index) =>
      fillToActive ? index <= activeIndex : index == activeIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.normal),
                  curve: AppMotion.normalCurve,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isOn(i) ? AppColors.primary : AppColors.border,
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (startLabel != null || endLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(startLabel ?? '', style: AppTextStyles.caption),
              const Spacer(),
              Text(endLabel ?? '', style: AppTextStyles.caption),
            ],
          ),
        ],
      ],
    );
  }
}
