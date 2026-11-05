# Cập nhật Quên mật khẩu UC05 — Hào (05/11)

Nhánh `feature/uc05-forgot-password`; `flutter test` đạt 601/601, `flutter analyze` chỉ còn cảnh báo import cũ ở `wishlist_screen.dart:7`.

## 1. Đã làm

| Phần | File chính | Ghi chú |
| --- | --- | --- |
| Đặt lại mật khẩu | `lib/data/repositories/auth_repository.dart` | Kiểm email + SĐT trong cùng transaction, ghi hash bằng email trong DB làm muối; trả email chuẩn hóa, không ghi session; không khớp dùng một câu lỗi chung |
| Trạng thái màn | `lib/providers/forgot_password_provider.dart` | Provider riêng theo màn; lỗi theo ô hoặc banner, chặn gửi trùng và notify sau dispose |
| Màn Quên mật khẩu | `lib/features/auth/forgot_password_screen.dart` | 4 ô nhập, thanh độ mạnh, SĐT chỉ nhận tối đa 10 số; khóa form và Back lúc lưu |
| Route | `lib/routes/app_routes.dart` | Thêm `AppRoutes.forgotPassword`, nhận email String tùy chọn và tạo Provider theo màn |
| Lối vào từ Login | `lib/features/auth/login_screen.dart` | Link “Quên mật khẩu?”, chuyển email đang gõ; thành công điền email, xóa mật khẩu và hiện SnackBar |
| Kiểm thử | Repository, Provider, Screen, Login và routes | 31 test mới, 570 test cũ xanh; W5 dùng predicate IconButton để kiểm nút Back |

## 2. Pull về cần làm gì

- Không đổi DB/schema/version, không cần xóa app.
- Chạy `flutter test`.

## 3. Quy ước mới

Không có.

## 4. Ảnh hưởng tới từng người

**Lượng**

- `lib/routes/app_routes.dart` thêm hằng `forgotPassword`, các import cần thiết và một nhánh `screen()`.
- `test/routes/app_routes_test.dart` thêm một test route Quên mật khẩu, kiểm email điền sẵn và argument sai kiểu.

**Người viết fake AuthRepository**

- Fake `implements AuthRepository` cần thêm `Future<String> resetPassword({required String email, required String phone, required String newPassword, required String confirmPassword})`.
- Hai fake hiện tại đã cập nhật; fake dùng chung hỗ trợ đếm gọi, lưu tham số, lỗi và chờ kết quả.

**Người khác:** không ảnh hưởng.
