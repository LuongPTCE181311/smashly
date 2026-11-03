# SMASHLY — Elevate Your Game

App thương mại điện tử đồ cầu lông — đồ án môn **PRM393**.
Flutter + SQLite local, không backend.

## Môi trường và nền tảng

- Dart `^3.13.3` theo [`pubspec.yaml`](pubspec.yaml); Flutter `>=3.44.0` theo [`pubspec.lock`](pubspec.lock). Dự án chưa pin phiên bản Flutter cụ thể, chưa có `.fvmrc`.
- Có project Android (`android/`) và iOS (`ios/`). Windows dùng SQLite qua `sqflite_common_ffi`, được khởi tạo trong [`lib/main.dart`](lib/main.dart).
- Đã kiểm cài mới trên Windows: Flutter 3.47.7 stable (Hào) và Flutter 3.47.3 (theo QA của Trọng).
- Android: có project nhưng nhóm chưa kiểm trên máy thật/emulator vì chưa có Android SDK.
- Không chạy trên Chrome/Edge: `sqflite` không hỗ trợ web; `main.dart` chỉ cấu hình FFI cho Windows.
- Khi chạy Windows bằng `flutter run` từ thư mục project, DB nằm ở `.dart_tool/sqflite_common_ffi/databases/smashly.db`. [`database_helper.dart`](lib/core/database/database_helper.dart) ghép `getDatabasesPath()` với tên `smashly.db`; đường dẫn mặc định do FFI cung cấp.

## Chạy project

```bash
git clone https://github.com/LuongPTCE181311/smashly.git
cd smashly
git checkout develop
flutter pub get
flutter run
```

Lần chạy đầu, app tự tạo file `smashly.db` **trên máy của bạn**, tạo 9 bảng và seed dữ liệu demo.
App mặc định vào **Splash** theo [`lib/app.dart`](lib/app.dart). Splash mở DB và khôi phục session trước khi điều hướng theo trạng thái đăng nhập.

## Debug và kiểm tra

Mở thẳng menu dev:

```bash
flutter run --dart-define=START_ROUTE=/dev
```

`START_ROUTE` chỉ có tác dụng ở bản debug. Khi mở thẳng `/dev`, app bỏ qua Splash nên chưa khôi phục session vào `AuthProvider`, kể cả khi đã lưu phiên đăng nhập. Muốn vào màn admin: đăng nhập ADMIN → Dashboard → menu avatar → Hồ sơ → Menu dev. `AdminGuard` bảo vệ Dashboard, Products và Product Form; menu dev không bỏ qua quyền admin. Xem [`lib/features/auth/admin_guard.dart`](lib/features/auth/admin_guard.dart) và [`lib/routes/app_routes.dart`](lib/routes/app_routes.dart).

```bash
flutter analyze
flutter test
flutter test test/data/repositories/cart_repository_test.dart
```

Lệnh cuối minh họa chạy test theo file; thay đường dẫn bằng file test cần kiểm tra.

## Tài khoản demo

| Email | Mật khẩu | Role |
| --- | --- | --- |
| admin@smashly.com | Admin@123 | ADMIN |
| customer@smashly.com | Customer@123 | CUSTOMER (có sẵn 4 đơn, 1 món trong giỏ) |
| newbie@smashly.com | Newbie@123 | CUSTOMER (giỏ trống, chưa có đơn) |

## Quy tắc nhóm

- Làm việc trên nhánh `develop`. **Không push lên `main`.**
- Trước khi code và trước khi push: `git pull --rebase origin develop`.
- Không dùng `git push --force`.
- Commit: `feat(home): add hero banner`, `fix(cart): ...`, `chore: ...`

### Ai được sửa file nào

| File / thư mục | Owner |
| --- | --- |
| `pubspec.yaml`, `lib/main.dart`, `lib/core/database/db_schema.dart`, `database_helper.dart`, `seed_users.dart` | TV1 |
| `lib/core/theme/`, `lib/routes/app_routes.dart`, `lib/shared/widgets/` | TV3 |
| `lib/core/database/seed/seed_catalog.dart`, `assets/images/products/` | TV5 |
| `lib/core/database/seed/seed_orders.dart` | TV4 |

Cần sửa file của người khác → nhắn owner.

### SQLite

- Mỗi người có database riêng trên máy mình. **Không commit, không gửi file `.db`.**
- Chỉ TV1 đổi schema. Khi tạo DB mới, `onCreate` tạo bảng rồi seed dữ liệu demo. Khi tăng `DbSchema.version`, `onUpgrade` drop bảng cũ, tạo lại và seed; dữ liệu cũ bị mất. Mở lại DB cùng version không chạy seed. Xem [`lib/core/database/database_helper.dart`](lib/core/database/database_helper.dart).
- Reset DB: ở bản debug, mở Profile → **Reset demo data** → xác nhận. Luồng này xóa session, gọi `DatabaseHelper.resetDatabase()` để đóng/xóa file DB rồi mở lại + seed, sau đó về Splash. Xem [`lib/features/profile/profile_screen.dart`](lib/features/profile/profile_screen.dart). Đây là thao tác thay dữ liệu trên thiết bị bằng dữ liệu demo.
- Không viết SQL trong `features/` — SQL chỉ nằm trong `lib/data/daos/`.

## Cấu trúc thư mục

```text
lib/
├── main.dart, app.dart
├── core/       constants, theme, database (+ seed), services, utils
├── data/       models, daos, repositories
├── providers/
├── routes/
├── shared/widgets/
└── features/   auth, shell, home, shop, product, cart, checkout, orders, profile, admin
assets/images/  brand, banners, categories, brands, states, products/<loại>/
```

Ảnh sản phẩm: PNG nền trong suốt, 800×800, tên `<loại>_<brand>_<model>.png`
(ví dụ `racket_yonex_astrox99pro.png`).
