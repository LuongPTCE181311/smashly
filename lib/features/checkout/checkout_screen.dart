import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/validators.dart';
import '../../data/models/cart_item.dart';
import '../../data/repositories/order_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../shell/app_shell.dart';
import '../shell/app_tab.dart';
import 'widgets/checkout_section.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/payment_method_tile.dart';

/// S08 · Thanh toán. OWNER: Danh.
///
/// Đặt các món đang chọn trong giỏ. Thông tin nhận hàng điền sẵn từ tài khoản,
/// 3 phương thức thanh toán chỉ mô phỏng (không có cổng thanh toán thật).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _phone = TextEditingController();
  late final _address = TextEditingController();
  final _note = TextEditingController();

  PaymentMethod _method = PaymentMethod.cod;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _name.text = user?.fullName ?? '';
    _phone.text = user?.phone ?? '';
    _address.text = user?.address ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final checkout = context.read<CheckoutProvider>();
    if (checkout.isPlacing) return;
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    FocusScope.of(context).unfocus();

    final cart = context.read<CartProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final order = await checkout.placeOrder(
      userId: userId,
      receiverName: _name.text,
      receiverPhone: _phone.text,
      shippingAddress: _address.text,
      paymentMethod: _method,
      note: _note.text,
    );

    // Dù thành công (giỏ đã đổi) hay lỗi hết hàng (kho đã đổi), giỏ phải tải
    // lại để badge và cảnh báo tồn kho ở tab Giỏ hàng đúng.
    cart.load();
    if (order == null) {
      final message = checkout.errorMessage;
      if (message != null) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }
    // pushReplacement: Back từ màn thành công không quay lại Checkout.
    navigator.pushReplacementNamed(AppRoutes.orderSuccess, arguments: order.id);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isPlacing = context.select<CheckoutProvider, bool>(
      (checkout) => checkout.isPlacing,
    );
    final items = cart.selectedItems.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: items.isEmpty && !isPlacing
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Chưa có sản phẩm để thanh toán',
              message: 'Hãy chọn món trong giỏ hàng trước.',
              actionLabel: 'Về giỏ hàng',
              onAction: () => AppShell.goToTab(context, AppTab.cart),
            )
          : _buildForm(cart, items, isPlacing),
    );
  }

  Widget _buildForm(CartProvider cart, List<CartItem> items, bool isPlacing) {
    final subtotal = cart.selectedTotal;
    final shippingFee = OrderRepository.shippingFeeFor(subtotal);
    final total = subtotal + shippingFee;

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                CheckoutSection(
                  title: 'Thông tin nhận hàng',
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Họ và tên',
                        controller: _name,
                        validator: validateFullName,
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        enabled: !isPlacing,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Số điện thoại',
                        controller: _phone,
                        validator: validatePhone,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        enabled: !isPlacing,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Địa chỉ giao hàng',
                        controller: _address,
                        validator: (v) =>
                            validateRequired(v, 'Địa chỉ không được để trống'),
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        textInputAction: TextInputAction.next,
                        enabled: !isPlacing,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Ghi chú (không bắt buộc)',
                        controller: _note,
                        prefixIcon: Icons.edit_note_rounded,
                        textInputAction: TextInputAction.done,
                        enabled: !isPlacing,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                CheckoutSection(
                  title: 'Phương thức thanh toán',
                  caption: 'Chỉ mô phỏng, không có giao dịch thật',
                  child: Column(
                    children: [
                      for (final method in PaymentMethod.values)
                        PaymentMethodTile(
                          method: method,
                          selected: method == _method,
                          onTap: isPlacing
                              ? null
                              : () => setState(() => _method = method),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                CheckoutSection(
                  title: 'Đơn hàng (${items.length})',
                  child: OrderSummaryCard(
                    items: items,
                    subtotal: subtotal,
                    shippingFee: shippingFee,
                    total: total,
                  ),
                ),
              ],
            ),
          ),
        ),
        _CheckoutBar(total: total, isPlacing: isPlacing, onPressed: _submit),
      ],
    );
  }
}

/// Thanh cố định đáy: 'Đặt hàng · số tiền'. `isLoading` của PrimaryButton chặn
/// bấm lần 2 ở giao diện; CheckoutProvider chặn thêm ở tầng logic.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.isPlacing,
    required this.onPressed,
  });

  final int total;
  final bool isPlacing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: PrimaryButton(
            label: 'Đặt hàng · ${CurrencyFormatter.format(total)}',
            height: AppSizes.ctaHeight,
            isLoading: isPlacing,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
