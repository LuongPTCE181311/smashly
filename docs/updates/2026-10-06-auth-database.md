# Cập nhật Auth & Database — Hào (06/10)

Tất cả đã merge vào `develop`. Mọi người pull về, chạy lại app (DB tự tạo lại vì DB_VERSION = 3) và đọc phần liên quan đến mình.

## 1. Đã làm

| Phần                      | File chính                                                                       | Ghi chú                                               |
| ------------------------- | -------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Review DB của Lượng       | `lib/core/database/`                                                             | 9 bảng, CHECK, khóa ngoại, index, seed khớp blueprint |
| Sửa schema                | `db_schema.dart`                                                                 | `cart_items.size` = `NOT NULL DEFAULT ''`             |
| Quy ước thời gian         | `lib/core/utils/db_time.dart`                                                    | Mọi cột `*_at` lưu UTC dạng `YYYY-MM-DD HH:MM:SS`     |
| Enum dùng chung           | `lib/core/constants/enums.dart`                                                  | `ViewStatus`, `UserRole`                              |
| Model + DAO mẫu           | `lib/data/models/user.dart`, `lib/data/daos/user_dao.dart`                       |                                                       |
| Repository + Provider mẫu | `lib/data/repositories/auth_repository.dart`, `lib/providers/auth_provider.dart` | Đã gắn vào `MultiProvider` trong `main.dart`          |
| Validate form             | `lib/core/utils/validators.dart`                                                 | Dùng cho mọi form                                     |
| Lỗi nghiệp vụ             | `lib/core/utils/app_exception.dart`                                              | `AppException(message, field: ...)`                   |
| Test                      | `test/`                                                                          | Chạy `flutter test`                                   |

## 2. Quy ước mọi người cần làm theo

**Thời gian**

- Ghi DB: `dbTime(DateTime.now())` — không dùng `toIso8601String()`
- Đọc DB: `parseDbTime(map['created_at'] as String)`
- Hiển thị: `.toLocal()` rồi mới format
- Lý do: trộn 2 kiểu thì `ORDER BY created_at` sắp sai thứ tự và giờ lệch 7 tiếng.

**DAO** — xem mẫu `user_dao.dart`

- Mọi hàm nhận `DatabaseExecutor db` làm tham số đầu, để Repository chạy được trong transaction.
- Luôn `where: 'x = ?'` + `whereArgs`, không nối chuỗi vào SQL.
- Không chứa logic nghiệp vụ.

**Repository** — xem mẫu `auth_repository.dart`

- Ghi nhiều bảng cùng lúc → bọc trong `db.transaction`, truyền `txn` (không phải `db`) vào mọi DAO bên trong.
- Chỉ bắt `on DatabaseException`, đổi thành `AppException` câu tiếng Việt; `debugPrint` lỗi gốc.
- Validate lại input bằng `validators.dart`, dù UI đã validate.

**Provider** — xem mẫu `auth_provider.dart`

- State để private, bên ngoài đọc qua getter.
- Khối bắt lỗi cuối cùng là `catch (error)` (bắt cả `Error`), để `status` không kẹt ở `loading`.
- Không import `sqflite`, không gọi `Navigator`.

**Enum có giá trị lưu DB** — viết theo kiểu `UserRole`:

```dart
enum OrderStatus {
  pending('PENDING'),
  confirmed('CONFIRMED');

  const OrderStatus(this.dbValue);
  final String dbValue;
}
```

**Giỏ hàng**

- Món không có size → `size = ''` (không dùng null). SQLite coi các NULL là khác nhau nên UNIQUE sẽ không chặn trùng.
- Lấy cart của user: tra `SELECT id FROM carts WHERE user_id = ?`, không coi `cart_id = user_id`.

## 3. Dùng AuthProvider

```dart
final auth = context.watch<AuthProvider>();
auth.currentUser;       // User? đang đăng nhập
auth.currentUser?.id;   // userId để query giỏ/đơn
auth.isAdmin;           // kiểm tra quyền
```

## 4. Việc từng người

**Danh**

- Review `auth_repository.dart` (transaction users + carts) và `cart_dao.dart`.
- `cart_dao.dart` hiện chỉ có `createForUser` — bạn viết tiếp các hàm còn lại vào file này.
- Kiểm tra `seed_orders.dart`: cart item seed phải tra `cart_id` theo `user_id`.
- Khi có `CartProvider`, nhắn Hào thêm vào `MultiProvider` trong `main.dart`.

**Trọng**

- Review `db_schema.dart` (phần products, racket_specs) và cách seed dùng `dbTime()`.

**Kha, Lượng**

- Đọc mục 2 trước khi viết DAO/Provider đầu tiên.

## 5. Hào cần để làm Splash → Login → Register

| Cần                                                                                      | Từ    | Nếu chưa có                                          |
| ---------------------------------------------------------------------------------------- | ----- | ---------------------------------------------------- |
| `core/theme/` (màu, chữ, spacing)                                                        | Lượng | Hào dùng widget Material tạm, đánh dấu `TODO(theme)` |
| Widget chung: `AppTextField`, `PrimaryButton` (có loading), `LoadingState`, `ErrorState` | Lượng | Như trên                                             |
| `app_routes.dart` có route `splash`, `login`, `register`, `adminDashboard` + `AppShell`  | Lượng | Hào dùng màn placeholder, đánh dấu `TODO(routes)`    |
| Logo `assets/images/brand/logo_smashly.png`                                              | Lượng | Tạm dùng chữ "SMASHLY"                               |

Ai cần thêm package hoặc khai báo asset trong `pubspec.yaml` → nhắn Hào.
