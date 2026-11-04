import 'package:flutter/material.dart';

import '../shared/widgets/states/empty_state.dart';

/// Màn báo không tìm thấy route [routeName].
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy')),
      body: EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy màn này',
        message: routeName,
      ),
    );
  }
}
