import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../providers/forgot_password_provider.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_header.dart';
import 'widgets/password_strength_bar.dart';

/// Màn quên mật khẩu trả email về màn đăng nhập khi thành công.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _phone = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  final _phoneFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    _phoneFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged(String value) {
    context.read<ForgotPasswordProvider>().clearFieldError('newPassword');
    // Ô nhập lại phụ thuộc mật khẩu mới nên cần kiểm lại khi mật khẩu đổi.
    if (_confirm.text.isNotEmpty) _confirmKey.currentState?.validate();
    // Vẽ lại thanh độ mạnh theo mật khẩu vừa gõ.
    setState(() {});
  }

  Future<void> _submit() async {
    final provider = context.read<ForgotPasswordProvider>();
    if (provider.isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = await provider.submit(
      email: _email.text,
      phone: _phone.text,
      newPassword: _newPassword.text,
      confirmPassword: _confirm.text,
    );
    if (!mounted) return;
    if (email != null) Navigator.of(context).pop(email);
  }

  void _goBack() {
    if (context.read<ForgotPasswordProvider>().isSaving) return;
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForgotPasswordProvider>();
    return PopScope(
      canPop: !provider.isSaving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: Stack(
                  children: [
                    AuthHeader(
                      height: MediaQuery.sizeOf(context).height * 0.28,
                      title: 'Reset password',
                      subtitle: 'Nhập email và số điện thoại đã đăng ký',
                    ),
                    Positioned(
                      top: 0,
                      left: AppSpacing.sm,
                      child: SafeArea(
                        bottom: false,
                        child: IconButton(
                          tooltip: 'Quay lại',
                          color: AppColors.onDark,
                          onPressed: provider.isSaving ? null : _goBack,
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -AppSpacing.xxl),
                child: Padding(
                  padding: AppSpacing.screenPadding,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.xlAll,
                      boxShadow: AppShadows.card,
                    ),
                    child: _buildForm(provider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ForgotPasswordProvider provider) {
    final saving = provider.isSaving;
    final error = provider.errorMessage;
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null) ...[
              AuthErrorBanner(message: error),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              label: 'Email',
              controller: _email,
              validator: validateEmail,
              errorText: provider.fieldErrors['email'],
              enabled: !saving,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => provider.clearFieldError('email'),
              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Số điện thoại',
              controller: _phone,
              focusNode: _phoneFocus,
              validator: validatePhone,
              errorText: provider.fieldErrors['phone'],
              enabled: !saving,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              onChanged: (_) => provider.clearFieldError('phone'),
              onFieldSubmitted: (_) => _newFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Mật khẩu mới',
              controller: _newPassword,
              focusNode: _newFocus,
              isPassword: true,
              validator: validatePassword,
              errorText: provider.fieldErrors['newPassword'],
              enabled: !saving,
              prefixIcon: Icons.lock_reset_outlined,
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
              validator: (value) =>
                  validateConfirmPassword(_newPassword.text, value),
              errorText: provider.fieldErrors['confirmPassword'],
              enabled: !saving,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => provider.clearFieldError('confirmPassword'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Đặt lại mật khẩu',
              isLoading: saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
