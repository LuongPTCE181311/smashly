import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Vùng bấm để mở chi tiết sản phẩm (ảnh, tên, giá). Ô chọn và stepper nằm
/// ngoài vùng này nên không bao giờ kích hoạt điều hướng. [onOpen] null thì
/// chỉ hiện [child], không bắt sự kiện bấm.
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
