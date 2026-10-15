import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_exception.dart';
import '../../data/models/product.dart';
import '../../providers/admin_product_provider.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/app_dialog.dart';
import '../../shared/widgets/states/empty_state.dart';
import '../../shared/widgets/states/error_state.dart';
import '../../shared/widgets/states/loading_state.dart';
import 'widgets/admin_product_tile.dart';

/// S14 — Admin Products (UC17): tìm, lọc, xóa sản phẩm.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(admin),
          _buildFilters(admin),
          Expanded(child: _buildBody(admin)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sản phẩm'),
      ),
    );
  }

  // ===== HEADER: dải Midnight + ô search =====

  Widget _buildHeader(AdminProductProvider admin) {
    final canPop = Navigator.of(context).canPop();
    final countText = switch (admin.status) {
      ViewStatus.success || ViewStatus.empty => '${admin.resultCount} sản phẩm',
      _ => 'Đang tải...',
    };

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.darkGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canPop)
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.onDark,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý sản phẩm',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.onDark,
                          ),
                        ),
                        Text(
                          countText,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onDarkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  context.read<AdminProductProvider>().setKeyword(value);
                  setState(() {}); // cập nhật nút X
                },
                onSubmitted: (_) =>
                    context.read<AdminProductProvider>().loadProducts(),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc thương hiệu...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clearSearch,
                        ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<AdminProductProvider>().setKeyword('');
    setState(() {});
  }

  // ===== BỘ LỌC: chip "Đang ẩn" + chip danh mục =====

  Widget _buildFilters(AdminProductProvider admin) {
    final query = admin.query;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        children: [
          FilterChip(
            avatar: query.onlyHidden
                ? null
                : const Icon(Icons.visibility_off_outlined, size: 18),
            label: const Text('Đang ẩn'),
            selected: query.onlyHidden,
            onSelected: (_) => _runFilter(admin.toggleHidden),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: VerticalDivider(width: 1),
          ),
          _categoryChip(admin, label: 'Tất cả', categoryId: null),
          for (final category in admin.categories)
            _categoryChip(
              admin,
              label: _categoryLabel(category.name),
              categoryId: category.id,
            ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    AdminProductProvider admin, {
    required String label,
    required int? categoryId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: admin.query.categoryId == categoryId,
        onSelected: (_) => _runFilter(() => admin.selectCategory(categoryId)),
      ),
    );
  }

  void _runFilter(Future<void> Function() action) {
    _searchFocusNode.unfocus();
    action();
  }

  // ===== BODY: 4 trạng thái =====

  Widget _buildBody(AdminProductProvider admin) {
    return switch (admin.status) {
      ViewStatus.initial ||
      ViewStatus.loading => const LoadingState(message: 'Đang tải sản phẩm...'),
      ViewStatus.error => ErrorState(
        message: admin.errorMessage,
        onRetry: admin.retry,
      ),
      ViewStatus.empty =>
        admin.query.hasFilter
            ? EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Không có sản phẩm phù hợp',
                message: 'Thử từ khóa khác hoặc bỏ bớt bộ lọc.',
                actionLabel: 'Xóa bộ lọc',
                onAction: _resetFilters,
              )
            : EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Chưa có sản phẩm nào',
                message: 'Thêm sản phẩm đầu tiên để bắt đầu bán hàng.',
                actionLabel: 'Thêm sản phẩm',
                onAction: () => _openForm(null),
              ),
      ViewStatus.success => _buildList(admin),
    };
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {});
    context.read<AdminProductProvider>().resetFilters();
  }

  Widget _buildList(AdminProductProvider admin) {
    final products = admin.products;

    return RefreshIndicator(
      onRefresh: admin.refresh,
      child: ListView.separated(
        // Chừa chỗ cho FAB ở đáy.
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xs,
          AppSpacing.screen,
          96,
        ),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final product = products[index];
          return AdminProductTile(
            key: ValueKey(product.id),
            product: product,
            categoryName: _categoryLabel(
              admin.categoryNameOf(product.categoryId),
            ),
            busy: admin.isBusy(product.id),
            onEdit: () => _openForm(product.id),
            onDelete: () => _confirmDelete(product),
          );
        },
      ),
    );
  }

  // ===== ĐIỀU HƯỚNG =====

  /// Mở S15: [productId] null = thêm mới. Quay về thì tải lại danh sách.
  Future<void> _openForm(int? productId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.adminProductForm,
      arguments: productId,
    );
    if (!mounted) return;
    context.read<AdminProductProvider>().refresh();
  }

  // ===== XÓA =====

  Future<void> _confirmDelete(Product product) async {
    final admin = context.read<AdminProductProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // 1. Đếm đơn hàng để nói rõ hậu quả trong dialog.
    final int orderCount;
    try {
      orderCount = await admin.countOrdersOf(product);
    } on AppException catch (e) {
      _showMessage(messenger, e.message);
      return;
    }
    if (!mounted) return;

    // Đã ngừng bán và có đơn: xóa nữa cũng không đổi gì.
    if (!product.isActive && orderCount > 0) {
      _showMessage(
        messenger,
        '"${product.name}" đã ngừng bán và có trong $orderCount đơn hàng '
        'nên không thể xóa vĩnh viễn.',
      );
      return;
    }

    // 2. Dialog nêu tên sản phẩm + hậu quả.
    final hardDelete = orderCount == 0;
    final confirmed = await AppDialog.confirm(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Xóa "${product.name}"?',
      message: hardDelete
          ? 'Sản phẩm sẽ bị xóa vĩnh viễn, đồng thời bị gỡ khỏi giỏ hàng và '
                'danh sách yêu thích của khách. Không thể hoàn tác.'
          : 'Sản phẩm đã có trong $orderCount đơn hàng nên sẽ được chuyển '
                'sang Ngừng bán thay vì xóa vĩnh viễn. Khách không còn thấy '
                'sản phẩm, đơn hàng cũ vẫn giữ nguyên.',
      confirmLabel: hardDelete ? 'Xóa vĩnh viễn' : 'Ngừng bán',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    // 3. Xóa → provider tải lại danh sách → SnackBar kết quả.
    try {
      final outcome = await admin.deleteProduct(product);
      switch (outcome) {
        case ProductDeleteOutcome.deleted:
          _showMessage(messenger, 'Đã xóa "${product.name}"');
        case ProductDeleteOutcome.deactivated:
          _showMessage(
            messenger,
            'Đã chuyển "${product.name}" sang Ngừng bán',
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () => _undoDeactivate(admin, messenger, product),
            ),
          );
      }
    } on AppException catch (e) {
      _showMessage(messenger, e.message);
    }
  }

  Future<void> _undoDeactivate(
    AdminProductProvider admin,
    ScaffoldMessengerState messenger,
    Product product,
  ) async {
    try {
      await admin.restoreProduct(product);
      _showMessage(messenger, 'Đã bán lại "${product.name}"');
    } on AppException catch (e) {
      _showMessage(messenger, e.message);
    }
  }

  void _showMessage(
    ScaffoldMessengerState messenger,
    String message, {
    SnackBarAction? action,
  }) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }
}

/// Tên danh mục tiếng Việt (DB lưu tiếng Anh, giống màn Shop).
String _categoryLabel(String name) {
  return switch (name) {
    'Rackets' => 'Vợt',
    'Shoes' => 'Giày',
    'Shirts' => 'Áo',
    'Shorts' => 'Quần',
    'Socks' => 'Tất',
    'Bags' => 'Túi',
    'Grips' => 'Quấn cán',
    'Strings' => 'Cước',
    'Nets' => 'Lưới',
    'Accessories' => 'Phụ kiện',
    _ => name,
  };
}
