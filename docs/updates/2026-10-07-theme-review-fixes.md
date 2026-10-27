# Sửa theme theo góp ý của Hào + AppDialog + icon app — Lượng (07/10)

Xử lý đủ 8 góp ý trong `2026-10-07-auth-review-fixes.md` (mục 4) và ghi chú Hào gửi Lượng. Không đổi DB, không đổi `pubspec.yaml`, không đổi file của người khác.

## 1. Pull code về cần làm gì

```bash
git checkout develop
git pull origin develop
flutter pub get
```

- Stop app rồi chạy lại (không hot reload).
- Muốn thấy **icon app mới**: gỡ app rồi chạy lại, vì launcher hay giữ icon cũ.
- Không cần xóa DB.

Chạy bằng terminal / điện thoại thật:

- Chạy: `flutter run`. Mở menu dev: `flutter run --dart-define=START_ROUTE=/dev`.
- Gỡ app: nhấn giữ icon SMASHLY trên điện thoại → Gỡ cài đặt, hoặc `adb uninstall com.smashly.smashly`.

Chạy bằng Android Studio (máy ảo):

- Chạy: chọn máy ảo ở thanh trên → nút ▶ Run (đã chạy thì bấm ■ Stop rồi ▶ lại).
- Mở menu dev: **Run → Edit Configurations… → main.dart → Additional run args**, điền `--dart-define=START_ROUTE=/dev` → OK. Xóa dòng này đi là về Splash.
- Gỡ app: trên máy ảo nhấn giữ icon SMASHLY → kéo vào Uninstall, hoặc mở tab **Terminal** của Android Studio gõ `adb uninstall com.smashly.smashly`.
- Font hay icon chưa đổi sau khi pull: **Tools → Flutter → Flutter Clean**, rồi ▶ Run lại.

## 2. Đã làm

| Góp ý                                   | Đã sửa                                                                                         | File                                              |
| --------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| 1. `AppShell._active` static            | Mỗi AppShell tự nhớ route của mình; `goToTab` tìm shell trên cùng còn mở. Không có shell → không đóng màn nào | `features/shell/app_shell.dart`                   |
| 2. Tiêu đề AppBar luôn màu ink          | Tiêu đề theo `foregroundColor` của AppBar                                                      | `core/theme/app_theme.dart`                       |
| 3. `ErrorState` không dùng được nền tối | Thêm `onDark: true` cho `ErrorState` và `EmptyState`                                           | `shared/widgets/states/`                          |
| 4. `AppLogo` co theo cỡ chữ hệ thống    | Logo không co theo cỡ chữ nữa; kích thước chỉ do `size`                                        | `shared/widgets/app_logo.dart`                    |
| 5. `AppTextField`                       | Thêm `textCapitalization`; ô mật khẩu hiện được check xanh (cạnh nút hiện/ẩn)                  | `shared/widgets/inputs/app_text_field.dart`       |
| 6. Thiếu token                          | Thêm `AppColors.onDarkMuted`, `onDarkSubtle`, `errorSoft`                                      | `core/theme/app_colors.dart`                      |
| 7. Icon app là icon Flutter             | Icon từ logo: icon thường + adaptive icon (Android 8+, màn chờ Android 12+) + monochrome (Android 13) | `android/app/src/main/res/mipmap-*`, `drawable/ic_launcher_background.xml` |
| 8. Cần `AppDialog`                      | `AppDialog.confirm(...)` trả về `bool`                                                          | `shared/widgets/app_dialog.dart`                  |

Test mới: `test/shared/theme_review_test.dart` và 2 ca `goToTab` trong `test/routes/app_routes_test.dart`. `flutter test`: tất cả pass.

## 3. Cách dùng

**Token màu mới**

```dart
AppColors.onDarkMuted   // chữ phụ trên nền tối (trắng 72%) — tagline, mô tả
AppColors.onDarkSubtle  // nền nhạt trên nền tối (trắng 12%) — rãnh thanh tiến trình, nền icon
AppColors.errorSoft     // nền khối lỗi (error 8%) — banner lỗi
```

**AppBar trên nền tối** (header admin)

```dart
AppBar(
  backgroundColor: AppColors.midnight,
  foregroundColor: AppColors.onDark,   // tiêu đề, nút Back, icon đều trắng
  title: const Text('SMASHLY Admin'),
)
```

Không tự đặt `titleTextStyle` hay màu cho `Text` tiêu đề nữa.

**Trạng thái trên nền tối**

```dart
ErrorState(
  onDark: true,
  title: 'Không khởi tạo được dữ liệu',
  message: 'Kiểm tra bộ nhớ trống của máy rồi thử lại.',
  onRetry: _start,
)
```

**Dialog xác nhận**

```dart
final ok = await AppDialog.confirm(
  context,
  title: 'Đăng xuất?',
  message: 'Bạn sẽ cần đăng nhập lại để tiếp tục mua sắm.',
  confirmLabel: 'Đăng xuất',
  destructive: true,              // nút xác nhận màu đỏ
  icon: Icons.logout_rounded,     // tùy chọn
);
if (!ok || !context.mounted) return;
```

- Bấm Hủy, bấm ra ngoài hoặc Back đều trả `false`.
- `AppDialog.confirm` dùng `showDialog`, không qua `AppRoutes`, nên không dính lỗi `pushNamed<bool>`.

**Ô nhập**

```dart
AppTextField(label: 'Họ tên', textCapitalization: TextCapitalization.words, ...);
AppTextField(label: 'Mật khẩu', isPassword: true, showValidCheck: true, ...);
```

**`goToTab`** — cách dùng không đổi. Khác ở chỗ: gọi từ màn không có AppShell bên dưới (admin, login…) giờ **không làm gì** (chỉ in log), trước đây sẽ đóng hết các màn.

## 4. Việc từng người

**Hào**

- Thay các `TODO(theme)` bằng token mới (file của Hào nên mình không sửa):
  - `splash_screen.dart` dòng tagline và mô tả lỗi → `AppColors.onDarkMuted`; nền thanh tiến trình → `AppColors.onDarkSubtle`.
  - `auth_header.dart` subtitle → `AppColors.onDarkMuted`.
  - `auth_error_banner.dart` nền → `AppColors.errorSoft`.
- Nếu muốn, `_buildError()` ở Splash có thể thay bằng `ErrorState(onDark: true, ...)`.
- Profile: đổi `AlertDialog` sang `AppDialog.confirm(...)`.
- Register: ô Họ tên dùng `textCapitalization: TextCapitalization.words`; ô mật khẩu dùng được `showValidCheck`.
- Kiểm tra giúp phần `android/res` (icon). Mình chỉ thêm icon, không đụng `styles.xml` hay `colors.xml` của Hào.

**Trọng**

- Header admin: làm theo mẫu AppBar nền tối ở mục 3, không cần chờ nữa.
- Dialog xóa sản phẩm: `AppDialog.confirm(..., destructive: true, icon: Icons.delete_outline)`; nội dung nêu tên sản phẩm và hậu quả (mục 15 blueprint).

**Kha, Danh**

- Không cần sửa gì. Đổi tab vẫn dùng `AppShell.goToTab(context, AppTab.x)`.

## 5. Lượng làm tiếp

- `StatusBadge` / `StockBadge` / `PromoBadge`, `PriceText`, `RatingView`, `QuantityStepper`.
- Widget Catalog (màn debug xem mọi component), gắn vào menu dev.
- Màn Product Detail, My Orders, Order Detail.
