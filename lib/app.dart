import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class SmashlyApp extends StatelessWidget {
  const SmashlyApp({super.key, this.startRoute = _startRouteFromDefine});

  /// Chỉ dùng ở bản debug: `flutter run --dart-define=START_ROUTE=/dev` mở thẳng
  /// menu dev. Rỗng (mặc định) hoặc bản release → Splash.
  final String startRoute;

  static const _startRouteFromDefine = String.fromEnvironment('START_ROUTE');

  @override
  Widget build(BuildContext context) {
    final initialRoute = kDebugMode && startRoute.isNotEmpty
        ? startRoute
        : AppRoutes.splash;

    return MaterialApp(
      title: 'SMASHLY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Dựng đúng 1 route. `initialRoute: '/dev'` mặc định dựng cả `/` (Splash)
      // bên dưới, Splash chạy ngầm rồi pushReplacement sẽ thay mất menu dev.
      onGenerateInitialRoutes: (_) => [
        AppRoutes.onGenerateRoute(RouteSettings(name: initialRoute)),
      ],
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
