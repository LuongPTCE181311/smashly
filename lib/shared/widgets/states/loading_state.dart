import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Trạng thái đang tải mặc định: spinner giữa màn + câu mô tả (tùy chọn).
///
/// Màn có lưới/danh sách lớn (Home, Shop, Orders) nên dùng skeleton đúng
/// hình nội dung thay vì widget này.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
