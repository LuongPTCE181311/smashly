# SMASHLY — Elevate Your Game

App thương mại điện tử đồ cầu lông — đồ án môn **PRM393**.
Flutter + SQLite local, không backend.

## Chạy project

```bash
git clone https://github.com/LuongPTCE181311/smashly.git
cd smashly
git checkout develop
flutter pub get
flutter run
```

Lần chạy đầu, app tự tạo file `smashly.db` **trên máy của bạn**, tạo 9 bảng và seed dữ liệu demo.
Màn hình đầu tiên (tạm thời) là **Kiểm tra SQLite**: tất cả dòng phải hiện màu xanh.

Chạy test: `flutter test`

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
- Chỉ TV1 đổi schema. Mỗi lần đổi, TV1 tăng `DbSchema.version`; app trên máy bạn sẽ tự xóa DB cũ và tạo lại.
- Lỗi DB lạ: bấm **Reset demo data** hoặc gỡ app rồi chạy lại.
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
