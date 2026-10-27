import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

/// Co nhẹ con về 0.97 khi đang nhấn — phản hồi chạm dùng chung cho nút, card.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? AppMotion.pressedScale : 1,
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.fastCurve,
        child: widget.child,
      ),
    );
  }
}
