import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../product_image_assets.dart';

/// Bottom sheet chọn ảnh sản phẩm từ asset có sẵn (S15), chia nhóm theo
/// thư mục. Trả về đường dẫn ảnh được chọn, hoặc null nếu đóng sheet.
///
/// ```dart
/// final path = await ProductImagePickerSheet.show(context, selected: _imagePath);
/// ```
class ProductImagePickerSheet extends StatelessWidget {
  const ProductImagePickerSheet({super.key, this.selected});

  /// Ảnh đang chọn trong form, được viền xanh.
  final String? selected;

  static Future<String?> show(BuildContext context, {String? selected}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (_) => ProductImagePickerSheet(selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        children: [
          const Text('Chọn ảnh sản phẩm', style: AppTextStyles.h2),
          for (final group in ProductImageAssets.groups.entries) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(group.key, style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              // Lưới nằm trong ListView nên không tự cuộn.
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final path in group.value) _buildThumbnail(context, path),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, String path) {
    final isSelected = path == selected;

    return InkWell(
      borderRadius: AppRadius.mdAll,
      // Bấm ảnh → đóng sheet, trả đường dẫn về cho form.
      onTap: () => Navigator.of(context).pop(path),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.productTile,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.broken_image_outlined,
            color: AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}
