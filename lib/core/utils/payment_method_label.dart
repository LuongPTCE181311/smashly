import 'package:flutter/material.dart';

import '../constants/enums.dart';

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cod => 'Thanh toán khi nhận hàng',
    PaymentMethod.bankTransfer => 'Chuyển khoản ngân hàng',
    PaymentMethod.eWallet => 'Ví điện tử',
  };

  IconData get icon => switch (this) {
    PaymentMethod.cod => Icons.payments_outlined,
    PaymentMethod.bankTransfer => Icons.account_balance_outlined,
    PaymentMethod.eWallet => Icons.account_balance_wallet_outlined,
  };
}
