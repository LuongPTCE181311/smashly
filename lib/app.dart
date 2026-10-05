import 'package:flutter/material.dart';

import 'core/database/db_check_screen.dart';

class SmashlyApp extends StatelessWidget {
  const SmashlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMASHLY',
      debugShowCheckedModeBanner: false,
      // TODO(TV3): thay bằng AppTheme.light trong core/theme/app_theme.dart.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4BFF)),
        useMaterial3: true,
      ),
      // TẠM THỜI: màn kiểm tra SQLite để cả nhóm xác nhận DB trên máy mình.
      // TODO(TV3): đổi sang initialRoute = splash + onGenerateRoute (app_routes.dart).
      home: const DbCheckScreen(),
    );
  }
}
