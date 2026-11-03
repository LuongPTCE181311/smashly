import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/change_password_provider.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../auth/widgets/auth_error_banner.dart';
import '../../auth/widgets/password_strength_bar.dart';

/// Kết quả khi sheet Đổi mật khẩu tự đóng; `null` là người dùng bấm Hủy.
enum ChangePasswordOutcome { changed, accountGone }

/// Bottom sheet Đổi mật khẩu (UC04.3). Cần [ChangePasswordProvider] ở phía trên.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged(String value) {
    context.read<ChangePasswordProvider>().clearFieldError('newPassword');
    // Ô nhập lại so với mật khẩu mới, nên phải kiểm lại khi mật khẩu mới đổi.
    if (_confirm.text.isNotEmpty) _confirmKey.currentState?.validate();
    // Vẽ lại thanh độ mạnh mật khẩu.
    setState(() {});
  }

  Future<void> _submit() async {
    final provider = context.read<ChangePasswordProvider>();
    if (provider.isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final changed = await provider.submit(
      currentPassword: _current.text,
      newPassword: _newPassword.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;
    if (changed) {
      Navigator.of(context).pop(ChangePasswordOutcome.changed);
    } else if (provider.accountGone) {
      Navigator.of(context).pop(ChangePasswordOutcome.accountGone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChangePasswordProvider>();
    final saving = provider.isSaving;
    final error = provider.errorMessage;

    return PopScope(
      canPop: !saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Đổi mật khẩu', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.lg),
                  if (error != null) ...[
                    AuthErrorBanner(message: error),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AppTextField(
                    label: 'Mật khẩu hiện tại',
                    controller: _current,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) => validateRequired(
                      value,
                      'Vui lòng nhập mật khẩu hiện tại',
                    ),
                    errorText: provider.fieldErrors['currentPassword'],
                    enabled: !saving,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                    onChanged: (_) =>
                        provider.clearFieldError('currentPassword'),
                    onFieldSubmitted: (_) => _newFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Mật khẩu mới',
                    controller: _newPassword,
                    focusNode: _newFocus,
                    isPassword: true,
                    prefixIcon: Icons.lock_reset_outlined,
                    validator: validatePassword,
                    errorText: provider.fieldErrors['newPassword'],
                    enabled: !saving,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: _onNewPasswordChanged,
                    onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                  ),
                  if (_newPassword.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    PasswordStrengthBar(password: _newPassword.text),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Nhập lại mật khẩu mới',
                    controller: _confirm,
                    fieldKey: _confirmKey,
                    focusNode: _confirmFocus,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) =>
                        validateConfirmPassword(_newPassword.text, value),
                    errorText: provider.fieldErrors['confirmPassword'],
                    enabled: !saving,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onChanged: (_) =>
                        provider.clearFieldError('confirmPassword'),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Cập nhật mật khẩu',
                    isLoading: saving,
                    onPressed: _submit,
                  ),
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
