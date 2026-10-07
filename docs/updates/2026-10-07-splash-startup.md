# Splash (S01) và cách app khởi động — Hào (07/10)

Đã merge vào develop (PR #7). Thay đổi cách mở app của **mọi người**: đọc mục 2 trước khi chạy.

## 1. Đã làm

| Phần                  | File chính                                         | Ghi chú                                                                                       |
| --------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Màn Splash            | `lib/features/auth/splash_screen.dart`             | Mở DB + đọc session, tối thiểu 1,2 s, vào đúng màn theo role; lỗi → "Không khởi tạo được dữ liệu" + Thử lại |
| Mở DB                 | `lib/main.dart`, `lib/data/repositories/auth_repository.dart` | `main.dart` không mở DB nữa; `getCurrentUser()` luôn mở DB trước khi đọc session        |
| Sửa lỗi mở DB         | `lib/core/database/database_helper.dart`           | Mở lỗi thì lần sau mở lại được (trước đây giữ lỗi cũ mãi)                                     |
| Điểm vào app          | `lib/app.dart`, `lib/routes/app_routes.dart`       | `/` = Splash; menu dev mở bằng `--dart-define` (mục 3)                                         |
| Màn chờ Android       | `android/app/src/main/res/` (mục 3)                | Nền `midnight`, không chớp trắng khi mở app                                                   |
| Test                  | `test/features/auth/splash_screen_test.dart`, `test/core/database/database_helper_test.dart` | Đồng hồ giả (không chờ 1,2 s thật); lỗi SQLite thật |

## 2. Pull về cần làm gì

```bash
git checkout develop
git pull origin develop
flutter pub get
```

- **Stop rồi `flutter run`** (không hot reload): đổi `main.dart` và file `android/`.
- `flutter run` giờ vào **Splash → Login**, không còn vào thẳng menu dev. Đăng nhập bằng tài khoản seed (`customer@smashly.com` / `Customer@123`, `admin@smashly.com` / `Admin@123`).
- Đã đăng nhập trước đó thì mở lại app sẽ vào thẳng Home/Admin (session lưu trên máy).
- Không cần xóa DB, không có package mới.

## 3. Quy ước mới

**Mở menu dev (chỉ bản debug)**

```bash
flutter run --dart-define=START_ROUTE=/dev
```

- Menu dev mở thẳng, không qua Splash → chưa có người dùng đăng nhập. Màn nào cần `currentUser` thì vào Login trước (menu dev có mục "S02 · Login").
- Bản release luôn vào Splash, bỏ qua `START_ROUTE`.
- Khi có màn Profile (S12): thêm mục "Menu dev" ở bản debug.

**DB mở ở Splash, không ở `main.dart`**

- Không thêm `await DatabaseHelper.instance.database` vào `main.dart`. DAO vẫn gọi `DatabaseHelper.instance.database` như cũ (mở lười, chỉ mở 1 lần).
- Xem số dòng mỗi bảng: menu dev → "Kiểm tra SQLite".

**Test widget có route `/`**

- `MaterialApp(initialRoute: '/dev')` dựng **cả** `/` (Splash) bên dưới `/dev` (Flutter tách theo dấu `/`). Test dựng app từ menu dev phải dùng `onGenerateInitialRoutes` để chỉ dựng 1 route (xem `lib/app.dart`), hoặc bọc `AuthProvider`.

**File `android/` đã đổi** (thư mục chưa có owner; Hào sửa, cả nhóm biết)

| File | Thay đổi | Lý do |
|---|---|---|
| `res/values/colors.xml` (mới) | `splash_background = #0B1220` | Trùng `AppColors.midnight` |
| `res/drawable/launch_background.xml` | trắng → `@color/splash_background` | Android ≤ 4.4 |
| `res/drawable-v21/launch_background.xml` | `?android:colorBackground` → `@color/splash_background` | Android 5–11 |
| `res/values-v31/styles.xml` (mới) | `windowSplashScreenBackground` | Android 12+ dùng màn chờ hệ thống, không đọc `launch_background` |
| `res/values-night-v31/styles.xml` (mới) | như trên, cho chế độ tối | Qualifier `night` ưu tiên trước API level |
| `AndroidManifest.xml` | `android:label`: `smashly` → `SMASHLY` | Tên dưới icon trên máy đúng thương hiệu |

`NormalTheme` (nền cửa sổ sau frame đầu) giữ nguyên để màn sáng không lộ viền tối khi bàn phím trượt.

## 4. Ảnh hưởng tới từng người

**Cả nhóm**

- Chạy app sẽ vào Login: đăng nhập 1 lần, lần sau vào thẳng Home. Cần menu dev → mục 3.

**Lượng**

- PR này sửa file của Lượng `test/routes/app_routes_test.dart`: `_app()` dùng `initialRoute: AppRoutes.devMenu` → dựng cả Splash (cần `AuthProvider`) → 12 ca đỏ. Đã đổi `_app()` sang `onGenerateInitialRoutes: (_) => [AppRoutes.onGenerateRoute(RouteSettings(name: initialRoute))]` (chỉ dựng 1 route, giống `lib/app.dart`). Khi có Register sẽ bỏ thêm `register` khỏi `pushedRoutes`.
- Góp ý widget chung: `ErrorState`/`EmptyState` cần biến thể nền tối (chữ `ink` không đọc được trên `midnight`); `AppLogo` co chữ theo `textScaler` nên tràn ngang ở màn 320 px + chữ 1,5 lần (Splash đang bọc `FittedBox`); token `onDarkMuted` và nền thanh tiến trình trên nền tối.

**Icon app trên màn chờ Android 12+ (cần người nhận)**

- Android 12+ luôn hiện **icon app** giữa màn chờ hệ thống. Icon hiện tại là **icon Flutter mặc định** (`mipmap-*/ic_launcher.png` trùng file mẫu của Flutter). Tên app đã đổi thành `SMASHLY` trong PR này.
- Cần: icon SMASHLY (dùng `assets/images/brand/logo_mark.png`) cho mọi mật độ `mipmap-*`. **Người nhận: chưa phân công — Hào đề xuất Lượng** (owner logo/brand), Hào hỗ trợ phần `android/`.

## 5. Hào làm tiếp

- Register (S03) sau khi Lượng đồng ý `fieldKey` cho `AppTextField`.
- Profile (S12): đăng xuất, mục "Menu dev" ở bản debug.
