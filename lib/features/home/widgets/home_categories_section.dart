import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/category.dart';
import '../../../shared/widgets/category_card.dart';

class HomeCategoriesSection extends StatelessWidget {
  const HomeCategoriesSection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final ValueChanged<Category> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final category = categories[index];

          return CategoryCard(
            category: category,
            onTap: () => onCategoryTap(category),
          );
        },
      ),
    );
  }
}
