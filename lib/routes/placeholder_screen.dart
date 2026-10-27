import 'package:flutter/material.dart';

import '../shared/widgets/states/empty_state.dart';

/// Màn tạm cho route chưa có màn thật. Owner thay dòng tương ứng trong
/// `AppRoutes.screen` bằng màn của mình.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.code,
    required this.title,
    required this.owner,
  });

  final String code;
  final String title;
  final String owner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: Icons.construction_rounded,
        title: '$code · $title',
        message:
            'Màn tạm — $owner sẽ thay bằng màn thật trong app_routes.dart.',
      ),
    );
  }
}
