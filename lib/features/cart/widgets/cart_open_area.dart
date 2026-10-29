import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Tappable region that opens the product detail (image, name, price). The
/// checkbox and stepper sit outside it, so they never navigate. When [onOpen]
/// is null it only shows [child] and does not capture taps.
class CartOpenArea extends StatelessWidget {
  const CartOpenArea({super.key, required this.onOpen, required this.child});

  final VoidCallback? onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onOpen = this.onOpen;
    if (onOpen == null) return child;
    return Semantics(
      onTapHint: 'Xem chi tiết sản phẩm',
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadius.smAll,
        child: child,
      ),
    );
  }
}
