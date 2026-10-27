import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SpecGuideSheet extends StatelessWidget {
  const SpecGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SpecGuideSheet(),
    );
  }

  static const _entries = [
    (
      Icons.fitness_center_rounded,
      'Trọng lượng (U)',
      'Số U càng lớn vợt càng nhẹ. 3U ≈ 85–89 g đầm tay, 4U ≈ 80–84 g dễ xoay, 5U ≈ 75–79 g rất nhẹ.',
    ),
    (
      Icons.balance_rounded,
      'Điểm cân bằng',
      'Head Heavy dồn lực lên đầu vợt để đập mạnh. Head Light vung nhanh, phòng thủ tốt. Even cân bằng cả hai.',
    ),
    (
      Icons.straighten_rounded,
      'Độ cứng đũa',
      'Đũa dẻo tự trợ lực, hợp người mới. Đũa cứng đánh chính xác nhưng cần lực cổ tay tốt.',
    ),
    (
      Icons.speed_rounded,
      'Sức căng tối đa',
      'Mức căng cước cao nhất hãng khuyến nghị. Người mới nên căng thấp hơn mức này 3–4 lbs.',
    ),
    (
      Icons.trending_up_rounded,
      'Trình độ',
      'Beginner cho người mới, Intermediate cho người chơi 1–2 năm, Advanced cho người chơi lâu năm.',
    ),
    (
      Icons.bolt_rounded,
      'Lối chơi',
      'Attack thiên đập cầu, Control thiên điều cầu, All-round cân bằng, Defense thiên phòng thủ.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          children: [
            Text('Đọc thông số vợt trong 30 giây', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.lg),
            for (final (icon, title, body) in _entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTextStyles.subtitle),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            body,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
