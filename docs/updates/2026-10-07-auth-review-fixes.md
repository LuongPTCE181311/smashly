# Cập nhật sau review theme — Hào (07/10)

Có hiệu lực khi PR `fix/tv1-shared-widget-review` đã merge vào `develop`. Mọi người pull về, làm theo mục 2 và đọc phần liên quan đến mình.

## 1. Đã làm

| Phần                      | File chính                                         | Ghi chú                                                                                  |
| ------------------------- | -------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Review theme của Lượng    | `lib/core/theme/`, `lib/shared/`, `lib/routes/`    | Đã squash merge vào `develop` (`b1d3f55`)                                                |
| Sửa `AppTextField`        | `lib/shared/widgets/inputs/app_text_field.dart`    | 2 lỗi validate: lỗi treo sau `Form.validate()`, báo lỗi khi đang gõ                      |
| Test `AppTextField`       | `test/shared/widgets/app_text_field_test.dart`     | 4 kịch bản (a)–(d); cố ý làm hỏng code 3 cách, cả 3 lần test đều đỏ đúng chỗ             |
| Test route                | `test/routes/app_routes_test.dart`                 | Truyền argument đúng kiểu (trước đây truyền `1` cho mọi route)                           |
| Kiểm chứng font/logo      | `pubspec.yaml`, `assets/`                          | `flutter build apk --debug` thành công; 5 file font + 3 logo có trong APK, khớp pubspec  |

`flutter analyze`: không có lỗi. `flutter test`: 81 test pass.

## 2. Pull về cần làm gì

```bash
git checkout develop
git pull origin develop
flutter pub get
```

- Chạy lại app bằng **stop rồi `flutter run`** (không hot reload), vì có font và asset mới.
- **Không cần xóa DB**: schema không đổi, vẫn `DB_VERSION = 3`.
- Đọc `docs/updates/2026-10-07-theme-widgets-routes.md` của Lượng (theme, widget chung, routes).

## 3. Quy ước mới

**Đổi tab**

- Dùng `AppShell.goToTab(context, AppTab.cart)`, không dùng `Navigator.pushNamed(context, AppRoutes.cart)`.
- Lý do: route của tab dựng một `AppShell` mới, nên `pushNamed` tạo AppShell thứ hai đè lên AppShell cũ (2 bottom nav, Back quay về shell cũ với tab cũ).
- Không gọi `goToTab` từ màn không nằm trong AppShell (admin, login, register): nó sẽ đóng hết các màn mà không đổi tab.
- Vào app từ Login/Splash vẫn dùng `pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false)`.

**`AppTextField` validate thế nào**

- Rời ô → validate, sai thì hiện lỗi.
- Ô đang có lỗi → sửa đúng là lỗi tự mất ngay khi gõ, không cần rời ô.
- Ô đang đúng → gõ thành sai thì chưa báo, chờ tới lúc rời ô.
- `errorText` (lỗi từ server, vd. `auth.fieldErrors['email']`) **không tự mất khi gõ**. Màn hình tự xóa, ví dụ gọi `clearErrors()` của provider trong `onChanged`.

**Argument của route**

- Truyền đúng kiểu đã ghi cạnh hằng số trong `AppRoutes` (vd. `productDetail`: `int`, `login`: `String`).
- Màn đọc argument bằng kiểm tra kiểu, không ép kiểu:

```dart
login => LoginScreen(initialEmail: arguments is String ? arguments : null),
```

- Lý do: `arguments as String?` ném `TypeError` khi ai đó truyền sai kiểu, màn hình đỏ thay vì mở bình thường.

**Kết quả trả về khi pop**

- Đọc bằng `final result = await Navigator.of(context).pushNamed(AppRoutes.x);` rồi kiểm `result is bool` / `result is String`.
- **Không** dùng `pushNamed<bool>(...)` / `pushNamed<String>(...)`: `AppRoutes` tạo `AppPageRoute<dynamic>`, Flutter ép sang `Route<bool?>` sẽ ném `TypeError` ngay khi mở màn.

**Lỗi môi trường thường gặp khi build Android**

- `Android sdkmanager did not install NDK <phiên bản>`: cài tay qua Android Studio → SDK Manager → SDK Tools → tick "Show Package Details" → NDK (Side by side) → cài đúng phiên bản ghi trong thông báo lỗi (máy Hào với Flutter 3.47.6 cần `28.2.13676358`).
- Ổ C ít chỗ: đặt biến môi trường `GRADLE_USER_HOME` sang ổ khác (vd. `D:\Gradle`), rồi khởi động lại VS Code/terminal. Kiểm tra: `echo $env:GRADLE_USER_HOME`.
- Lần build đầu Gradle tải thư viện, mất vài phút; các lần sau nhanh hơn nhiều.

## 4. Việc từng người

**Lượng — duyệt PR này**

- Duyệt PR `fix/tv1-shared-widget-review` (sửa file của Lượng, đã được Lượng đồng ý).

**Đề xuất cho Lượng (PR sau)**

- Sửa `AppShell._active` (biến static): khi có 2 AppShell chồng nhau, đóng shell trên thì `_active` thành `null` dù shell dưới vẫn còn, nên `goToTab` không đổi tab nữa.
- `appBarTheme.titleTextStyle` là `AppTextStyles.h2` (màu `AppColors.ink` cố định), nên đặt `foregroundColor` trắng cho AppBar trên header tối thì tiêu đề vẫn màu ink. Cần sửa để tiêu đề theo `foregroundColor`.

**Trọng**

- Header admin: chờ Lượng sửa `AppBar` rồi mới làm, tránh tự hard-code màu chữ.

**Cả nhóm**

- Thử `flutter build apk --debug` trên máy mình **trước 11/10**. Lỗi thì xem mục 3 hoặc nhắn lên nhóm.

## 5. Hào làm tiếp

- Login → Register → Splash.
- Mốc 11/10: luồng Login → Home chạy được trên cả 5 máy.
