import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../cart/widgets/quantity_stepper.dart';

class AddToCartBar extends StatelessWidget {
  const AddToCartBar({
    super.key,
    required this.quantity,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAdd,
  });

  final int quantity;
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.card,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              QuantityStepper(
                quantity: quantity,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: label,
                  icon: icon,
                  isLoading: isLoading,
                  height: AppSizes.ctaHeight,
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
