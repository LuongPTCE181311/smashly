import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';

/// Ô nhập dùng chung cho mọi form.
///
/// Quy tắc validate (`validator`):
/// - Rời ô → validate, hiện lỗi nếu sai.
/// - Đang gõ: chỉ validate lại khi ô **đang có lỗi** (để lỗi mất ngay khi sửa
///   đúng); ô đang đúng thì không báo lỗi giữa chừng, chờ tới lúc rời ô.
/// - `Form.validate()` (bấm submit) hiện lỗi cả ô chưa chạm; gõ đúng → lỗi mất.
///
/// - `isPassword: true` → có nút hiện/ẩn mật khẩu.
/// - `errorText` → lỗi từ server/Repository (vd. "Email này đã được đăng ký"),
///   lấy từ `authProvider.fieldErrors['email']`. Lỗi này **không tự mất khi
///   gõ**: màn hình phải tự xóa (vd. gọi `clearErrors()` trong provider) rồi
///   truyền `null`.
/// - `showValidCheck: true` → hiện check xanh khi ô hợp lệ (form Register).
///
/// Đặt trong `Form` để nút submit gọi `formKey.currentState!.validate()`.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.autofillHints,
    this.focusNode,
    this.enabled = true,
    this.errorText,
    this.showValidCheck = false,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool enabled;
  final String? errorText;
  final bool showValidCheck;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  FocusNode? _ownFocusNode;
  bool _touched = false;
  bool _obscured = true;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    setState(() => _touched = true);
    _fieldKey.currentState?.validate();
  }

  bool get _isValid {
    final value = _fieldKey.currentState?.value ?? widget.controller?.text;
    if (!_touched || value == null || value.isEmpty) return false;
    if (widget.errorText != null) return false;
    return widget.validator?.call(value) == null;
  }

  Widget? _buildSuffix() {
    if (widget.isPassword) {
      return IconButton(
        tooltip: _obscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }
    if (!widget.showValidCheck) return null;
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: _isValid
          ? const Icon(
              Icons.check_circle_rounded,
              key: ValueKey('valid'),
              color: AppColors.success,
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: _fieldKey,
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      obscureText: widget.isPassword && _obscured,
      enableSuggestions: !widget.isPassword,
      autocorrect: !widget.isPassword,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: (value) {
        widget.onChanged?.call(value);
        if (widget.showValidCheck && _touched) setState(() {});
      },
      autofillHints: widget.autofillHints,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        errorMaxLines: 2,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: _buildSuffix(),
      ),
    );
  }
}
