import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

/// Icon tab Giỏ hàng kèm badge số lượng; badge nảy lên khi số tăng.
class CartBadgeIcon extends StatefulWidget {
  const CartBadgeIcon({super.key, required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  State<CartBadgeIcon> createState() => _CartBadgeIconState();
}

class _CartBadgeIconState extends State<CartBadgeIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  late final Animation<double> _scale = TweenSequence<double>(
    [
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
    ],
  ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.normalCurve));

  @override
  void didUpdateWidget(CartBadgeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) {
      _controller.duration = AppMotion.of(context, AppMotion.emphasis);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Badge.count(
        count: widget.count,
        isLabelVisible: widget.count > 0,
        child: Icon(widget.icon),
      ),
    );
  }
}
