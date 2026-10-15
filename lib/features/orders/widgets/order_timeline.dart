import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/order.dart';
import '../../../shared/widgets/order_status_badge.dart';

enum TimelineStepState { done, current, upcoming, cancelled }

class TimelineStep {
  const TimelineStep({
    required this.status,
    required this.state,
    required this.time,
  });

  final OrderStatus status;
  final TimelineStepState state;
  final DateTime? time;

  static const flow = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.shipping,
    OrderStatus.delivered,
  ];

  static List<TimelineStep> fromOrder(Order order) {
    final times = {
      OrderStatus.pending: order.createdAt,
      OrderStatus.confirmed: order.confirmedAt,
      OrderStatus.shipping: order.shippedAt,
      OrderStatus.delivered: order.deliveredAt,
    };

    if (order.status == OrderStatus.cancelled) {
      final reached = flow.lastIndexWhere((status) => times[status] != null);
      return [
        for (final status in flow.take(reached < 0 ? 1 : reached + 1))
          TimelineStep(
            status: status,
            state: TimelineStepState.done,
            time: times[status],
          ),
        TimelineStep(
          status: OrderStatus.cancelled,
          state: TimelineStepState.cancelled,
          time: order.cancelledAt,
        ),
      ];
    }

    final current = flow.indexOf(order.status);
    return [
      for (var i = 0; i < flow.length; i++)
        TimelineStep(
          status: flow[i],
          state: i < current || order.status == OrderStatus.delivered
              ? TimelineStepState.done
              : i == current
              ? TimelineStepState.current
              : TimelineStepState.upcoming,
          time: i <= current ? times[flow[i]] : null,
        ),
    ];
  }
}

class OrderTimeline extends StatefulWidget {
  const OrderTimeline({super.key, required this.order});

  static const stepDelay = Duration(milliseconds: 120);

  final Order order;

  @override
  State<OrderTimeline> createState() => _OrderTimelineState();
}

class _OrderTimelineState extends State<OrderTimeline>
    with SingleTickerProviderStateMixin {
  late final List<TimelineStep> _steps = TimelineStep.fromOrder(widget.order);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: OrderTimeline.stepDelay * _steps.length + AppMotion.normal,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _progressOf(int index) {
    final total = _controller.duration!.inMilliseconds;
    final elapsed = _controller.value * total;
    final start = index * OrderTimeline.stepDelay.inMilliseconds;
    return ((elapsed - start) / AppMotion.normal.inMilliseconds).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            _TimelineRow(
              step: _steps[i],
              isLast: i == _steps.length - 1,
              nextReached:
                  i + 1 < _steps.length &&
                  _steps[i + 1].state != TimelineStepState.upcoming,
              progress: _progressOf(i),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.nextReached,
    required this.progress,
  });

  static const _dotSize = 20.0;

  final TimelineStep step;
  final bool isLast;
  final bool nextReached;
  final double progress;

  Color get _targetColor => switch (step.state) {
    TimelineStepState.cancelled => AppColors.error,
    TimelineStepState.upcoming => AppColors.border,
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(AppColors.border, _targetColor, progress)!;
    final lineColor = nextReached
        ? Color.lerp(AppColors.border, AppColors.primary, progress)!
        : AppColors.border;
    final reached = step.state != TimelineStepState.upcoming;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _Dot(state: step.state, color: color, size: _dotSize),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.status.label,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 14,
                      color: switch (step.state) {
                        TimelineStepState.cancelled => AppColors.error,
                        TimelineStepState.upcoming => AppColors.inkMuted,
                        _ => AppColors.ink,
                      },
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.time != null
                        ? DateFormatter.dateTime(step.time!)
                        : reached
                        ? 'Đang xử lý'
                        : 'Chưa tới',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.color, required this.size});

  final TimelineStepState state;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dot = switch (state) {
      TimelineStepState.upcoming => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
        ),
      ),
      TimelineStepState.cancelled => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: const Icon(
          Icons.close_rounded,
          size: 14,
          color: AppColors.onDark,
        ),
      ),
      _ => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: state == TimelineStepState.done
            ? const Icon(Icons.check_rounded, size: 14, color: AppColors.onDark)
            : null,
      ),
    };

    if (state != TimelineStepState.current) return dot;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
      ),
      child: dot,
    );
  }
}
