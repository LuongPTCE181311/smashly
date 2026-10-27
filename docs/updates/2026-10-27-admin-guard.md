# Cập nhật Admin guard UC02 — Hào (27/10)

Task SML-047 (UC02), nhánh `feature/SML-047-uc02-login`, từ `develop` tại `2023a78`.

## 1. Đã làm

| Phần | File chính | Ghi chú |
| --- | --- | --- |
| Admin guard | `lib/features/auth/admin_guard.dart` | Chỉ ADMIN thấy child; chưa đăng nhập hoặc CUSTOMER về Login và xóa stack khi route guard đang ở trên cùng; không đổi session/provider, không gọi logout, không SnackBar |
| Tích hợp routes | `lib/routes/app_routes.dart` | Thêm `_adminOnly` và bọc guard trong builder của `onGenerateRoute`; giữ nguyên `screen()` |
| Test guard | `test/features/auth/admin_guard_test.dart` | Kiểm child chưa từng mount khi thiếu quyền, route đầu tiên, logout, route bị che và rebuild liên tiếp không push Login lặp |
| Test routes | `test/routes/app_routes_test.dart` | Test admin đăng nhập trước khi push; test `goToTab` dùng 404; kiểm khách/CUSTOMER về Login và `adminProfile` không bị guard |

## 2. Pull về cần làm gì

- Không đổi DB/schema/version, không cần xóa app.
- Chạy `flutter test` như thường lệ.
- Menu dev và `START_ROUTE` mở màn thuộc `_adminOnly` khi chưa đăng nhập sẽ về Login; không có cờ tắt guard ở debug.
- Muốn test admin: đăng nhập `admin@smashly.com` / `Admin@123` → Dashboard → Profile admin → Menu dev. Cần Dashboard của Trọng có lối sang Products/Form/Profile admin; Dashboard hiện tại vẫn là placeholder nên luồng này chờ Trọng hoàn thiện.

## 3. Quy ước mới

- Các route bị guard: `adminDashboard`, `adminProducts`, `adminProductForm`. `adminProfile` không guard để giữ luồng logout/reset của Profile.
- Route admin mới cần bảo vệ phải thêm vào `_adminOnly` trong `AppRoutes`.
- Màn admin đi qua các route được bảo vệ không cần tự kiểm role trong `initState` nữa.
- Khi thiếu quyền, child không được gắn vào cây, provider admin không được tạo. Nếu guard bị route khác che, chỉ gỡ child; khi lộ lại và vẫn thiếu quyền mới chuyển Login.
- Guard chỉ điều hướng bằng `pushNamedAndRemoveUntil(AppRoutes.login, (_) => false)`, không đổi session/provider và không gọi logout.

## 4. Ảnh hưởng tới từng người

**Lượng**

- `lib/routes/app_routes.dart` chỉ thêm import guard, tập `_adminOnly` cạnh hằng admin và bọc guard trong builder của `onGenerateRoute`; không sửa `screen()`.
- `test/routes/app_routes_test.dart` nhận auth truyền vào, login ADMIN trước hai test route admin, dùng route 404 cho test không có AppShell và thêm test quyền/adminProfile.

**Trọng**

- Menu dev/`START_ROUTE` không cho mở Dashboard/Products/Form khi chưa có quyền ADMIN; cần đăng nhập admin trước.
- Dashboard cần có lối sang Products/Form/Profile admin để test và mở Menu dev từ Profile admin.
- Khi thêm route admin cần bảo vệ, thêm vào `_adminOnly`; không tự kiểm role trong `initState` của màn đi qua guard.

**Cả nhóm:** không dùng menu dev hoặc `START_ROUTE` để bỏ qua quyền admin; `adminProfile` vẫn giữ hành vi Profile hiện có.

## 5. Hào làm tiếp

- Kiểm tra luồng admin trên app khi Dashboard có lối sang Products/Form/Profile admin.
- SML-049: README.
