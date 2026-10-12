import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'brand_tile.dart';

class HomeBrandsSection extends StatelessWidget {
  const HomeBrandsSection({
    super.key,
    required this.brands,
    required this.onBrandTap,
  });

  final List<String> brands;
  final ValueChanged<String> onBrandTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final brand = brands[index];

          return BrandTile(brand: brand, onTap: () => onBrandTap(brand));
        },
      ),
    );
  }
}
