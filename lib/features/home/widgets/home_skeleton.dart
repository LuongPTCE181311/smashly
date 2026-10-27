import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.35, end: 0.85).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _box(height: 40),
          const SizedBox(height: AppSpacing.lg),

          _box(height: 52),
          const SizedBox(height: AppSpacing.lg),

          _box(height: 220, radius: AppRadius.xl),

          const SizedBox(height: AppSpacing.section),

          _box(width: 180, height: 24),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, _) =>
                  _box(width: 72, height: 72, radius: AppRadius.lg),
            ),
          ),

          const SizedBox(height: AppSpacing.section),

          _box(width: 210, height: 24),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(child: _box(height: 96)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _box(height: 96)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box({
    double? width,
    required double height,
    double radius = AppRadius.md,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
