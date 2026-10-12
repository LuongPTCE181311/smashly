import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../shell/app_shell.dart';
import '../../shell/app_tab.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào bạn 👋', style: AppTextStyles.caption),
              Text('Elevate Your Game.', style: AppTextStyles.h1),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            AppShell.goToTab(context, AppTab.cart);
          },
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      ],
    );
  }
}
