import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Một lựa chọn phương thức thanh toán. `onTap: null` = đang khóa.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  static (String, String, IconData) _info(PaymentMethod method) =>
      switch (method) {
        PaymentMethod.cod => (
          'Thanh toán khi nhận hàng',
          'COD',
          Icons.payments_outlined,
        ),
        PaymentMethod.bankTransfer => (
          'Chuyển khoản ngân hàng',
          'Quét mã QR hoặc chuyển khoản',
          Icons.account_balance_outlined,
        ),
        PaymentMethod.eWallet => (
          'Ví điện tử',
          'MoMo, ZaloPay, VNPay',
          Icons.account_balance_wallet_outlined,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon) = _info(method);
    final color = selected ? AppColors.primary : AppColors.inkMuted;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.subtitle),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
