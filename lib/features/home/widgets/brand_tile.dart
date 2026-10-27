import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class BrandTile extends StatelessWidget {
  const BrandTile({super.key, required this.brand, required this.onTap});

  final String brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        width: 120,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          brand,
          style: AppTextStyles.subtitle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
