import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PlayStyleItem {
  const PlayStyleItem({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
}

const playStyles = [
  PlayStyleItem(
    value: 'ATTACK',
    label: 'Tấn công',
    description: 'Đập cầu mạnh',
    icon: Icons.bolt_rounded,
  ),
  PlayStyleItem(
    value: 'CONTROL',
    label: 'Kiểm soát',
    description: 'Điều cầu chính xác',
    icon: Icons.my_location_rounded,
  ),
  PlayStyleItem(
    value: 'ALL_ROUND',
    label: 'Toàn diện',
    description: 'Cân bằng công thủ',
    icon: Icons.autorenew_rounded,
  ),
  PlayStyleItem(
    value: 'DEFENSE',
    label: 'Phòng thủ',
    description: 'Nhanh và linh hoạt',
    icon: Icons.shield_outlined,
  ),
];

class PlayStyleSection extends StatelessWidget {
  const PlayStyleSection({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: playStyles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (_, index) {
        final item = playStyles[index];

        return InkWell(
          onTap: () => onSelected(item.value),
          borderRadius: AppRadius.lgAll,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(item.icon, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: AppTextStyles.subtitle),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
