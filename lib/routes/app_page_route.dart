import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// Hiệu ứng chuyển màn chung của app: fade + trượt 8% từ phải, 320 ms.
/// Máy bật "giảm chuyển động" thì chuyển màn ngay, không animate.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: AppMotion.page,
        reverseTransitionDuration: AppMotion.page,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, _, child) {
          if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
            return child;
          }
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.pageCurve,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
