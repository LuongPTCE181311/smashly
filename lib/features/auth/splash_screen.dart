import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/buttons/primary_button.dart';

/// S01 — mở DB + khôi phục phiên (qua [AuthProvider.restoreSession]) rồi
/// chuyển đúng màn theo role. Lỗi khởi tạo → thông báo + nút Thử lại.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Tổng thời gian tối thiểu để màn không nháy khi DB mở nhanh.
  static const minDuration = Duration(milliseconds: 1200);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _logo = AnimationController(
    vsync: this,
    duration: AppMotion.emphasis,
  );
  late final _logoCurve = CurvedAnimation(
    parent: _logo,
    curve: AppMotion.normalCurve,
  );
  late final _logoScale = Tween<double>(begin: 0.9, end: 1).animate(_logoCurve);

  bool _logoStarted = false;
  bool _running = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Không gọi restoreSession() ngay trong initState: nó notifyListeners()
    // trong lúc framework đang build. Sau frame đầu thì logo cũng đã hiện.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logoStarted) return;
    _logoStarted = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _logo.value = 1;
    } else {
      _logo.forward();
    }
  }

  @override
  void dispose() {
    _logoCurve.dispose();
    _logo.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    // Chặn ở màn là bắt buộc: provider đang loading thì restoreSession() trả về
    // ngay, Splash sẽ đọc status == loading và báo lỗi giả.
    if (_running || !mounted) return;
    setState(() {
      _running = true;
      _failed = false;
    });

    final auth = context.read<AuthProvider>();
    // Song song: DB nhanh → đủ 1,2 s; DB chậm → đi ngay khi xong. restoreSession
    // không ném (provider catch (error)) nên Future.wait luôn chờ đủ cả hai.
    await Future.wait([
      auth.restoreSession(),
      Future<void>.delayed(SplashScreen.minDuration),
    ]);
    if (!mounted) return;
    // Có route khác đè lên (vd. menu dev) thì pushReplacement sẽ thay mất route
    // trên cùng, không phải Splash → không điều hướng.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    final navigator = Navigator.of(context);
    switch (auth.status) {
      case ViewStatus.success:
        navigator.pushReplacementNamed(
          auth.isAdmin ? AppRoutes.adminDashboard : AppRoutes.home,
        );
      case ViewStatus.empty:
        navigator.pushReplacementNamed(AppRoutes.login);
      case ViewStatus.initial || ViewStatus.loading || ViewStatus.error:
        setState(() {
          _running = false;
          _failed = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.darkGradient),
          child: SafeArea(child: _failed ? _buildError() : _buildLoading()),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            // AppLogo co chữ theo textScaler: màn hẹp + chữ to sẽ tràn ngang.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: FadeTransition(
                opacity: _logoCurve,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 56, onDark: true),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Elevate Your Game.',
                        style: AppTextStyles.body.copyWith(
                          // TODO(theme): xin Lượng token onDarkMuted thay cho alpha tự chọn.
                          color: AppColors.onDark.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            0,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: LinearProgressIndicator(
            minHeight: AppSpacing.xs,
            borderRadius: AppRadius.smAll,
            color: AppColors.primary,
            // TODO(theme): xin Lượng token cho nền thanh tiến trình trên nền tối.
            backgroundColor: AppColors.onDark.withValues(alpha: 0.12),
            semanticsLabel: 'Đang khởi động',
          ),
        ),
      ],
    );
  }

  /// Bố cục lỗi riêng: ErrorState/EmptyState dùng chữ màu ink, không đọc được
  /// trên nền tối (S10).
  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.onDark,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Không khởi tạo được dữ liệu',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: AppColors.onDark),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Kiểm tra bộ nhớ trống của máy rồi thử lại.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                // TODO(theme): xin Lượng token onDarkMuted thay cho alpha tự chọn.
                color: AppColors.onDark.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Thử lại', onPressed: _start, expanded: false),
          ],
        ),
      ),
    );
  }
}
