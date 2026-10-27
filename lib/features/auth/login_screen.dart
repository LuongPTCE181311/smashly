import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_header.dart';

/// S02 — Đăng nhập. [initialEmail] điền sẵn ô email (vd. mở từ lối vào khác).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  /// Gõ chữ không làm cả màn build lại; chỉ nút Đăng nhập nghe 2 controller này.
  late final Listenable _inputs = Listenable.merge([_email, _password]);

  late final _enter = AnimationController(
    vsync: this,
    duration: AppMotion.page,
  );
  late final _enterCurve = CurvedAnimation(
    parent: _enter,
    curve: AppMotion.pageCurve,
  );
  late final _slide = Tween(
    begin: const Offset(0, 0.1),
    end: Offset.zero,
  ).animate(_enterCurve);

  late final _shakeController = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
  );

  bool _enterStarted = false;

  /// Không áp luật độ mạnh mật khẩu ở Login (D2): chỉ cần không trống.
  /// Dùng chung validator với ô để nút và lỗi dưới ô không lệch luật.
  bool get _canSubmit =>
      validateEmail(_email.text) == null &&
      _validatePassword(_password.text) == null;

  static String? _validatePassword(String? value) =>
      validateRequired(value, 'Mật khẩu không được để trống');

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery chưa đọc được trong initState nên bắt đầu animation ở đây, 1 lần.
    if (_enterStarted) return;
    _enterStarted = true;
    if (_reduceMotion) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _enterCurve.dispose();
    _enter.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _clearServerErrors() => context.read<AuthProvider>().clearErrors();

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    if (!_canSubmit) {
      // Chỉ tới được bằng Enter (nút đã disable): hiện lỗi cho người dùng thấy.
      _formKey.currentState?.validate();
      return;
    }
    FocusScope.of(context).unfocus();

    final user = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    if (user == null) {
      // null cũng có thể là "đang loading nên bỏ qua" → chỉ rung khi thật sự lỗi.
      if (auth.status == ViewStatus.error) _shake();
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      user.isAdmin ? AppRoutes.adminDashboard : AppRoutes.home,
      (_) => false,
    );
  }

  Future<void> _openRegister() async {
    final auth = context.read<AuthProvider>();
    auth.clearErrors();
    // Không dùng pushNamed<String>: route của app là AppPageRoute<dynamic>,
    // Navigator ép sang Route<String?> sẽ ném TypeError.
    final result = await Navigator.of(context).pushNamed(AppRoutes.register);
    if (!mounted) return;
    // Bắt buộc kể cả khi Back: Register dùng chung key lỗi 'email' với Login.
    auth.clearErrors();
    if (result is! String) return;

    _email.text = result;
    _password.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tạo tài khoản thành công')));
  }

  void _shake() {
    if (_reduceMotion) return;
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final (isLoading, errorMessage, emailError, passwordError) = context
        .select<AuthProvider, (bool, String?, String?, String?)>(
          (auth) => (
            auth.isLoading,
            auth.errorMessage,
            auth.fieldErrors['email'],
            auth.fieldErrors['password'],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            // Chỉ bọc header: status bar lấy kiểu từ vùng ở mép trên (icon sáng
            // trên nền tối). Bọc cả màn thì `light` còn tô đen thanh điều hướng
            // Android ở mép dưới (systemNavigationBarColor: 0xFF000000).
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: AuthHeader(
                // 40% chiều cao màn (spec). sizeOf không đổi khi bàn phím trượt,
                // nên header không co giữa chừng và màn không build lại mỗi frame.
                height: MediaQuery.sizeOf(context).height * 0.4,
                title: 'Welcome back',
                subtitle: 'Đăng nhập để tiếp tục mua sắm',
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -AppSpacing.xxl),
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _animatedCard(
                  _buildForm(
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    emailError: emailError,
                    passwordError: passwordError,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Slide-up + fade khi vào màn, rung ngang khi lỗi. Key nằm trên chính card
  /// (bên trong cả 2 transform) để test đo được vị trí thật.
  Widget _animatedCard(Widget child) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _enterCurve,
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final t = _shakeController.value;
            final dx = math.sin(t * 4 * math.pi) * AppSpacing.sm * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Container(
            key: const Key('login_card'),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.xlAll,
              boxShadow: AppShadows.card,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildForm({
    required bool isLoading,
    required String? errorMessage,
    required String? emailError,
    required String? passwordError,
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
              label: 'Email',
              controller: _email,
              validator: validateEmail,
              errorText: emailError,
              enabled: !isLoading,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onChanged: (_) => _clearServerErrors(),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Mật khẩu',
              controller: _password,
              focusNode: _passwordFocus,
              isPassword: true,
              validator: _validatePassword,
              errorText: passwordError,
              enabled: !isLoading,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) => _clearServerErrors(),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            ListenableBuilder(
              listenable: _inputs,
              builder: (context, _) => PrimaryButton(
                label: 'Đăng nhập',
                isLoading: isLoading,
                onPressed: _canSubmit ? _submit : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Chưa có tài khoản?',
                  style: AppTextStyles.body.copyWith(color: AppColors.inkMuted),
                ),
                TextButton(
                  // Khóa khi loading (D3): login thành công sẽ xóa cả Register đang mở.
                  onPressed: isLoading ? null : _openRegister,
                  child: const Text('Đăng ký'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
