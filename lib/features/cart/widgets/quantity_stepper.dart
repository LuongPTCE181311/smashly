import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Nút − số lượng +. Truyền `null` cho [onDecrease]/[onIncrease] để khóa nút.
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.max,
    this.onQuantityChanged,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final int? max;
  final ValueChanged<int>? onQuantityChanged;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  bool _increasing = true;
  bool _editing = false;

  bool get _editable =>
      widget.onQuantityChanged != null && (widget.max ?? 0) >= 1;

  @override
  void didUpdateWidget(QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      _increasing = widget.quantity > oldWidget.quantity;
    }
  }

  void _finishEditing(int? value) {
    setState(() => _editing = false);
    if (value != null && value != widget.quantity) {
      widget.onQuantityChanged!(value);
    }
  }

  Widget _slide(Widget child, Animation<double> animation) {
    final entering = child.key == ValueKey(widget.quantity);
    final from = (_increasing ? 1.0 : -1.0) * (entering ? 1 : -1) * 0.6;
    return ClipRect(
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: Offset(0, from),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
    );
  }

  Widget _number() {
    final text = Text(
      '${widget.quantity}',
      textAlign: TextAlign.center,
      style: AppTextStyles.subtitle,
    );
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.normal),
      switchInCurve: AppMotion.normalCurve,
      switchOutCurve: AppMotion.normalCurve,
      transitionBuilder: _slide,
      child: SizedBox(
        key: ValueKey(widget.quantity),
        width: 40,
        height: 36,
        child: _editable
            ? InkWell(
                onTap: () => setState(() => _editing = true),
                borderRadius: AppRadius.smAll,
                child: Tooltip(
                  message: 'Nhập số lượng',
                  child: Center(child: text),
                ),
              )
            : Center(child: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: 'Giảm số lượng',
            onPressed: widget.onDecrease,
          ),
          if (_editing)
            _QuantityField(
              initial: widget.quantity,
              max: widget.max!,
              onDone: _finishEditing,
            )
          else
            _number(),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: 'Tăng số lượng',
            onPressed: widget.onIncrease,
          ),
        ],
      ),
    );
  }
}

class _QuantityFormatter extends TextInputFormatter {
  const _QuantityFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final number = int.tryParse(digits) ?? max + 1;
    final text = '${number > max ? max : number}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _QuantityField extends StatefulWidget {
  const _QuantityField({
    required this.initial,
    required this.max,
    required this.onDone,
  });

  final int initial;
  final int max;

  final ValueChanged<int?> onDone;

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  late final _controller = TextEditingController(text: '${widget.initial}');
  final _focus = FocusNode();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _commit() {
    if (_done) return;
    _done = true;
    final value = int.tryParse(_controller.text);
    widget.onDone(value == null || value < 1 ? null : value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        autofocus: true,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        style: AppTextStyles.subtitle,
        inputFormatters: [_QuantityFormatter(widget.max)],
        onSubmitted: (_) => _commit(),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      color: AppColors.ink,
      disabledColor: AppColors.border,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
    );
  }
}
