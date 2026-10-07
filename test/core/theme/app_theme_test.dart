import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_colors.dart';
import 'package:smashly/core/theme/app_motion.dart';
import 'package:smashly/core/theme/app_text_styles.dart';
import 'package:smashly/core/theme/app_theme.dart';

void main() {
  test('AppTheme.light dùng đúng token màu và font', () {
    final theme = AppTheme.light;

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.textTheme.headlineSmall?.fontFamily, AppFonts.jakarta);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.inter);
  });

  test('line height khớp bảng typography', () {
    expect(AppTextStyles.display.fontSize! * AppTextStyles.display.height!, 38);
    expect(AppTextStyles.body.fontSize! * AppTextStyles.body.height!, 20);
  });

  testWidgets('AppMotion.of trả Duration.zero khi bật giảm chuyển động', (
    tester,
  ) async {
    late Duration normal;
    late Duration reduced;

    await tester.pumpWidget(
      Column(
        children: [
          Builder(
            builder: (context) {
              normal = AppMotion.of(context, AppMotion.normal);
              return const SizedBox();
            },
          ),
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = AppMotion.of(context, AppMotion.normal);
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );

    expect(normal, AppMotion.normal);
    expect(reduced, Duration.zero);
  });
}
