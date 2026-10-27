import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_header.dart';
import 'widgets/password_strength_bar.dart';

/// S03 — Tạo tài khoản, trả email về Login mà không tự đăng nhập.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  Map<String, FocusNode> get _fieldFocusNodes => {
    'fullName': _fullNameFocus,
    'email': _emailFocus,
    'phone': _phoneFocus,
    'password': _passwordFocus,
    'confirmPassword': _confirmFocus,
  };

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _clearServerErrors() => context.read<AuthProvider>().clearErrors();

  void _onPasswordChanged(String value) {
    _clearServerErrors();
    if (_confirmPassword.text.isNotEmpty) {
      _confirmKey.currentState!.validate();
    }
  }

  void _focusFirstInvalidField() {
    final fields = [
      (_fullNameFocus, validateFullName(_fullName.text)),
      (_emailFocus, validateEmail(_email.text)),
      (_phoneFocus, validatePhone(_phone.text)),
      (_passwordFocus, validatePassword(_password.text)),
      (
        _confirmFocus,
        validateConfirmPassword(_password.text, _confirmPassword.text),
      ),
    ];
    for (final (focus, error) in fields) {
      if (error == null) continue;
      focus.requestFocus();
      return;
    }
  }

  void _focusServerError(AuthProvider auth) {
    for (final entry in _fieldFocusNodes.entries) {
      if (!auth.fieldErrors.containsKey(entry.key)) continue;
      // Chờ các ô rebuild sang enabled trước khi yêu cầu focus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || auth.isLoading) return;
        if (auth.fieldErrors.containsKey(entry.key)) entry.value.requestFocus();
      });
      return;
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _focusFirstInvalidField();
      return;
    }
    FocusScope.of(context).unfocus();

    final result = await auth.register(
      fullName: _fullName.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      confirmPassword: _confirmPassword.text,
    );
    if (!mounted) return;
    if (result is String) {
      Navigator.of(context).pop(result);
      return;
    }
    _focusServerError(auth);
  }

  void _goBack() {
    if (context.read<AuthProvider>().isLoading) return;
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final (
      isLoading,
      errorMessage,
      fullNameError,
      emailError,
      phoneError,
      passwordError,
      confirmPasswordError,
    ) = context
        .select<
          AuthProvider,
          (bool, String?, String?, String?, String?, String?, String?)
        >(
          (auth) => (
            auth.isLoading,
            auth.errorMessage,
            auth.fieldErrors['fullName'],
            auth.fieldErrors['email'],
            auth.fieldErrors['phone'],
            auth.fieldErrors['password'],
            auth.fieldErrors['confirmPassword'],
          ),
        );

    return PopScope(
      canPop: !isLoading,
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
                      title: 'Create your account',
                    ),
                    Positioned(
                      top: 0,
                      left: AppSpacing.sm,
                      child: SafeArea(
                        bottom: false,
                        child: IconButton(
                          tooltip: 'Quay lại',
                          color: AppColors.onDark,
                          onPressed: isLoading ? null : _goBack,
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
                    child: _buildForm(
                      isLoading: isLoading,
                      errorMessage: errorMessage,
                      fullNameError: fullNameError,
                      emailError: emailError,
                      phoneError: phoneError,
                      passwordError: passwordError,
                      confirmPasswordError: confirmPasswordError,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({
    required bool isLoading,
    required String? errorMessage,
    required String? fullNameError,
    required String? emailError,
    required String? phoneError,
    required String? passwordError,
    required String? confirmPasswordError,
  }) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null) ...[
              AuthErrorBanner(message: errorMessage),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              label: 'Họ tên',
              controller: _fullName,
              focusNode: _fullNameFocus,
              validator: validateFullName,
              errorText: fullNameError,
              enabled: !isLoading,
              showValidCheck: true,
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (_) => _clearServerErrors(),
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Email',
              controller: _email,
              focusNode: _emailFocus,
              validator: validateEmail,
              errorText: emailError,
              enabled: !isLoading,
              showValidCheck: true,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => _clearServerErrors(),
              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Số điện thoại',
              controller: _phone,
              focusNode: _phoneFocus,
              validator: validatePhone,
              errorText: phoneError,
              enabled: !isLoading,
              showValidCheck: true,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              onChanged: (_) => _clearServerErrors(),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Mật khẩu',
              controller: _password,
              focusNode: _passwordFocus,
              isPassword: true,
              validator: validatePassword,
              errorText: passwordError,
              enabled: !isLoading,
              showValidCheck: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: _onPasswordChanged,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            ListenableBuilder(
              listenable: _password,
              builder: (context, _) => _password.text.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: PasswordStrengthBar(password: _password.text),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Nhập lại mật khẩu',
              controller: _confirmPassword,
              fieldKey: _confirmKey,
              focusNode: _confirmFocus,
              isPassword: true,
              validator: (value) =>
                  validateConfirmPassword(_password.text, value),
              errorText: confirmPasswordError,
              enabled: !isLoading,
              showValidCheck: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => _clearServerErrors(),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Tạo tài khoản',
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Đã có tài khoản?',
                  style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
                ),
                TextButton(
                  onPressed: isLoading ? null : _goBack,
                  child: const Text('Đăng nhập'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
