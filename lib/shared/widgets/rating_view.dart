import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class RatingView extends StatelessWidget {
  const RatingView({super.key, required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đánh giá ${rating.toStringAsFixed(1)} trên 5, $count lượt',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
            const SizedBox(width: AppSpacing.xs),
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.label,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('($count)', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
