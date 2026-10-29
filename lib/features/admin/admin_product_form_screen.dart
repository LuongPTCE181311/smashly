import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_exception.dart';
import '../../data/models/product.dart';
import '../../data/models/racket_spec.dart';
import '../../providers/admin_product_form_provider.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/inputs/app_text_field.dart';
import '../../shared/widgets/states/error_state.dart';
import '../../shared/widgets/states/loading_state.dart';
import 'admin_category_label.dart';
import 'widgets/product_image_picker_sheet.dart';

// Lựa chọn thông số vợt: giá trị lưu DB (khớp CHECK trong db_schema) → chữ hiển thị.
const _weightOptions = {'2U': '2U', '3U': '3U', '4U': '4U', '5U': '5U'};
const _balanceOptions = {
  'HEAD_LIGHT': 'Nhẹ đầu',
  'EVEN': 'Cân bằng',
  'HEAD_HEAVY': 'Nặng đầu',
};
const _shaftOptions = {
  'FLEXIBLE': 'Dẻo',
  'MEDIUM': 'Trung bình',
  'STIFF': 'Cứng',
  'EXTRA_STIFF': 'Rất cứng',
};
const _levelOptions = {
  'BEGINNER': 'Mới chơi',
  'INTERMEDIATE': 'Trung bình',
  'ADVANCED': 'Nâng cao',
};
const _styleOptions = {
  'ATTACK': 'Tấn công',
  'CONTROL': 'Kiểm soát',
  'ALL_ROUND': 'Toàn diện',
  'DEFENSE': 'Phòng thủ',
};

/// S15 — Admin Product Form (UC18): một màn dùng chung cho thêm và sửa
/// sản phẩm. Thêm hay sửa do [AdminProductFormProvider.isEditing] quyết định.
class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Ô nhập chữ / số.
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _sizesController = TextEditingController();
  final _maxTensionController = TextEditingController();

  // Giá trị chọn bằng nút bấm (không phải ô nhập chữ).
  String? _imagePath;
  String? _imageError;
  int? _categoryId;
  bool _isFeatured = false;

  // Thông số vợt, mặc định cho vợt mới.
  String _weightClass = '4U';
  String _balance = 'EVEN';
  String _shaft = 'MEDIUM';
  String _playerLevel = 'INTERMEDIATE';
  String _playStyle = 'ALL_ROUND';

  /// true khi admin đã sửa gì đó mà chưa lưu → rời màn phải hỏi lại.
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Đợi khung hình đầu vẽ xong mới tải, để provider không
    // notifyListeners() khi cây widget đang build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _sizesController.dispose();
    _maxTensionController.dispose();
    super.dispose();
  }

  // ===== TẢI DỮ LIỆU & ĐIỀN FORM =====

  Future<void> _loadData() async {
    final form = context.read<AdminProductFormProvider>();
    await form.load();
    if (!mounted || form.status != ViewStatus.success) return;
    _fillForm(form);
  }

  /// Chế độ sửa: điền dữ liệu cũ vào các ô. Chế độ thêm: để trống.
  void _fillForm(AdminProductFormProvider form) {
    final product = form.product;
    if (product != null) {
      _nameController.text = product.name;
      _brandController.text = product.brand;
      _descriptionController.text = product.description;
      _priceController.text = '${product.price}';
      _originalPriceController.text = product.originalPrice?.toString() ?? '';
      _stockController.text = '${product.stock}';
      _sizesController.text = product.sizes ?? '';
      _imagePath = product.imagePath;
      _categoryId = product.categoryId;
      _isFeatured = product.isFeatured;
    }

    final spec = form.racketSpec;
    if (spec != null) {
      _weightClass = spec.weightClass;
      _balance = spec.balance;
      _shaft = spec.shaft;
      _playerLevel = spec.playerLevel;
      _playStyle = spec.playStyle;
      _maxTensionController.text = '${spec.maxTensionLbs}';
    }

    // Vừa điền dữ liệu gốc, chưa phải thay đổi của admin.
    setState(() => _hasChanges = false);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  // ===== BUILD =====

  @override
  Widget build(BuildContext context) {
    final form = context.watch<AdminProductFormProvider>();

    return PopScope<Object?>(
      // Có thay đổi chưa lưu → chặn nút Back, hỏi lại trước khi rời màn.
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(form.isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        ),
        body: _buildBody(form),
        bottomNavigationBar: form.status == ViewStatus.success
            ? _buildSaveBar(form)
            : null,
      ),
    );
  }

  Widget _buildBody(AdminProductFormProvider form) {
    return switch (form.status) {
      ViewStatus.initial ||
      ViewStatus.loading => const LoadingState(message: 'Đang tải...'),
      ViewStatus.error => ErrorState(
        message: form.errorMessage,
        onRetry: _loadData,
      ),
      ViewStatus.success || ViewStatus.empty => _buildForm(form),
    };
  }

  Widget _buildForm(AdminProductFormProvider form) {
    final isRacket = form.isRacketCategory(_categoryId);

    return Form(
      key: _formKey,
      // Ô nhập bất kỳ đổi giá trị → đánh dấu có thay đổi chưa lưu.
      onChanged: _markChanged,
      // Dùng Column (không dùng ListView) để mọi ô luôn được dựng, nhờ vậy
      // validate() kiểm tra được cả ô đang nằm ngoài màn hình.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePicker(),
            const SizedBox(height: AppSpacing.lg),
            _buildGeneralInfo(form, isRacket),
            const SizedBox(height: AppSpacing.lg),
            _buildPriceStock(),
            // Nhóm thông số vợt chỉ hiện khi danh mục là Vợt.
            if (isRacket) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildRacketSpecs(),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildDisplaySettings(),
          ],
        ),
      ),
    );
  }

  /// Khung trắng bo góc có tiêu đề, bọc từng nhóm ô nhập.
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.card,
      ),
      // Material trong suốt để hiệu ứng chạm của ListTile/InkWell vẽ được
      // trên nền trắng của khung.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }

  // ===== 1. CHỌN ẢNH =====

  Widget _buildImagePicker() {
    final hasError = _imageError != null;

    return _buildSection(
      title: 'Ảnh sản phẩm',
      children: [
        InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: _pickImage,
          child: Container(
            height: 180,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.productTile,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
              ),
            ),
            child: _imagePath == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppColors.inkMuted,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text('Chạm để chọn ảnh', style: AppTextStyles.body),
                    ],
                  )
                : Image.asset(
                    _imagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.inkMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasError ? _imageError! : 'Chọn từ ảnh có sẵn trong ứng dụng.',
          style: AppTextStyles.caption.copyWith(
            color: hasError ? AppColors.error : AppColors.inkMuted,
          ),
        ),
      ],
    );
  }

  /// Mở bottom sheet lưới ảnh asset; chọn xong thì hiện ảnh trong form.
  Future<void> _pickImage() async {
    final path = await ProductImagePickerSheet.show(
      context,
      selected: _imagePath,
    );
    if (!mounted || path == null || path == _imagePath) return;
    setState(() {
      _imagePath = path;
      _imageError = null;
      _hasChanges = true;
    });
  }

  // ===== 2. THÔNG TIN CHUNG =====

  Widget _buildGeneralInfo(AdminProductFormProvider form, bool isRacket) {
    // Đang sửa một cây vợt mà đổi sang danh mục khác → báo spec cũ sẽ bị xóa.
    final willDeleteSpec = form.racketSpec != null && !isRacket;

    return _buildSection(
      title: 'Thông tin chung',
      children: [
        AppTextField(
          label: 'Tên sản phẩm',
          controller: _nameController,
          validator: (value) => _validateRequired(value, 'tên sản phẩm'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Thương hiệu',
          hint: 'VD: Yonex, Victor, Li-Ning',
          controller: _brandController,
          validator: (value) => _validateRequired(value, 'thương hiệu'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<int>(
          initialValue: _categoryId,
          decoration: const InputDecoration(labelText: 'Danh mục'),
          items: [
            for (final category in form.categories)
              DropdownMenuItem(
                value: category.id,
                child: Text(adminCategoryLabel(category.name)),
              ),
          ],
          validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
          // Đổi danh mục → build lại để hiện/ẩn nhóm thông số vợt.
          onChanged: (value) => setState(() => _categoryId = value),
        ),
        if (willDeleteSpec) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sản phẩm không còn là vợt: thông số vợt cũ sẽ bị xóa khi lưu.',
            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Mô tả (tùy chọn)',
          controller: _descriptionController,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  // ===== 3. GIÁ & KHO =====

  Widget _buildPriceStock() {
    return _buildSection(
      title: 'Giá & kho hàng',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Giá bán (đ)',
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: _digitsOnly(maxLength: 9),
                validator: _validatePrice,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Giá gốc (tùy chọn)',
                controller: _originalPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: _digitsOnly(maxLength: 9),
                validator: _validateOriginalPrice,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Tồn kho',
          controller: _stockController,
          keyboardType: TextInputType.number,
          inputFormatters: _digitsOnly(maxLength: 5),
          validator: _validateStock,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Sizes (tùy chọn)',
          hint: 'Cách nhau bằng dấu phẩy, VD: 39,40,41 hoặc S,M,L',
          controller: _sizesController,
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  /// Chỉ cho gõ chữ số, tối đa [maxLength] ký tự (không gõ được dấu âm).
  List<TextInputFormatter> _digitsOnly({required int maxLength}) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxLength),
    ];
  }

  // ===== 4. THÔNG SỐ VỢT (chỉ hiện khi danh mục là Vợt) =====

  Widget _buildRacketSpecs() {
    return _buildSection(
      title: 'Thông số vợt',
      children: [
        _buildSpecChoice(
          label: 'Trọng lượng',
          options: _weightOptions,
          value: _weightClass,
          onSelected: (value) => _weightClass = value,
        ),
        _buildSpecChoice(
          label: 'Điểm cân bằng',
          options: _balanceOptions,
          value: _balance,
          onSelected: (value) => _balance = value,
        ),
        _buildSpecChoice(
          label: 'Độ cứng đũa',
          options: _shaftOptions,
          value: _shaft,
          onSelected: (value) => _shaft = value,
        ),
        _buildSpecChoice(
          label: 'Trình độ',
          options: _levelOptions,
          value: _playerLevel,
          onSelected: (value) => _playerLevel = value,
        ),
        _buildSpecChoice(
          label: 'Lối chơi',
          options: _styleOptions,
          value: _playStyle,
          onSelected: (value) => _playStyle = value,
        ),
        AppTextField(
          label: 'Sức căng tối đa (lbs)',
          hint: 'Từ 15 đến 40',
          controller: _maxTensionController,
          keyboardType: TextInputType.number,
          inputFormatters: _digitsOnly(maxLength: 2),
          validator: _validateMaxTension,
        ),
      ],
    );
  }

  /// Một dòng chip chọn 1 trong nhiều giá trị (VD: 2U / 3U / 4U / 5U).
  Widget _buildSpecChoice({
    required String label,
    required Map<String, String> options,
    required String value,
    required ValueChanged<String> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in options.entries)
                ChoiceChip(
                  label: Text(option.value),
                  selected: option.key == value,
                  onSelected: (_) => setState(() {
                    onSelected(option.key);
                    _hasChanges = true;
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== 5. CÀI ĐẶT HIỂN THỊ =====

  Widget _buildDisplaySettings() {
    return _buildSection(
      title: 'Cài đặt hiển thị',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sản phẩm nổi bật'),
          subtitle: const Text('Hiện ở mục nổi bật trên trang Home'),
          value: _isFeatured,
          onChanged: (value) => setState(() {
            _isFeatured = value;
            _hasChanges = true;
          }),
        ),
      ],
    );
  }

  // ===== NÚT LƯU CỐ ĐỊNH ĐÁY =====

  Widget _buildSaveBar(AdminProductFormProvider form) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: PrimaryButton(
            label: form.isEditing ? 'Lưu thay đổi' : 'Thêm sản phẩm',
            icon: Icons.save_outlined,
            height: AppSizes.ctaHeight,
            isLoading: form.isSaving,
            onPressed: _onSave,
          ),
        ),
      ),
    );
  }

  // ===== VALIDATE =====

  String? _validateRequired(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) return 'Vui lòng nhập $fieldName';
    return null;
  }

  /// Giá bán bắt buộc và phải > 0.
  String? _validatePrice(String? value) {
    final price = int.tryParse((value ?? '').trim());
    if (price == null) return 'Vui lòng nhập giá bán';
    if (price <= 0) return 'Giá bán phải lớn hơn 0';
    return null;
  }

  /// Giá gốc không bắt buộc; nếu nhập thì phải lớn hơn giá bán.
  String? _validateOriginalPrice(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;

    final originalPrice = int.tryParse(text);
    if (originalPrice == null) return 'Giá gốc không hợp lệ';

    final price = int.tryParse(_priceController.text.trim());
    if (price != null && originalPrice <= price) {
      return 'Giá gốc phải lớn hơn giá bán';
    }
    return null;
  }

  /// Tồn kho bắt buộc và phải ≥ 0.
  String? _validateStock(String? value) {
    final stock = int.tryParse((value ?? '').trim());
    if (stock == null) return 'Vui lòng nhập tồn kho';
    if (stock < 0) return 'Tồn kho không được âm';
    return null;
  }

  /// Sức căng tối đa bắt buộc với vợt, trong khoảng 15–40 lbs.
  String? _validateMaxTension(String? value) {
    final tension = int.tryParse((value ?? '').trim());
    if (tension == null) return 'Vui lòng nhập sức căng tối đa';
    if (tension < 15 || tension > 40) return 'Sức căng phải từ 15 đến 40 lbs';
    return null;
  }

  // ===== LƯU =====

  Future<void> _onSave() async {
    final form = context.read<AdminProductFormProvider>();
    if (form.isSaving) return;

    // 1. Validate: ảnh không phải ô nhập nên kiểm tra riêng, rồi tới cả Form.
    setState(() {
      _imageError = _imagePath == null ? 'Vui lòng chọn ảnh sản phẩm' : null;
    });
    final fieldsValid = _formKey.currentState!.validate();
    if (_imageError != null || !fieldsValid) {
      _showMessage('Vui lòng kiểm tra lại các ô báo lỗi.');
      return;
    }
    FocusScope.of(context).unfocus();

    // 2. Gom dữ liệu trên form thành Product (+ RacketSpec nếu là vợt).
    final product = _buildProduct(form);
    final spec = form.isRacketCategory(_categoryId)
        ? _buildRacketSpec(product.id)
        : null;

    // 3. Provider → Repository → DAO ghi SQLite trong một transaction.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final saved = await form.save(product, spec);
      if (!saved || !mounted) return;
    } on AppException catch (e) {
      _showMessage(e.message);
      return;
    } catch (_) {
      _showMessage('Không thể lưu sản phẩm. Vui lòng thử lại.');
      return;
    }

    // 4. Thành công → báo và quay về màn trước (S14 / Dashboard tự tải lại).
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Đã lưu sản phẩm')));
    // Navigator.pop không bị PopScope chặn nên không hỏi "Bỏ thay đổi?".
    navigator.pop(true);
  }

  Product _buildProduct(AdminProductFormProvider form) {
    // Sản phẩm cũ khi sửa; null khi thêm mới.
    final old = form.product;

    return Product(
      // Thêm mới: DAO bỏ qua id, SQLite tự cấp id mới.
      id: old?.id ?? 0,
      categoryId: _categoryId!,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      price: int.parse(_priceController.text.trim()),
      originalPrice: int.tryParse(_originalPriceController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      // Form không sửa rating và trạng thái bán: thêm mới thì mặc định,
      // sửa thì giữ nguyên giá trị cũ.
      rating: old?.rating ?? 0,
      ratingCount: old?.ratingCount ?? 0,
      description: _descriptionController.text.trim(),
      imagePath: _imagePath!,
      sizes: _normalizedSizes(),
      isFeatured: _isFeatured,
      isActive: old?.isActive ?? true,
    );
  }

  RacketSpec _buildRacketSpec(int productId) {
    return RacketSpec(
      // Thêm mới: Repository thay bằng id vừa được SQLite cấp.
      productId: productId,
      weightClass: _weightClass,
      balance: _balance,
      shaft: _shaft,
      maxTensionLbs: int.parse(_maxTensionController.text.trim()),
      playerLevel: _playerLevel,
      playStyle: _playStyle,
    );
  }

  /// " 39, 40,,41 " → "39,40,41"; để trống → null (sản phẩm không có size).
  String? _normalizedSizes() {
    final sizes = _sizesController.text
        .split(',')
        .map((size) => size.trim())
        .where((size) => size.isNotEmpty)
        .toList();
    return sizes.isEmpty ? null : sizes.join(',');
  }

  // ===== RỜI MÀN & THÔNG BÁO =====

  /// Bấm Back khi còn thay đổi chưa lưu → hỏi lại.
  Future<void> _confirmDiscard() async {
    if (context.read<AdminProductFormProvider>().isSaving) return;

    final discard = await AppDialog.confirm(
      context,
      icon: Icons.edit_off_outlined,
      title: 'Bỏ thay đổi?',
      message: 'Các thay đổi chưa lưu sẽ bị mất.',
      confirmLabel: 'Bỏ thay đổi',
      cancelLabel: 'Ở lại',
      destructive: true,
    );
    if (!discard || !mounted) return;
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
