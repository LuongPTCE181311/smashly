import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/theme/app_spacing.dart';

/// Rung [child] sang ngang mỗi lần [controller] chạy từ 0 đến 1.
class ShakeCard extends StatelessWidget {
  const ShakeCard({super.key, required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final t = controller.value;
        // 2 nhịp qua lại, biên độ giảm dần về 0 khi kết thúc.
        final dx = math.sin(t * 4 * math.pi) * AppSpacing.sm * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
