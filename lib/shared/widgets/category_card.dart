import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.lgAll,
              ),
              child: Image.asset(
                category.iconPath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) {
                  return const Icon(
                    Icons.sports_tennis_rounded,
                    size: 40,
                    color: AppColors.primary,
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
