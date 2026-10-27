# Cập nhật Theme, Widget chung & Routes — Lượng (07/10)

Đã làm xong 4 thứ Hào cần ở mục 5 file `2026-10-06-auth-database.md`: theme, widget chung, routes + AppShell, logo. Từ giờ không cần dùng widget Material tạm hay đánh dấu `TODO(theme)` / `TODO(routes)` nữa.

## 1. Pull code về cần làm gì

```bash
git checkout develop
git pull origin develop
flutter pub get
```

- Chạy lại app bằng **stop rồi `flutter run`** (không hot reload), vì có font và asset mới.
- **Không cần xóa DB**: schema không đổi, vẫn `DB_VERSION = 3`.
- App mở lên giờ là **menu dev**, không còn màn kiểm tra SQLite. Từ menu này mở được mọi màn, kể cả "Kiểm tra SQLite".

## 2. Đã làm

| Phần             | File chính                                                                                       | Ghi chú                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------- |
| Theme            | `lib/core/theme/` (`app_colors`, `app_text_styles`, `app_spacing`, `app_motion`, `app_theme`)    | Token theo mục 21–22 blueprint; `MaterialApp` đã dùng `AppTheme.light` |
| Font             | `assets/fonts/` + khai báo `fonts:` trong `pubspec.yaml`                                         | Plus Jakarta Sans (tiêu đề, giá, nút), Inter (nội dung); đóng gói sẵn, không cần mạng |
| Nút              | `shared/widgets/buttons/` (`PrimaryButton`, `SecondaryButton`, `PressableScale`)                 | `PrimaryButton` có `isLoading`, co 0.97 khi nhấn               |
| Ô nhập           | `shared/widgets/inputs/app_text_field.dart`                                                      | Validate khi rời ô, ẩn/hiện mật khẩu, lỗi từ server, check xanh |
| 3 trạng thái     | `shared/widgets/states/` (`LoadingState`, `EmptyState`, `ErrorState`)                            |                                                                 |
| Logo             | `shared/widgets/app_logo.dart` + `assets/images/brand/`                                          | Dùng widget `AppLogo`; PNG chỉ để làm slide, README             |
| Routes           | `lib/routes/app_routes.dart`                                                                     | Đủ 15 màn, màn chưa làm hiện `PlaceholderScreen`               |
| Chuyển màn       | `lib/routes/app_page_route.dart`                                                                 | Fade + trượt 8%, 320 ms, tự tắt khi máy bật giảm chuyển động   |
| Bottom nav       | `lib/features/shell/` (`AppShell`, `AppTab`)                                                     | 5 tab, giữ trạng thái từng tab, badge giỏ hàng                  |
| Test             | `test/core/theme/`, `test/shared/`, `test/routes/`                                               | `flutter test`: 77 test pass                                    |

## 3. Quy ước dùng chung

**Màu, chữ, khoảng cách** — không viết `Color(0xFF...)`, `fontSize: 17`, `EdgeInsets.all(13)` trong màn hình:

```dart
Text('Giỏ hàng', style: AppTextStyles.h1);
Text(brand, style: AppTextStyles.caption);                         // đã sẵn màu inkMuted
Text(desc, style: AppTextStyles.body.copyWith(color: AppColors.inkMuted));
Text('2.890.000₫', style: AppTextStyles.price);                    // priceSmall 16 · price 20 · priceLarge 24
Padding(padding: AppSpacing.screenPadding, ...);                    // lề màn 16
const SizedBox(height: AppSpacing.section);                         // giữa các section 24
Container(decoration: BoxDecoration(borderRadius: AppRadius.lgAll, boxShadow: AppShadows.card));
Container(decoration: const BoxDecoration(gradient: AppColors.darkGradient)); // hero, header tối
```

- Widget Material mặc định đã mang sẵn style: `FilledButton`, `TextButton`, `Card`, `Chip`, `Checkbox`, `SnackBar`, `TabBar`, bottom sheet, dialog… nên không cần set màu nữa.
- Animation lấy thời lượng qua `AppMotion.of(context, AppMotion.fast)`. Có 4 mức: `fast` 150 · `normal` 250 · `page` 320 · `emphasis` 600.
- Cần thêm màu hay cỡ chữ mới → nhắn Lượng, đừng tự thêm vào màn hình của mình.

**Widget chung**

```dart
PrimaryButton(label: 'Đăng nhập', isLoading: auth.isLoading, onPressed: valid ? _submit : null);
SecondaryButton(label: 'Tiếp tục mua sắm', onPressed: ...);

AppTextField(
  label: 'Email',
  controller: _email,
  validator: validateEmail,                 // từ core/utils/validators.dart
  errorText: auth.fieldErrors['email'],      // lỗi từ Repository
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
  prefixIcon: Icons.mail_outline,
  showValidCheck: true,                      // check xanh (Register)
);
AppTextField(label: 'Mật khẩu', isPassword: true, ...);

AppLogo(size: 40, onDark: true);             // trên nền tối
```

**Màn hình switch theo `ViewStatus`** (mẫu cho mọi màn có dữ liệu):

```dart
switch (provider.status) {
  ViewStatus.initial || ViewStatus.loading => const LoadingState(),
  ViewStatus.error => ErrorState(message: provider.errorMessage, onRetry: provider.load),
  ViewStatus.empty => EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Chưa có đơn hàng',
      actionLabel: 'Mua sắm ngay',
      onAction: () => AppShell.goToTab(context, AppTab.shop),
    ),
  ViewStatus.success => _Content(...),
}
```

Màn có lưới hoặc danh sách lớn (Home, Shop, Orders) nên làm skeleton thay cho `LoadingState`.

**Điều hướng** — luôn dùng hằng số `AppRoutes`, không gõ chuỗi:

```dart
Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id);   // int
Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: order.id);       // int
Navigator.pushReplacementNamed(context, AppRoutes.orderSuccess, arguments: orderId);
Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);       // vào app customer
Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (_) => false);
AppShell.goToTab(context, AppTab.cart);   // đổi tab từ bất kỳ đâu, tự đóng màn đang đè lên
```

- 5 tab Home · Shop · Cart · Orders · Profile nằm trong `AppShell`. Mở route của tab (vd. `AppRoutes.cart`) = mở AppShell ở đúng tab đó.
- **Làm xong màn của mình → chỉ sửa đúng dòng placeholder của mình** trong `AppRoutes.screen()` (`lib/routes/app_routes.dart`), không thêm hay xóa route khác. Ví dụ:

  ```dart
  // trước
  productDetail => const PlaceholderScreen(code: 'S06', title: 'Chi tiết sản phẩm', owner: 'Lượng'),
  // sau
  productDetail => ProductDetailScreen(productId: arguments! as int),
  ```

- Cần route mới hoặc đổi kiểu arguments → nhắn Lượng.

## 4. Việc từng người

**Hào**

- Review khai báo `fonts:` trong `pubspec.yaml` (file của Hào). Mình chỉ thêm đúng khối này.
- `app.dart` chỉ đổi 2 chỗ có `TODO(TV3)`: `theme: AppTheme.light` và `initialRoute` + `onGenerateRoute`.
- Thay các dòng `splash`, `login`, `register`, `profile` trong `AppRoutes.screen()` bằng màn thật. Dòng `splash` hiện là `DevMenuScreen`; sau khi thay, menu dev vẫn mở được qua `AppRoutes.devMenu`. Nếu tiện thì thêm một mục "Menu dev" ở Profile bản debug.
- Màn Profile dùng chung cho `profile` (tab customer) và `adminProfile` (admin mở từ menu avatar).
- Splash, header Login: nền `AppColors.darkGradient` + `AppLogo(onDark: true)`.

**Kha**

- Thay dòng `home`, `shop`. Home và Shop là tab, nên màn không cần nút Back.
- Home → Shop với filter điền sẵn: set `ProductQuery` vào `ShopProvider` rồi `AppShell.goToTab(context, AppTab.shop)`.
- `ProductCard`, `CategoryCard` đặt trong `shared/widgets/`, dùng `PressableScale` để có hiệu ứng nhấn giống nút.

**Danh**

- Thay dòng `cart`, `checkout`, `orderSuccess`.
- Badge giỏ: trong `features/shell/app_shell.dart` có `TODO(Danh)` (`const cartCount = 0`). Khi có `CartProvider`, bạn sửa đúng dòng đó thành `context.watch<CartProvider>().totalQuantity`, hoặc nhắn Lượng sửa.
- Checkout → Order Success dùng `pushReplacementNamed` để Back không quay lại Checkout. Nút "Tiếp tục mua sắm" → `AppShell.goToTab(context, AppTab.home)`.

**Trọng**

- Thay dòng `adminDashboard`, `adminProducts`, `adminProductForm`. Product Form nhận `int? productId`: `null` = thêm mới, có id = sửa.
- Header admin dùng `AppColors.midnight` + `AppLogo(onDark: true)`; menu avatar → `AppRoutes.adminProfile`.

**Cả nhóm**

- Đọc mục 3 trước khi viết màn đầu tiên.
- Ảnh empty state (`empty_cart.png`…) bỏ vào `assets/images/states/` rồi truyền `imagePath:` vào `EmptyState`. Chưa có ảnh thì widget tự dùng icon.

## 5. Lượng làm tiếp

- Widget chung còn lại: `AppDialog` (xác nhận / nguy hiểm), `StatusBadge` / `StockBadge` / `PromoBadge`, `PriceText`, `RatingView`, `QuantityStepper`.
- Widget Catalog (màn debug xem mọi component), gắn vào menu dev.
- Bottom nav kính mờ (glass) theo mục 8 blueprint.
- Màn Product Detail, My Orders, Order Detail.

Widget nào thấy thiếu, khó dùng hoặc tên chưa hợp lý thì nhắn lên nhóm.
