import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/racket_spec.dart';
import 'racket_spec_text.dart';
import 'spec_card.dart';
import 'spec_guide_sheet.dart';
import 'spec_meter.dart';

class RacketSpecSection extends StatelessWidget {
  const RacketSpecSection({super.key, required this.spec});

  final RacketSpec spec;

  @override
  Widget build(BuildContext context) {
    final weight = RacketSpecText.weight(spec.weightClass);
    final balance = RacketSpecText.balance(spec.balance);
    final shaft = RacketSpecText.shaft(spec.shaft);
    final level = RacketSpecText.level(spec.playerLevel);
    final style = RacketSpecText.style(spec.playStyle);

    final cards = [
      SpecCard(
        title: 'Trọng lượng',
        value: weight.label,
        meaning: weight.meaning,
        visual: SpecMeter(
          count: RacketSpecText.weightOrder.length,
          activeIndex: RacketSpecText.weightOrder.indexOf(spec.weightClass),
          fillToActive: false,
          startLabel: 'Nặng',
          endLabel: 'Nhẹ',
        ),
      ),
      SpecCard(
        title: 'Điểm cân bằng',
        value: balance.label,
        meaning: balance.meaning,
        visual: SpecMeter(
          count: RacketSpecText.balanceOrder.length,
          activeIndex: RacketSpecText.balanceOrder.indexOf(spec.balance),
          fillToActive: false,
          startLabel: 'Nhẹ đầu',
          endLabel: 'Nặng đầu',
        ),
      ),
      SpecCard(
        title: 'Độ cứng đũa',
        value: shaft.label,
        meaning: shaft.meaning,
        visual: SpecMeter(
          count: RacketSpecText.shaftOrder.length,
          activeIndex: RacketSpecText.shaftOrder.indexOf(spec.shaft),
          startLabel: 'Dẻo',
          endLabel: 'Rất cứng',
        ),
      ),
      SpecCard(
        title: 'Sức căng tối đa',
        value: '${spec.maxTensionLbs} lbs',
        meaning: 'Mức căng cước tối đa hãng khuyến nghị',
        icon: Icons.speed_rounded,
      ),
      SpecCard(
        title: 'Trình độ',
        value: level.label,
        meaning: level.meaning,
        icon: level.icon,
      ),
      SpecCard(
        title: 'Lối chơi',
        value: style.label,
        meaning: style.meaning,
        icon: style.icon,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Thông số', style: AppTextStyles.h2),
            const Spacer(),
            IconButton(
              tooltip: 'Đọc thông số vợt',
              icon: const Icon(Icons.info_outline_rounded),
              color: AppColors.primary,
              onPressed: () => SpecGuideSheet.show(context),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  RacketSpecText.fitSummary(spec),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: i + 1 < cards.length
                      ? cards[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
