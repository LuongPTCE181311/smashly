import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../auth/widgets/auth_error_banner.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.user});

  final User user;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _address = TextEditingController(text: widget.user.address ?? '');
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  bool _submitting = false;

  bool get _hasChanges =>
      _name.text.trim() != widget.user.fullName.trim() ||
      _phone.text.trim() != widget.user.phone.trim() ||
      _address.text.trim() != (widget.user.address ?? '').trim();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  void _changed(String value) {
    context.read<AuthProvider>().clearSaveErrors();
    setState(() {});
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (_submitting || auth.isSaving || !_hasChanges) return;
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final saved = await auth.updateProfile(
      fullName: _name.text,
      phone: _phone.text,
      address: _address.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!auth.isLoggedIn || saved) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final saving = auth.isSaving || _submitting;
    final error = auth.saveErrorMessage;
    return PopScope(
      canPop: !saving,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Sửa thông tin cá nhân', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.lg),
                  if (error != null) ...[
                    AuthErrorBanner(message: error),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AppTextField(
                    label: 'Họ và tên',
                    controller: _name,
                    validator: validateFullName,
                    errorText: auth.saveFieldErrors['fullName'],
                    enabled: !saving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                    onChanged: _changed,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Số điện thoại',
                    controller: _phone,
                    focusNode: _phoneFocus,
                    validator: validatePhone,
                    errorText: auth.saveFieldErrors['phone'],
                    enabled: !saving,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onFieldSubmitted: (_) => _addressFocus.requestFocus(),
                    onChanged: _changed,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Địa chỉ',
                    controller: _address,
                    focusNode: _addressFocus,
                    validator: validateAddress,
                    errorText: auth.saveFieldErrors['address'],
                    enabled: !saving,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    inputFormatters: [LengthLimitingTextInputFormatter(200)],
                    onChanged: _changed,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Lưu',
                    isLoading: saving,
                    onPressed: !saving && _hasChanges ? _save : null,
                  ),
                  TextButton(
                    onPressed: saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
