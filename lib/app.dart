import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

class SmashlyApp extends StatelessWidget {
  const SmashlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMASHLY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Splash tạm là menu dev; màn kiểm tra SQLite mở từ menu này.
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
