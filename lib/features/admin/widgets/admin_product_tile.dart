import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import 'admin_stock_label.dart';

enum _TileAction { edit, delete }

/// Một hàng trong danh sách Admin Products: ảnh 56, tên, brand · danh mục,
/// giá, tồn kho (màu + chữ), nhãn "Đang ẩn", menu ⋮ Sửa / Xóa.
class AdminProductTile extends StatelessWidget {
  const AdminProductTile({
    super.key,
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.busy = false,
  });

  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Đang xóa / khôi phục: khóa thao tác, thay menu bằng vòng xoay nhỏ.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final hidden = !product.isActive;
    final subtitle = [
      product.brand.toUpperCase(),
      if (categoryName.isNotEmpty) categoryName,
    ].join(' · ');

    return Material(
      color: hidden ? AppColors.background : AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: busy ? null : onEdit,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: hidden ? 0.5 : 1,
                child: _Thumbnail(imagePath: product.imagePath),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: hidden ? AppColors.inkMuted : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: AppTextStyles.priceSmall.copyWith(
                        color: hidden ? AppColors.inkMuted : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AdminStockLabel(stock: product.stock),
                        if (hidden) const AdminHiddenLabel(),
                      ],
                    ),
                  ],
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<_TileAction>(
                  tooltip: 'Thao tác với ${product.name}',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.inkMuted,
                  ),
                  onSelected: (action) => switch (action) {
                    _TileAction.edit => onEdit(),
                    _TileAction.delete => onDelete(),
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _TileAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Sửa'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _TileAction.delete,
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                        title: Text(
                          'Xóa',
                          style: TextStyle(color: AppColors.error),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        color: AppColors.productTile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.sports_tennis_rounded, color: AppColors.inkMuted),
      ),
    );
  }
}
