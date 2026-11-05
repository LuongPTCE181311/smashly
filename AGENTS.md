# AGENTS.md – SMASHLY (PRM393)

Luật chung cho mọi thành viên và mọi công cụ AI (Codex, Claude…) làm trong repo này. Trả lời bằng tiếng Việt.

## Thành viên
Lượng (trưởng nhóm), Hào, Kha, Danh, Trọng. Mỗi người sở hữu một domain; quy ước nhóm gốc: `docs/updates/2026-10-06-auth-database.md`, nhật ký thay đổi: `docs/updates/README.md`.

## Kiến trúc
App Flutter bán đồ cầu lông, SQLite cục bộ (sqflite), state bằng Provider.
Luồng: Screen → Provider → Repository → DAO → SQLite (Repository gọi thêm Service khi cần, ví dụ `SessionService`). Mỗi lớp chỉ gọi lớp ngay dưới.

| Lớp | Thư mục | Được làm | Không được làm |
| --- | --- | --- | --- |
| Model | `data/models/` | thuộc tính, `fromMap()`, `toMap()` | gọi DB, chứa logic |
| DAO | `data/daos/` | SQL cho bảng của mình, trả Model; nhận `DatabaseExecutor` để chạy trong/ngoài transaction | kiểm tra nghiệp vụ, `BuildContext` |
| Repository | `data/repositories/` | luật nghiệp vụ, mở `db.transaction`, ném `AppException` câu tiếng Việt | viết SQL, SnackBar, Navigator |
| Provider | `providers/` | trạng thái `ViewStatus`, dữ liệu, gọi Repository | import `sqflite`, Navigator |
| Screen/Widget | `features/`, `shared/` | vẽ UI, gọi Provider, điều hướng | import `sqflite`, SQL, hard-code màu/cỡ chữ |

- API nền (PR #51): `runDb('XxxRepository.hàm', 'Câu dự phòng', () async {...})` bọc truy vấn Repository; `errorMessageOf(error, 'Câu dự phòng')` cho câu lỗi; Repository dựng không tham số (`AuthRepository()`), test truyền `database: () async => db`; Provider mới `extends BaseProvider`, dùng `notify()`, `isDisposed`, `_loadId`; luật nghiệp vụ ở `AppRules`; đổi tab bằng `AppShell.goToTab(context, AppTab.x)`.
- Màn hình switch theo `ViewStatus` để hiện `LoadingState` / `EmptyState` / `ErrorState` / nội dung.
- Ghi nhiều bảng cùng lúc phải nằm trong một `db.transaction` ở Repository, truyền `txn` vào mọi DAO bên trong.
- Không dùng go_router, Riverpod, Bloc, GetX. Không thêm package khi nhóm chưa đồng ý.

## Database
- Không đổi `db_schema.dart` / `DbSchema.version` khi chưa báo chủ file và cả nhóm.
- `cart_items.size` là `TEXT NOT NULL DEFAULT ''` (`''` = không có size). Luôn tra `cart_id` bằng `SELECT id FROM carts WHERE user_id = ?`, không suy từ `user_id`.
- Thời gian trong DB: `'YYYY-MM-DD HH:MM:SS'` UTC. Ghi bằng `dbTime()`, đọc bằng `parseDbTime()`, UI hiển thị `.toLocal()`. Không dùng `toIso8601String()` để ghi DB.
- Hash mật khẩu chỉ qua `PasswordHasher`; email `trim().toLowerCase()` trước khi lưu/tra. Chỉ các hàm `UserDao.findAuth…` được đọc `password_hash`, và chỉ Repository gọi chúng. Session lưu bằng `SessionService` (SharedPreferences), không trong SQLite.

## Git
- Nhánh tách từ `develop`, PR vào `develop`. Tên nhánh theo mã UC, không dùng số SML: `refactor/uc03-register`, `feature/uc05-forgot-password`.
- Việc chung không thuộc UC dùng mã `SYS-<tên>`: nhánh `docs/sys-agents`, commit `docs(SYS-agents): …`, merge title kết thúc `#SYS-agents`.
- Không rebase, amend, push --force, stash, clean. Commit sai: sửa bằng commit mới.
- **Không sửa file của người khác**; thấy cần sửa thì báo chủ file.
- Trước commit: 3 file `windows/flutter/generated_*` nếu chỉ khác xuống dòng (`git diff --ignore-cr-at-eol --stat -- windows/flutter` không ra dòng thống kê) → `git restore` + `git update-index --refresh`. Chỉ `git add` đúng file của việc đó, không `git add .`.
- Commit: `type(UCxx-name): mô tả tiếng Anh` (`refactor`, `feat`, `fix`, `test`, `docs`). Chia commit theo file; UC con commit riêng trong PR của UC cha. Mỗi UC chính 1 PR.
- **Không dấu vết AI** trong commit/PR: không `Co-Authored-By`, không `Claude-Session`, không "Generated with".
- Tiêu đề PR theo mẫu commit; mô tả PR tiếng Anh, 3 mục `## Summary` / `## Changes` / `## Tests`. Body qua stdin, không file tạm, không BOM:
  ```powershell
  $OutputEncoding = New-Object System.Text.UTF8Encoding $false
  $body | gh pr create --base develop --head <nhánh> --title "<tiêu đề>" --body-file -
  ```
- Chỉ mở PR khi `flutter analyze` (chỉ còn cảnh báo cũ đã biết) và `flutter test` xanh.
- Merge: "Create a merge commit", title = dòng mặc định + ` #UCxx` hoặc ` #SYS-xxx`:
  `gh pr merge <số> --merge --subject "Merge pull request #<số> from LuongPTCE181311/<nhánh> #UCxx"`
  Không dùng `--squash`, `--rebase`, `--delete-branch`.

## Quy tắc dừng
- Mỗi bước có "Mong đợi"; kết quả khác thì DỪNG, báo nguyên output.
- KHÔNG coi là khác Mong đợi: cảnh báo `LF will be replaced by CRLF` ở 3 file `windows/flutter/generated_*`; `needs update` (mã 1) của `git update-index --refresh` với file đang sửa thật; dòng `NativeCommandError` của PowerShell khi lệnh flutter trả mã khác 0 vì có cảnh báo.
- `gh pr merge` không in gì khi không có TTY: xác nhận bằng `gh pr view <số> --json state,mergedAt,mergeCommit`, không merge lại.
- `git push` lỗi `remote: Internal Server Error`: kiểm `git ls-remote --heads origin <nhánh>`, chờ 30 s, push lại tối đa 2 lần; không đụng commit.

## Code
- Clean, dễ hiểu ở trình độ Flutter cơ bản; đổi càng ít file càng tốt; giữ API nếu được.
- Ưu tiên `context.watch` thay `context.select` trả record; `setState` thay `ListenableBuilder`; `if/for` thay map lồng.
- Chữ hiển thị: tiếng Việt có dấu hoặc tiếng Anh; không viết hoa toàn bộ câu thông báo. Không `Color(0xFF...)`, `fontSize:` ngoài `core/theme/`.
- Comment tiếng Việt: `///` **một câu** cho class và hàm public; `//` chỉ giải thích "vì sao". Không comment điều code đã tự nói, không để code bị comment out, không nhãn nội bộ (OWNER, S07, SML-xxx, BUG-xx).
- File snake_case, một class public mỗi file; màn hình kết thúc bằng `Screen`; route dùng hằng số trong `AppRoutes`.
- Kiểm `mounted` sau `await`; dispose mọi controller/FocusNode/AnimationController.
- Provider: khối bắt lỗi cuối là `catch (error)`, không `on Exception` (`Error` lọt sẽ kẹt loading). Repository tự bắt lỗi thì chỉ `on DatabaseException`, không `catch (e)` chung.
- State private + getter, collection trả về chỉ-đọc. Query chỉ đọc cột cần dùng.
- Mỗi thay đổi hành vi phải có test. Test cũ đỏ vì đổi tên/chỗ → sửa test; đỏ vì hành vi đổi → DỪNG hỏi người giao việc.

## Test
- Để SQLite sinh lỗi thật (UNIQUE/FOREIGN KEY), không tự tạo `DatabaseException`. Không tự thiết lập điều kiện rồi assert chính điều kiện đó.
- So sánh thời gian bằng thời điểm cố định, không `DateTime.now()`.
- File test đã import `sqflite_common_ffi/sqflite_ffi.dart` thì không import thêm `sqflite/sqflite.dart`.

## Lệnh kiểm tra (Windows PowerShell)
```powershell
[Console]::OutputEncoding = [Text.Encoding]::UTF8
dart format <đúng các file đã sửa>
flutter analyze
flutter test
```
`dart format` chỉ chạy trên đúng file vừa sửa, không `dart format lib`. Cảnh báo cũ đã biết: `lib/features/wishlist/wishlist_screen.dart:7` (của Kha).
Đọc file tiếng Việt trong PowerShell 5: `Get-Content -Encoding utf8`.

## Checklist trước khi coi là xong
- `flutter analyze` không có cảnh báo mới; `flutter test` xanh.
- Màn hình có đủ loading / empty / error / success (nếu áp dụng); app chạy được sau khi gỡ và cài lại.

Nếu máy bạn có `docs/agent/` (file riêng, không commit): đọc `docs/agent/STATUS.md` và làm theo `docs/agent/WORKFLOW.md`.
