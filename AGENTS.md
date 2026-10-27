# AGENTS.md — SMASHLY (PRM393)

## Bối cảnh

- App Flutter bán đồ cầu lông, SQLite local (sqflite), state management bằng Provider.
- Tài liệu gốc: `docs/blueprint.md`. Khi cần spec một màn hình, đọc mục tương ứng trong file đó (S01 Splash, S02 Login, S03 Register ở mục 7; S12 Profile ở cuối file, sau mục 34; DB ở mục 16–17, 27–28; quy tắc Git ở mục 26).
- Quy ước nhóm đã thống nhất: `docs/updates/2026-10-06-auth-database.md`.
- Nhóm 5 người, mỗi người sở hữu một domain. Người dùng Codex trong repo này là **Hào — Auth & Database (TV1)**.

## Phạm vi của Hào (chỉ được sửa các file này)

- `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`
- `lib/core/database/` (`db_schema.dart`, `database_helper.dart`, `seed/seed_users.dart`, `seed/seed_demo_data.dart`)
- `lib/core/services/session_service.dart`
- `lib/core/utils/validators.dart`, `password_hasher.dart`, `app_exception.dart`, `db_time.dart`
- `lib/core/constants/enums.dart` (chỉ `UserRole`, `ViewStatus`)
- `lib/data/models/user.dart`, `lib/data/daos/user_dao.dart`, `lib/data/repositories/auth_repository.dart`
- `lib/providers/auth_provider.dart`
- `lib/features/auth/`, `lib/features/profile/`
- `test/` cho các phần trên

Nếu thay đổi cần chạm file ngoài danh sách (theme, shared widgets, routes, cart, product, admin…): **dừng lại, không sửa**, báo rõ file nào, cần thay đổi gì, để Hào nhắn owner.

## Kiến trúc bắt buộc

Luồng: Screen → Provider → Repository → DAO → SQLite. Mỗi lớp chỉ gọi lớp ngay dưới.

| Lớp           | Thư mục              | Được làm                                                                                          | Không được làm                              |
| ------------- | -------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| Model         | `data/models/`       | thuộc tính, `fromMap()`, `toMap()`                                                                | gọi DB, chứa logic                          |
| DAO           | `data/daos/`         | SQL cho bảng của mình, trả về Model; nhận `DatabaseExecutor` để chạy được trong/ngoài transaction | kiểm tra nghiệp vụ, `BuildContext`          |
| Repository    | `data/repositories/` | luật nghiệp vụ, hash mật khẩu, mở `db.transaction`, ném `AppException` với câu tiếng Việt         | viết SQL, SnackBar, Navigator               |
| Provider      | `providers/`         | `ViewStatus status`, dữ liệu, `String? errorMessage`, gọi Repository, `notifyListeners()`         | import `sqflite`, Navigator                 |
| Screen/Widget | `features/`          | vẽ UI, gọi Provider, điều hướng                                                                   | import `sqflite`, SQL, hard-code màu/cỡ chữ |

- `enum ViewStatus { initial, loading, success, empty, error }` trong `core/constants/enums.dart`. Màn hình switch theo status để hiện `LoadingState` / `EmptyState` / `ErrorState` / nội dung.
- Ghi nhiều bảng cùng lúc (ví dụ Register: INSERT `users` + INSERT `carts`) phải nằm trong một `db.transaction` ở Repository, truyền `txn` vào mọi DAO bên trong.
- Không thêm package mới nếu chưa được Hào đồng ý. Package đã chốt: provider, sqflite, path, shared_preferences, crypto, intl (tùy chọn: flutter_animate, shimmer); dev: sqflite_common_ffi.
- Không đổi `db_schema.dart` / `DB_VERSION` trừ khi Hào yêu cầu rõ.
- Không dùng go_router, Riverpod, Bloc, GetX.

## Database

- Lượng đã dựng nền SQLite và bàn giao cho Hào. Không viết lại từ đầu; chỉ sửa chỗ lệch blueprint sau khi Hào đồng ý.
- Seed chạy mỗi khi bảng vừa được tạo mới (onCreate và onUpgrade sau khi drop), không bao giờ chạy khi mở DB đã có sẵn.
- `cart_items.size` là `TEXT NOT NULL DEFAULT ''`; `''` nghĩa là sản phẩm không có size (SQLite coi các NULL là khác nhau trong UNIQUE nên không dùng NULL).
- Không bao giờ suy ra `cart_id` từ `user_id`; luôn tra `SELECT id FROM carts WHERE user_id = ?`.
- Callback onCreate/onUpgrade của sqflite đã chạy trong transaction; seed không cần tự mở transaction.
- Thời gian trong DB: luôn 'YYYY-MM-DD HH:MM:SS' theo UTC (giống CURRENT_TIMESTAMP). Ghi bằng `dbTime()`, đọc bằng `parseDbTime()` trong `core/utils/db_time.dart`; UI hiển thị bằng `.toLocal()`. Không dùng `toIso8601String()` để ghi DB.
- `DatabaseHelper.onConfigure/onCreate/onUpgrade` là static public để test dùng chung; có `resetDatabase()`.

## Luật nghiệp vụ Auth

- Hash mật khẩu chỉ qua `PasswordHasher` trong `core/utils/password_hasher.dart` (hiện là SHA-256 của `email:password`, email đã chuẩn hóa). Không tự ghép chuỗi hay gọi `crypto` ở nơi khác. Email luôn `trim().toLowerCase()` trước khi lưu/tra cứu.
- Chỉ `UserDao.findAuthByEmail` được đọc `password_hash`; model `User` không chứa hash.
- Register: role luôn `'CUSTOMER'` (cứng trong code), tạo dòng `carts` cho user mới trong cùng transaction, không auto-login; thành công → quay về Login với email điền sẵn + SnackBar "Tạo tài khoản thành công".
- Validate: tên ≥ 2 ký tự; email đúng định dạng và chưa tồn tại; SĐT 10 số bắt đầu bằng 0; mật khẩu ≥ 8 ký tự, có cả chữ và số (không trim mật khẩu); xác nhận khớp.
- Login: email đúng định dạng, mật khẩu không trống. Sai: chỉ báo chung "Email hoặc mật khẩu chưa đúng". ADMIN → Admin Dashboard, CUSTOMER → App shell; dùng `pushAndRemoveUntil`.
- Lỗi gắn với ô nhập: `AppException(message, field: ...)`; field keys: 'fullName', 'email', 'phone', 'password', 'confirmPassword'.
- Session lưu bằng `SessionService` (SharedPreferences: `isLoggedIn`, `userId`), không lưu trong SQLite. Logout xóa session. Session trỏ tới user không tồn tại → xóa session.
- Splash: mở DB, đọc session, tối thiểu 1,2 s, `pushReplacement`; lỗi DB → "Không khởi tạo được dữ liệu" + nút Thử lại.
- Tài khoản seed: admin@smashly.com / Admin@123 (ADMIN), customer@smashly.com / Customer@123, newbie@smashly.com / Newbie@123.

## Quy ước code

- Chữ hiển thị: tiếng Việt có dấu đầy đủ hoặc tiếng Anh; không viết hoa toàn bộ câu thông báo.
- Không `Color(0xFF...)`, `fontSize: 17`… trong màn hình — dùng token trong `core/theme/` và widget trong `shared/widgets/`.
- Comment: không giải thích cú pháp cơ bản; chỉ doc comment ngắn cho nghiệp vụ hoặc lưu ý kỹ thuật quan trọng.
- Kiểm tra `mounted` trước khi dùng `context` sau `await`. Dispose mọi controller/FocusNode/AnimationController.
- `AuthProvider.clearErrors()` chỉ gọi trong event handler (onTap, onPressed) trước khi chuyển màn, không gọi trong build/initState/dispose.
- File test đã import `package:sqflite_common_ffi/sqflite_ffi.dart` thì không import thêm `package:sqflite/sqflite.dart`.
- File snake_case, một class công khai mỗi file; màn hình kết thúc bằng `Screen`; route dùng hằng số trong `AppRoutes`.

## Cách làm việc với Hào

- Trước khi viết code cho một việc mới: trình bày kế hoạch (file nào, hàm nào, luồng dữ liệu) và giải thích lý thuyết liên quan trong chat. Chờ Hào đồng ý rồi mới sửa.
- Làm từng lớp một (Model → DAO → Repository → Provider → Screen), dừng sau mỗi lớp để Hào review.
- Không tự chạy `flutter` / `dart` (bị treo trong sandbox trên Windows). Sau khi sửa, ghi rõ các lệnh cần chạy (`flutter analyze`, `flutter test <file>`) để Hào tự chạy và dán kết quả lại.
- Không tự commit, không push, không chạy lệnh git làm thay đổi lịch sử.
- Khi được nhờ viết commit message: tiếng Anh, Conventional Commits `type(scope): summary` + body nói what/why.

## Bắt buộc ở mỗi bước

- Trước khi code: liệt kê mọi cách hàm có thể thất bại (Exception, Error, null, mất `mounted`, bấm 2 lần, lỗi giữa transaction) và cách xử lý.
- Ưu tiên viết test trước từ spec, chờ Hào duyệt test rồi mới viết code.
- Cuối mỗi bước: liệt kê những gì trong kế hoạch CHƯA làm.

## Bài học đã gặp (không lặp lại)

- Provider: khối bắt lỗi cuối là `catch (error)`, không phải `on Exception` — `Error` (TypeError, ArgumentError) không phải `Exception`, để lọt sẽ kẹt `loading`.
- Test không tự tạo `DatabaseException`; để SQLite sinh lỗi thật (vi phạm UNIQUE/FOREIGN KEY).
- Test không tự thiết lập điều kiện rồi kiểm tra chính điều kiện đó (ví dụ tự bật PRAGMA rồi assert PRAGMA).
- Test so sánh thời gian dùng thời điểm cố định, không dùng `DateTime.now()`.
- Query chỉ đọc cột cần dùng; không đọc `password_hash` ngoài `findAuthByEmail`.
- Provider/model dùng chung: state private + getter, collection trả về dạng chỉ-đọc.
- Repository chỉ bắt `on DatabaseException`, không `catch (e)` chung (nuốt mất AppException ném từ trong transaction).
- `Navigator.push`/`pushNamed` gán vào biến có kiểu: ghi rõ type argument (`push<dynamic>(...)`), không để Dart suy ra `T` từ biến nhận (lỗi `Route<Object>`/TypeError khi route là `<dynamic>`).

## Checklist trước khi coi là xong

- `flutter analyze` không còn issue.
- `flutter test` xanh.
- Không có `import 'package:sqflite/...'` trong `features/` hay `shared/`.
- Không hard-code màu/cỡ chữ.
- Màn hình có đủ loading / empty / error / success (nếu áp dụng).
- Chỉ sửa file trong phạm vi của Hào.
- App chạy được sau khi gỡ và cài lại.
