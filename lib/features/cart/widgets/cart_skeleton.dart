import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

/// Khung xương lúc tải giỏ hàng: cùng bố cục với [CartScreen] (hàng chọn tất
/// cả + vài thẻ món), nhấp nháy nhẹ. Máy bật "giảm chuyển động" thì đứng yên.
class CartSkeleton extends StatefulWidget {
  const CartSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  State<CartSkeleton> createState() => _CartSkeletonState();
}

class _CartSkeletonState extends State<CartSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.emphasis,
  );

  late final Animation<double> _opacity = Tween(
    begin: 1.0,
    end: 0.45,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải giỏ hàng',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacity,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              const _Bar(width: 140, height: 16),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < widget.itemCount; i++) ...[
                const _TileSkeleton(),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Block(width: 72, height: 72, radius: AppRadius.mdAll),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(width: double.infinity, height: 16),
                SizedBox(height: AppSpacing.sm),
                _Bar(width: 120, height: 12),
                SizedBox(height: AppSpacing.md),
                _Bar(width: 90, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      _Block(width: width, height: height, radius: AppRadius.smAll);
}

class _Block extends StatelessWidget {
  const _Block({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.productTile,
        borderRadius: radius,
      ),
    );
  }
}
