# Màn Login (S02) — Hào (07/10)

Đã merge vào develop (PR #6). Mọi người pull về và đọc phần liên quan đến mình (mục 4).

## 1. Đã làm

| Phần              | File chính                                          | Ghi chú                                                                                   |
| ----------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Màn Login         | `lib/features/auth/login_screen.dart`               | Validate khi rời ô, nút chỉ bật khi form hợp lệ, khóa form khi loading, banner + rung khi sai |
| Header Auth       | `lib/features/auth/widgets/auth_header.dart`        | Header tối + logo, dùng lại cho Register                                                  |
| Banner lỗi Auth   | `lib/features/auth/widgets/auth_error_banner.dart`  | Icon + chữ, có `liveRegion` cho trình đọc màn hình                                        |
| Route             | `lib/routes/app_routes.dart`                        | Chỉ thay dòng `login`; nhận argument `String` (email điền sẵn)                            |
| Test              | `test/features/auth/`                               | `FakeAuthRepository` + 19 widget test                                                     |
| Test route (file của Lượng) | `test/routes/app_routes_test.dart`        | Bỏ `AppRoutes.login` khỏi `pushedRoutes`: màn thật cần `AuthProvider`, route login thật đã có test 7 trong `login_screen_test.dart` |

## 2. Pull về cần làm gì

```bash
git checkout develop
git pull origin develop
flutter pub get
```

- Không cần xóa DB, không có package mới.
- `flutter run` vào Splash → Login; menu dev: `flutter run --dart-define=START_ROUTE=/dev` (xem `2026-10-07-splash-startup.md`). Tài khoản seed: `admin@smashly.com` / `Admin@123`, `customer@smashly.com` / `Customer@123`, `newbie@smashly.com` / `Newbie@123`.

## 3. Quy ước mới

**Sau khi đăng nhập**

- ADMIN → `AppRoutes.adminDashboard`, CUSTOMER → `AppRoutes.home`, đều bằng `pushNamedAndRemoveUntil(..., (_) => false)`. Bấm Back ở màn đích là **thoát app**, không quay về Login.
- Người dùng hiện tại: `context.watch<AuthProvider>().currentUser` (id: `currentUser?.id`).

**Mở Login với email điền sẵn**

```dart
Navigator.pushNamed(context, AppRoutes.login, arguments: 'a@b.com'); // String
```

**Viết test cho màn dùng `AuthProvider`**

- Dùng `test/features/auth/fake_auth_repository.dart` (`willLogin`, `willFailLogin`, `holdLogin`) với `AuthProvider` thật; kiểm `unexpectedCalls == 0` trong tearDown.

## 4. Ảnh hưởng tới từng người

**Lượng**

- PR này sửa file của Lượng `test/routes/app_routes_test.dart`: bỏ đúng 1 dòng `AppRoutes.login` khỏi `pushedRoutes` (màn thật cần `AuthProvider`; route login thật đã có test riêng dựng qua `AppRoutes.onGenerateRoute`). Khi có Register sẽ bỏ thêm dòng `register`.
- Góp ý widget chung (PR sau): `AppTextField` thêm `textCapitalization`; ô `isPassword` hiện được cả check xanh lẫn nút con mắt.

**Trọng**

- Admin đi thẳng Login → Admin Dashboard, Back thoát app: header Dashboard không cần nút Back.

**Kha**

- CUSTOMER đăng nhập xong vào `AppRoutes.home` (AppShell tab Home): màn Home không có nút Back.

**Danh**

- Lấy `userId` cho giỏ/đơn: `context.read<AuthProvider>().currentUser?.id` sau khi đăng nhập.

## 5. Hào làm tiếp

- Splash (S01): đã xong (PR #7).
- Làm tiếp Profile (S12), rồi Register (S03) (Register chờ Lượng đồng ý thêm `fieldKey` vào `AppTextField`).
