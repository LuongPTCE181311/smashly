# SML-083 — UC18 Thêm / sửa sản phẩm (Admin Product Form · S15)

> Backlog: **SML-083** · Ưu tiên: MUST · Ước lượng: 2 điểm · Actor: Admin
> Spec gốc: blueprint mục 7, phần **S15 — Admin Product Form (Add / Edit)**.

## 1. Tóm tắt

S15 là **một màn hình dùng chung cho cả Thêm và Sửa sản phẩm**. Thêm hay sửa chỉ khác nhau ở tiêu đề và dữ liệu được điền sẵn. Admin chọn ảnh có sẵn trong app (không upload từ máy), nhập thông tin và giá/kho. **Nếu danh mục là Vợt** thì hiện thêm nhóm "Thông số vợt". Khi bấm Lưu, form kiểm tra dữ liệu rồi ghi `products` và `racket_specs` vào SQLite trong **một transaction**. Nếu admin bấm Back khi còn thay đổi chưa lưu, app hỏi lại "Bỏ thay đổi?".

Acceptance đã đạt:

| Yêu cầu | Đáp ứng ở đâu |
| --- | --- |
| Thêm sản phẩm xong thì hiện ngay ở Shop của khách | Sản phẩm mới có `is_active = 1`, mỗi lần mở Shop lại đọc DB (mục 3.4) |
| Giá > 0, tồn kho ≥ 0 | [`_validatePrice`](../../lib/features/admin/admin_product_form_screen.dart#L567), [`_validateStock`](../../lib/features/admin/admin_product_form_screen.dart#L590); DB cũng có `CHECK (price > 0)`, `CHECK (stock >= 0)` |
| Chọn ảnh từ asset | [`ProductImagePickerSheet`](../../lib/features/admin/widgets/product_image_picker_sheet.dart#L14) |
| Thông số vợt chỉ hiện khi là vợt | `if (isRacket)` trong [`_buildForm`](../../lib/features/admin/admin_product_form_screen.dart#L185) |
| Cảnh báo rời màn khi chưa lưu | `PopScope` trong [`build`](../../lib/features/admin/admin_product_form_screen.dart#L151) + [`_confirmDiscard`](../../lib/features/admin/admin_product_form_screen.dart#L701) |

## 2. Sơ đồ luồng

```text
AdminProductsScreen (S14)            AdminDashboardScreen (S13)
  FAB "Thêm sản phẩm" → id = null      menu "Thêm sản phẩm" → id = null
  tap hàng / menu Sửa  → id = 5        tap "Sắp hết hàng"   → id = 3
              │                                   │
              └──── Navigator.pushNamed(AppRoutes.adminProductForm, arguments: id)
                                  │
                    AppRoutes.screen()  →  AdminGuard (chỉ ADMIN)
                                  │
            ChangeNotifierProvider(AdminProductFormProvider(repo, productId: id))
                                  │
                       AdminProductFormScreen (S15)
     initState → load():  getCategories() [+ getProductDetail(id) nếu sửa]
                                  │
              admin nhập → bấm Lưu → _onSave():
                 1. validate (ảnh + mọi ô trong Form)
                 2. gom thành Product (+ RacketSpec nếu là vợt)
                 3. provider.save()
                                  │
                    ProductRepository.addProduct / updateProduct
                        db.transaction((txn) {
                          ProductDao.insertProduct / updateProduct   → bảng products
                          ProductDao.upsertRacketSpec / deleteRacketSpec → racket_specs
                        })
                                  │
                 4. SnackBar "Đã lưu sản phẩm" → Navigator.pop(true)
                                  │
       S14 / S13 nhận lại quyền điều khiển → refresh() → danh sách / số liệu mới
       Khách mở Shop → ShopProvider.loadInitial() → ProductDao.search (is_active = 1)
```

Mỗi lớp chỉ gọi lớp ngay dưới nó: **Screen → Provider → Repository → DAO → SQLite**. Màn hình không import `sqflite` và không viết SQL.

## 3. File đã tạo / sửa

### 3.1. File tạo mới

| File | Làm gì |
| --- | --- |
| [lib/features/admin/admin_product_form_screen.dart](../../lib/features/admin/admin_product_form_screen.dart#L48) | Màn S15: Form với 5 nhóm (Ảnh, Thông tin chung, Giá & kho, Thông số vợt, Cài đặt hiển thị), nút Lưu cố định ở đáy, validate, hỏi lại khi rời màn |
| [lib/providers/admin_product_form_provider.dart](../../lib/providers/admin_product_form_provider.dart#L13) | State của S15: `status`, `categories`, `product`, `racketSpec`, `isSaving`; hàm `load()` và `save()` |
| [lib/features/admin/widgets/product_image_picker_sheet.dart](../../lib/features/admin/widgets/product_image_picker_sheet.dart#L14) | Bottom sheet hiện lưới ảnh có sẵn, chia nhóm theo thư mục; bấm ảnh thì trả về đường dẫn |
| [lib/features/admin/product_image_assets.dart](../../lib/features/admin/product_image_assets.dart) | Danh sách cố định 22 đường dẫn ảnh trong `assets/images/products/` |
| [lib/features/admin/admin_category_label.dart](../../lib/features/admin/admin_category_label.dart#L2) | `adminCategoryLabel()`: đổi tên danh mục trong DB (`Rackets`) sang tiếng Việt (`Vợt`). Tách ra từ S14 để S15 dùng chung |
| [test/providers/admin_product_form_provider_test.dart](../../test/providers/admin_product_form_provider_test.dart) | 7 test Provider trên SQLite thật (ffi) |
| [test/features/admin/admin_product_form_screen_test.dart](../../test/features/admin/admin_product_form_screen_test.dart) | 6 widget test cho màn hình |

### 3.2. File sửa

| File | Sửa gì | Vì sao |
| --- | --- | --- |
| [lib/routes/app_routes.dart](../../lib/routes/app_routes.dart#L211) | Thay **đúng dòng placeholder** `adminProductForm` bằng `ChangeNotifierProvider<AdminProductFormProvider>` + `AdminProductFormScreen`, thêm 2 import | Nối route vào màn thật. File của **Lượng**, nhưng comment trong file cho phép chủ màn thay dòng placeholder của mình |
| [test/routes/app_routes_test.dart](../../test/routes/app_routes_test.dart#L72) | Bỏ `AppRoutes.adminProductForm: 1` khỏi map `pushedRoutes` | Test cũ mong route này là `PlaceholderScreen`; S13 và S14 cũng đã bỏ dòng của mình theo cách này. File của **Lượng**, cần báo Lượng |
| [lib/features/admin/admin_products_screen.dart](../../lib/features/admin/admin_products_screen.dart#L16) | Xoá hàm private `_categoryLabel` ở cuối file, import `admin_category_label.dart`, gọi `adminCategoryLabel(...)` | Để S14 và S15 dùng chung một hàm, không phải copy code |
| [docs/admin-guide/SML-084-UC17-admin-products.md](SML-084-UC17-admin-products.md) | Cập nhật các link số dòng bị lệch +1 | Do thêm 1 dòng import ở S14 |

**Không sửa:** `ProductDao` và `ProductRepository`. Các hàm `addProduct` / `updateProduct` (ghi kèm `racket_specs` trong transaction) đã được viết ở task 01 ([01-product-write.md](01-product-write.md)), UC18 chỉ gọi lại. Màn Shop cũng không cần sửa gì.

### 3.3. Ai gọi ai

| Hàm | Làm gì | Gọi tới |
| --- | --- | --- |
| [`AdminProductFormProvider.load`](../../lib/providers/admin_product_form_provider.dart#L53) | Tải danh mục; nếu sửa thì tải thêm sản phẩm + spec. Không tìm thấy id thì vào trạng thái lỗi | `getCategories`, `getProductDetail` |
| [`AdminProductFormProvider.save`](../../lib/providers/admin_product_form_provider.dart#L91) | Khoá chống bấm 2 lần, gọi thêm hoặc sửa, trả `true` khi đã lưu | [`addProduct`](../../lib/data/repositories/product_repository.dart#L87) / [`updateProduct`](../../lib/data/repositories/product_repository.dart#L110) |
| [`AdminProductFormProvider.isRacketCategory`](../../lib/providers/admin_product_form_provider.dart#L43) | Trả `true` nếu id danh mục là `Rackets` | — |
| [`ProductRepository.addProduct`](../../lib/data/repositories/product_repository.dart#L87) | Mở `db.transaction`, INSERT `products`, có spec thì INSERT `racket_specs` với id mới | [`insertProduct`](../../lib/data/daos/product_dao.dart#L134), [`upsertRacketSpec`](../../lib/data/daos/product_dao.dart#L148) |
| [`ProductRepository.updateProduct`](../../lib/data/repositories/product_repository.dart#L110) | Mở transaction, UPDATE `products`; có spec thì ghi đè, không có thì xoá spec cũ | [`updateProduct`](../../lib/data/daos/product_dao.dart#L139), [`upsertRacketSpec`](../../lib/data/daos/product_dao.dart#L148), [`deleteRacketSpec`](../../lib/data/daos/product_dao.dart#L160) |

### 3.4. Vì sao Shop của khách thấy ngay sản phẩm mới

- Khi thêm mới, form đặt `isActive: old?.isActive ?? true` (thêm mới thì `old` là null, nên giá trị là `true`). Nhờ vậy dòng mới có `is_active = 1`.
- Màn Shop không giữ bản sao dữ liệu. Mỗi khi mở Shop, route `shop` ([app_routes.dart#L136](../../lib/routes/app_routes.dart#L136)) tạo `ShopProvider` mới và gọi [`loadInitial`](../../lib/providers/shop_provider.dart#L53). Hàm này chạy [`ProductDao.search`](../../lib/data/daos/product_dao.dart#L204) với điều kiện `p.is_active = 1`, nên đọc thẳng từ SQLite và thấy dòng vừa INSERT.
- Admin và khách là hai tài khoản khác nhau. Khi khách đăng nhập, Login gọi `pushNamedAndRemoveUntil`, tạo AppShell mới nên Shop luôn được tải lại.
- Test [`thêm vợt mới: ghi products + racket_specs và hiện ở Shop`](../../test/providers/admin_product_form_provider_test.dart) chứng minh điều này: sau `save()`, `repository.searchProducts(const ProductQuery())` (đúng hàm Shop gọi) có chứa id mới.

## 4. Giải thích các phần chính của màn hình

### 4.1. Một màn cho cả Thêm và Sửa

Route đọc `arguments`: nếu là `int` thì đó là id cần sửa, còn lại là `null`, tức là thêm mới.

```dart
// lib/routes/app_routes.dart
adminProductForm => ChangeNotifierProvider<AdminProductFormProvider>(
  create: (_) => AdminProductFormProvider(
    ProductRepository(
      database: () => DatabaseHelper.instance.database,
      productDao: const ProductDao(),
    ),
    productId: arguments is int ? arguments : null,
  ),
  child: const AdminProductFormScreen(),
),
```

Màn hình chỉ hỏi `form.isEditing` để đổi tiêu đề ("Thêm sản phẩm" hoặc "Sửa sản phẩm") và chữ trên nút. Dữ liệu cũ được điền vào các ô trong [`_fillForm`](../../lib/features/admin/admin_product_form_screen.dart#L115).

Màn tải dữ liệu trong `initState`, nhưng **đợi khung hình đầu tiên vẽ xong** rồi mới gọi:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
}
```

Lý do: `load()` gọi `notifyListeners()` ngay. Nếu gọi khi cây widget đang build, Flutter sẽ báo lỗi *"setState() or markNeedsBuild() called during build"*.

### 4.2. Chọn ảnh từ asset có sẵn

Ảnh được đóng gói cùng app. **DB chỉ lưu chuỗi đường dẫn** (ví dụ `assets/images/products/shoes/shoe_yonex_65z3.png`) và UI hiển thị bằng `Image.asset(path)`, đúng như blueprint mục 18. Danh sách ảnh là một `const Map` trong [product_image_assets.dart](../../lib/features/admin/product_image_assets.dart):

```dart
static const Map<String, List<String>> groups = {
  'Vợt': ['$_root/rackets/racket_yonex_astrox99pro.png', ...],
  'Giày': ['$_root/shoes/shoe_yonex_65z3.png', ...],
  ...
};
```

Khi bấm vào khung ảnh, [`_pickImage`](../../lib/features/admin/admin_product_form_screen.dart#L302) mở bottom sheet rồi **chờ** (`await`) đường dẫn trả về:

```dart
Future<void> _pickImage() async {
  final path = await ProductImagePickerSheet.show(context, selected: _imagePath);
  if (!mounted || path == null || path == _imagePath) return;
  setState(() {
    _imagePath = path;
    _imageError = null;
    _hasChanges = true;
  });
}
```

Trong sheet, bấm một ảnh sẽ gọi `Navigator.of(context).pop(path)`. Giá trị `path` truyền vào `pop` chính là giá trị mà `showModalBottomSheet<String>` trả về.

### 4.3. Nhóm thông số vợt chỉ hiện khi là vợt

Khi admin đổi danh mục, `onChanged` của dropdown gọi `setState`, nên `build` chạy lại:

```dart
// _buildForm
final isRacket = form.isRacketCategory(_categoryId);
...
if (isRacket) ...[
  const SizedBox(height: AppSpacing.lg),
  _buildRacketSpecs(),
],
```

- Mỗi thông số (trọng lượng, cân bằng, độ cứng đũa, trình độ, lối chơi) là một hàng `ChoiceChip`, được dựng bằng hàm chung [`_buildSpecChoice`](../../lib/features/admin/admin_product_form_screen.dart#L482). Giá trị lưu DB như `HEAD_HEAVY` được ánh xạ sang chữ hiển thị "Nặng đầu" qua các map `_balanceOptions`, … ở đầu file. Các giá trị này khớp với `CHECK` của bảng `racket_specs`.
- Sức căng tối đa là ô số, giới hạn 15–40 lbs.
- **Khi lưu:** nếu là vợt thì tạo `RacketSpec`, nếu không thì truyền `null`. Repository sẽ xoá spec cũ khi nhận `null`. Vì vậy sửa một cây vợt rồi chuyển sang "Giày" thì spec cũ bị xoá, và form hiện dòng nhắc màu cam: *"Sản phẩm không còn là vợt: thông số vợt cũ sẽ bị xóa khi lưu."*
- Khi nhóm vợt bị ẩn, ô sức căng không còn trong cây widget, nên `validate()` không kiểm tra ô này. Giày không bị bắt nhập sức căng.

### 4.4. Validate dữ liệu

- Mỗi ô có một `validator`. Hàm này trả `null` khi hợp lệ, hoặc trả câu báo lỗi. Bấm Lưu thì gọi `_formKey.currentState!.validate()` để kiểm tra mọi ô cùng lúc.
- Ảnh không phải ô nhập chữ nên được kiểm tra riêng bằng biến `_imageError`.
- Form dùng `SingleChildScrollView + Column` chứ **không dùng `ListView`**. `ListView` chỉ dựng các ô đang hiện trên màn, nên ô nằm ngoài màn sẽ không được `validate()` kiểm tra.
- Ô số dùng `FilteringTextInputFormatter.digitsOnly` nên không gõ được dấu `-` hay chữ, và `LengthLimitingTextInputFormatter` để số không quá lớn.

```dart
/// Giá bán bắt buộc và phải > 0.
String? _validatePrice(String? value) {
  final price = int.tryParse((value ?? '').trim());
  if (price == null) return 'Vui lòng nhập giá bán';
  if (price <= 0) return 'Giá bán phải lớn hơn 0';
  return null;
}
```

### 4.5. Cảnh báo khi rời màn chưa lưu

Biến `_hasChanges` bật lên `true` trong các trường hợp sau:
- Gõ vào bất kỳ ô nào hoặc đổi dropdown: `Form(onChanged: _markChanged)` tự bắt.
- Chọn ảnh, bấm chip thông số, gạt switch Nổi bật: các widget này không nằm trong Form nên phải đặt `_hasChanges = true` trong `setState` của chúng.
- Sau khi `_fillForm` điền dữ liệu cũ, biến được đặt lại `false`, vì dữ liệu gốc không tính là thay đổi.

```dart
return PopScope<Object?>(
  // Có thay đổi chưa lưu → chặn nút Back, hỏi lại trước khi rời màn.
  canPop: !_hasChanges,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) _confirmDiscard();
  },
  child: Scaffold(...),
);
```

- `canPop: false` chặn cả nút Back trên AppBar lẫn nút/cử chỉ Back của hệ thống, rồi gọi `onPopInvokedWithResult` với `didPop = false`. Lúc đó màn hiện dialog "Bỏ thay đổi?" với hai nút "Ở lại" và "Bỏ thay đổi".
- Nếu chọn "Bỏ thay đổi", màn gọi `Navigator.of(context).pop()`. `Navigator.pop` **không bị `PopScope` chặn** (`PopScope` chỉ chặn `maybePop` và nút Back của hệ thống), nên màn đóng được. Khi lưu thành công, màn cũng thoát bằng `navigator.pop(true)` nên không bị hỏi lại.

### 4.6. Lưu — [`_onSave`](../../lib/features/admin/admin_product_form_screen.dart#L607)

1. Validate ảnh và cả Form. Có lỗi thì hiện SnackBar "Vui lòng kiểm tra lại các ô báo lỗi." và dừng.
2. [`_buildProduct`](../../lib/features/admin/admin_product_form_screen.dart#L650) gom dữ liệu thành `Product`. Rating và trạng thái bán **không có ô trên form**: thêm mới thì rating = 0 và đang bán; sửa thì giữ nguyên giá trị cũ (`old?.rating ?? 0`). Sizes được chuẩn hoá: `" 40, 41,,42 "` thành `"40,41,42"`, để trống thì là `null`.
3. `await form.save(product, spec)`. Trong lúc lưu, nút hiện spinner (`isLoading`) và provider trả `false` nếu bị gọi lần 2.
4. Thành công thì hiện SnackBar "Đã lưu sản phẩm" rồi `pop(true)`. Lỗi thì hiện câu báo lỗi của `AppException` và **ở lại form**, dữ liệu vẫn còn.

`messenger` và `navigator` được lấy **trước** `await`, vì sau `await` có thể `context` không còn hợp lệ. Màn cũng kiểm tra `mounted` trước khi dùng.

## 5. Quy tắc validate

| Ô | Bắt buộc | Quy tắc | Câu báo lỗi |
| --- | --- | --- | --- |
| Ảnh | Có | Phải chọn 1 ảnh | Vui lòng chọn ảnh sản phẩm |
| Tên sản phẩm | Có | Không được trống (đã trim) | Vui lòng nhập tên sản phẩm |
| Thương hiệu | Có | Không được trống | Vui lòng nhập thương hiệu |
| Danh mục | Có | Phải chọn | Vui lòng chọn danh mục |
| Giá bán | Có | Số nguyên **> 0** | Vui lòng nhập giá bán / Giá bán phải lớn hơn 0 |
| Giá gốc | Không | Nếu nhập thì **> giá bán** | Giá gốc phải lớn hơn giá bán |
| Tồn kho | Có | Số nguyên **≥ 0** (0 = hết hàng, vẫn hợp lệ) | Vui lòng nhập tồn kho / Tồn kho không được âm |
| Mô tả, Sizes | Không | Sizes cách nhau bằng dấu phẩy | — |
| Sức căng tối đa (chỉ vợt) | Có | 15–40 lbs | Vui lòng nhập sức căng tối đa / Sức căng phải từ 15 đến 40 lbs |
| Các chip thông số vợt | Luôn có giá trị | Mặc định 4U · Cân bằng · Trung bình · Trung bình · Toàn diện | — |

**Hai lớp bảo vệ:** form chặn trước ở UI, còn SQLite có `CHECK (price > 0)`, `CHECK (stock >= 0)`, `CHECK (rating BETWEEN 0 AND 5)` và `CHECK` cho giá trị spec. Nếu dữ liệu sai lọt qua UI, SQLite từ chối, Repository chuyển lỗi thành `AppException`, và transaction rollback nên không ghi nửa chừng.

## 6. Các trường hợp lỗi đã xử lý

| Tình huống | Cách xử lý |
| --- | --- |
| Tải danh mục / sản phẩm lỗi | `ErrorState` kèm nút Thử lại (gọi lại `_loadData`) |
| Mở sửa một id đã bị xoá | Trạng thái lỗi: "Không tìm thấy sản phẩm cần sửa. Có thể sản phẩm đã bị xóa." |
| Bấm Lưu 2 lần liên tiếp | Nút có `isLoading` + màn kiểm tra `form.isSaving` + provider trả `false` |
| Lỗi DB giữa transaction (ví dụ spec sai) | Rollback cả `products`, SnackBar báo lỗi, ở lại form |
| Đang lưu mà bấm Back | `_confirmDiscard` bỏ qua khi `isSaving` |
| Thoát màn khi đang `await` | Kiểm tra `mounted` sau mỗi `await`; provider có cờ `_disposed` |
| Sản phẩm bị xoá trong lúc đang sửa | `updateProduct` trả 0 dòng, nên báo "Không tìm thấy sản phẩm cần sửa." |

## 7. Cách test

### 7.1. Test tự động

```bash
flutter analyze
flutter test test/providers/admin_product_form_provider_test.dart test/features/admin/admin_product_form_screen_test.dart test/routes/app_routes_test.dart
```

| Test | Chứng minh |
| --- | --- |
| Provider: thêm mới tải danh mục | `isEditing = false`, `isRacketCategory` đúng cho Rackets / Shoes / null |
| Provider: thêm vợt mới | Ghi cả `products` + `racket_specs`, **`searchProducts` (Shop) thấy ngay** |
| Provider: sửa tải sẵn dữ liệu | `product` và `racketSpec` của id 1 được tải |
| Provider: vợt chuyển sang Giày | `racket_specs` cũ bị xoá |
| Provider: id không tồn tại | Trạng thái `error` kèm thông báo |
| Provider: giá = 0 | SQLite từ chối thật, ném `AppException`, không ghi dòng nào |
| Provider: spec sai | Transaction huỷ luôn dòng `products` |
| Screen: Lưu khi trống | Hiện đủ 6 lỗi |
| Screen: giá 0, giá gốc ≤ giá bán | Hiện đúng câu lỗi |
| Screen: sửa vợt rồi đổi sang Giày | Nhóm "Thông số vợt" biến mất, hiện dòng nhắc |
| Screen: có thay đổi rồi Back | Dialog hiện; "Ở lại" giữ màn, "Bỏ thay đổi" thì rời màn |
| Screen: chưa sửa gì rồi Back | Rời màn ngay, không hỏi |
| Screen: thêm giày hợp lệ | Chọn ảnh trong sheet, lưu, SnackBar, `pop(true)`, DB có dòng với sizes đã chuẩn hoá |

### 7.2. Test thủ công (đăng nhập `admin@smashly.com` / `Admin@123`)

**A. Thêm mới**
1. Dashboard → "Quản lý sản phẩm" → bấm FAB "Thêm sản phẩm". Tiêu đề là "Thêm sản phẩm", các ô trống.
2. Chạm vào khung ảnh, chọn một ảnh vợt. Ảnh hiện trong khung.
3. Nhập Tên "Vợt Demo UC18", Thương hiệu "Yonex", Danh mục **Vợt**. Nhóm "Thông số vợt" xuất hiện.
4. Giá 2500000, Tồn kho 7, Sức căng 28, chọn vài chip → bấm "Thêm sản phẩm".
5. Kết quả mong đợi: SnackBar "Đã lưu sản phẩm", quay về S14 và sản phẩm mới nằm **đầu danh sách** (sắp xếp `id DESC`).
6. Đăng xuất, đăng nhập `customer@smashly.com` / `Customer@123`, mở tab Shop, tìm "Demo UC18". Sản phẩm hiện ra. Mở chi tiết thì thấy đủ thông số vợt.

**B. Sửa**
1. Ở S14, tap "Yonex Astrox 99 Pro". Tiêu đề là "Sửa sản phẩm", các ô đã điền sẵn và nhóm thông số vợt có giá trị cũ.
2. Đổi tồn kho thành 20 → "Lưu thay đổi". Hàng ở S14 hiện tồn kho 20.
3. Sửa lại, đổi danh mục sang **Giày**. Nhóm vợt biến mất và hiện dòng nhắc màu cam. Bấm Back rồi chọn "Bỏ thay đổi" để không lưu.

**C. Nhập sai**
1. Thêm mới, bấm Lưu ngay. Viền đỏ ở khung ảnh và lỗi dưới 5 ô bắt buộc.
2. Giá bán `0`: "Giá bán phải lớn hơn 0".
3. Giá bán 1000000, Giá gốc 900000: "Giá gốc phải lớn hơn giá bán".
4. Chọn Vợt, sức căng `50`: "Sức căng phải từ 15 đến 40 lbs".
5. Thử gõ `-5` vào Tồn kho: bàn phím số không cho gõ dấu `-`. Nhập `0` thì hợp lệ (hết hàng).

**D. Rời màn khi chưa lưu**
1. Mở sửa một sản phẩm, không đổi gì, bấm Back. Rời màn ngay.
2. Mở lại, gõ thêm một chữ vào tên, bấm Back. Dialog "Bỏ thay đổi?" hiện ra. Bấm "Ở lại" thì vẫn ở form và chữ vừa gõ còn nguyên.
3. Bấm Back lần nữa, chọn "Bỏ thay đổi". Quay về S14 và dữ liệu không đổi.
4. Thử bằng cử chỉ vuốt Back của Android. Hành vi giống hệt.

## 8. Câu hỏi vấn đáp có thể gặp

1. **Vì sao Thêm và Sửa dùng chung một màn?**
   Hai màn riêng sẽ trùng khoảng 90% code (blueprint mục 5). Màn nhận `productId`: `null` là thêm, có id là sửa. Chỉ khác tiêu đề, dữ liệu điền sẵn, và lúc lưu thì gọi `addProduct` hay `updateProduct`.

2. **Lưu sản phẩm và thông số vợt, sao phải dùng transaction?**
   Đây là hai bảng phải đúng cùng lúc. Nếu INSERT `products` thành công mà `racket_specs` lỗi, ta sẽ có một cây vợt không có thông số. Trong `db.transaction`, chỉ cần một lệnh lỗi là SQLite rollback toàn bộ. Test "spec sai" chứng minh dòng `products` cũng không được ghi.

3. **Ảnh lưu thế nào? Sao không cho upload?**
   Ảnh là asset đóng gói trong app, DB chỉ lưu chuỗi đường dẫn và UI vẽ bằng `Image.asset`. App offline, không có server, nên lưu ảnh dạng BLOB sẽ làm DB nặng. Danh sách ảnh là `const` cho dễ hiểu; thêm ảnh mới thì thêm 1 dòng.

4. **Làm sao biết người dùng có thay đổi chưa lưu?**
   Cờ `_hasChanges`: `Form(onChanged:)` bắt mọi ô nhập, còn chip/switch/ảnh thì tự đặt cờ. `PopScope(canPop: !_hasChanges)` chặn Back và hiện dialog. Lưu xong thì dùng `Navigator.pop`, vốn không bị `PopScope` chặn.

5. **Validate ở UI rồi, DB có cần `CHECK` nữa không?**
   Có. UI chỉ là lớp đầu tiên, còn `CHECK` là lớp cuối cùng bảo vệ dữ liệu, kể cả khi sau này có code khác ghi vào DB. Test "giá = 0" bỏ qua UI, gọi thẳng Provider, và SQLite vẫn từ chối.

6. **Sau khi thêm, vì sao Shop thấy ngay mà không cần code "thông báo"?**
   Shop không cache dữ liệu. Mỗi lần mở, `ShopProvider.loadInitial()` truy vấn lại SQLite với `is_active = 1`. Sản phẩm mới có `is_active = 1` nên xuất hiện. Còn S14/S13 thì `await pushNamed(...)` rồi gọi `refresh()` khi form đóng.

7. **Nếu bấm Lưu hai lần thật nhanh thì sao?**
   Có ba lớp chặn: nút ở trạng thái `isLoading` không nhận chạm, `_onSave` kiểm tra `form.isSaving`, và `save()` trả `false` nếu đang lưu dở.

## 9. Lưu ý / việc còn lại

- **Báo Lượng:** em đã sửa `lib/routes/app_routes.dart` (chỉ thay dòng placeholder `adminProductForm` + 2 import) và `test/routes/app_routes_test.dart` (map `pushedRoutes` nay rỗng). Map rỗng nhưng vòng lặp vẫn giữ để sau này dùng lại.
- **Chưa làm (theo blueprint):**
  - Brand chưa có dropdown gợi ý, đang là ô nhập chữ (đã chốt cho đơn giản).
  - Chưa có ô Rating (đã chốt: không cho admin sửa).
  - Chưa có switch ẩn/hiện trong form; ẩn/hiện vẫn làm ở S14.
  - Chưa có hiệu ứng "hàng vừa sửa nháy nền 1 lần" ở S14, vì phải sửa S14.
- **Danh sách ảnh là cố định:** thêm file ảnh mới vào `assets/images/products/...` thì phải thêm dòng vào `product_image_assets.dart`, nếu không ảnh sẽ không hiện trong lưới chọn.
- **Chưa chạy trên emulator/điện thoại:** đã kiểm tra bằng `flutter analyze` (0 issue) và `flutter test` (toàn bộ 359 test pass), nhưng nên chạy tay theo mục 7.2 trước khi demo.
