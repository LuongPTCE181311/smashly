- Filter bottom sheet: brand, giá, rating, thông số vợt; Reset + Apply có đếm kết quả

- Recent searches (SharedPreferences)

- (SHOULD) Wishlist: nút tim + danh sách yêu thích

## Lượng — Nhóm trưởng · UI kit · Product Detail & Orders

- Tạo repo, nhánh main / develop , mời thành viên

- Khung thư mục, pubspec.yaml , SQLite (schema, DatabaseHelper , seed, session, hash mật khẩu) — bàn giao cho Hào

- Tuần 1, ưu tiên số 1: core/theme/ — màu, chữ, spacing, motion, AppTheme

- Widget dùng chung: nút, ô nhập, EmptyState , LoadingState , ErrorState , dialog, badge, PriceText , RatingView

- app_routes.dart với đủ 15 route (placeholder trước), AppShell bottom nav 5 tab, hiệu ứng chuyển trang

- Widget Catalog (màn debug xem tất cả component)

- Màn Product Detail: Hero ảnh, SpecCard / SpecMeter giải thích thông số vợt, chọn size, thêm vào giỏ

- Màn My Orders: tab theo trạng thái, OrderCard

- Màn Order Detail: timeline trạng thái, thông tin giao hàng, danh sách món

- Nhóm trưởng: mỗi Chủ nhật merge develop → main khi app chạy ổn, gắn tag

- (SHOULD) Khách hủy đơn Pending; tuần 4 rà soát UI toàn app

## Danh — Purchase · Cart & Checkout

- CartItem , Order , OrderItem model; CurrencyFormatter ( 2.890.000₫ )

- CartDao + CartRepository : thêm (cộng dồn, chặn vượt tồn kho), đổi số lượng, chọn/bỏ chọn, xóa

- CartProvider + badge giỏ hàng có animation

- trừ kho, xóa món khỏi giỏ); hàm đọc đơn cho Lượng dùng OrderDao + OrderRepository.placeOrder() trong transaction (tạo đơn, snapshot,

- Màn Cart: chọn tất cả, stepper, vuốt xóa + Undo, thanh tổng tiền

- Màn Checkout: địa chỉ điền sẵn, 3 phương thức thanh toán mô phỏng, tóm tắt đơn, phí ship

- Màn Order Success: mã đơn, nút Xem đơn hàng

- (SHOULD) Chọn size trong giỏ/đơn; animation thêm giỏ, xóa item


| Tuần | Lượng | Kha | Hào | Danh | Trọng | Mốc |
| --- | --- | --- | --- | --- | --- | --- |
|   |   |   |   |   |   | cuối |
|   |   |   |   |   |   | tuần |
| 4 · | Rà soát UI, | Wishlist | README, | Animation | QA, đổi trạng | 31/10: |
| 26/10– | animation, | (SHOULD), | kiểm tra cài | giỏ/checkout, size | thái đơn, slide | tổng |
| 01/11 | hủy đơn; | polish Home | mới + seed | (SHOULD) |   | duyệt |
|   | tag v1.0 |   |   |   |   | demo 2 |
|   |   |   |   |   |   | lần |

## 4. Phụ thuộc và quyền sở hữu file

Ba việc chặn đường cả nhóm phải xong trong tuần 1: theme + routes (Lượng),

ProductCard + ProductDao đọc (Kha), AuthProvider (Hào). Ai cần thứ chưa có thì dùng

tạm widget/dữ liệu giả, không ngồi chờ.

| Người cần | Cần cái gì | Từ ai | Trước |
| --- | --- | --- | --- |
|   |   |   | ngày |
| Cả nhóm | Theme, nút, ô nhập, 4 widget trạng thái, 15 route Lượng 08/10 |   |   |
| Cả nhóm | AuthProvider (biết user đang đăng nhập) | Hào | 09/10 |
| Lượng, Danh, | Product model, ProductCard , ProductDao | Kha | 10/10 |
| Trọng | đọc |   |   |
| Lượng (Detail) | CartProvider.addToCart() | Danh | 15/10 |
| Lượng (Orders) | OrderDao đọc đơn theo user / theo id | Danh | 20/10 |
| Kha, Lượng | Ảnh sản phẩm thật | Trọng | 14/10 |

## Ai được sửa file nào (cần sửa file của người khác → nhắn owner):

| File / thư mục | Owner |
| --- | --- |
| core/theme/ , shared/widgets/ , routes/ , | Lượng |
| features/shell/ , features/product/ , |   |
| features/orders/ ; repo GitHub (merge develop |   |
| → main ) |   |
| features/home/ , features/shop/ , | Kha |
| product_dao.dart (phần đọc) |   |


| File / thư mục | Owner |
| --- | --- |
| pubspec.yaml , main.dart , db_schema.dart , | Hào |
| database_helper.dart , seed_users.dart , |   |
| features/auth/ , features/profile/ |   |
| features/cart/ , features/checkout/ , | Danh |
| cart_dao.dart , order_dao.dart , |   |
| seed_orders.dart |   |
| features/admin/ , seed_catalog.dart , | Trọng |
| assets/images/products/ |   |

product_dao.dart có hai người: Kha tạo file và viết hàm đọc, Trọng thêm hàm ghi ở cuối file. Pull trước khi sửa để tránh conflict.

## 5. Database Diagram

products là trung tâm: giỏ hàng, đơn hàng, wishlist và thông số vợt đều nối vào nó; còn users sở hữu giỏ, đơn và wishlist. Đọc theo chiều từ trên xuống: một user có 1 giỏ, nhiều đơn, nhiều món yêu thích.


- Giỏ hàng không lưu giá, luôn lấy giá hiện tại từ products . Giá chỉ "đóng băng" vào order_items lúc đặt hàng, nên admin sửa giá hay xóa sản phẩm không làm sai đơn cũ.

- Tiền lưu số nguyên VND ( 2890000 ), không dùng số thực; chỉ định dạng 2.890.000₫ khi hiển thị.

- Xóa sản phẩm: chưa từng có trong đơn → xóa thật; đã có → chuyển is_active = 0 (ngừng bán).

## 7. Quy tắc cấu trúc thư mục & code

Mỗi chức năng đi đúng 5 bước theo thứ tự: Model → DAO → Repository → Provider → Screen; mỗi bước nằm đúng một thư mục. Phần Auth của Hào là mẫu đầu tiên — mọi người mở ra xem và viết theo đúng kiểu đó.

## File của bạn đặt ở đâu

```
lib/
├── main.dart, app.dart # Hào
├── core/
│ ├── constants/ # app_assets.dart, app_strings.dart,
enums.dart
│ ├── theme/ # Lượng: app_colors, app_text_styles,
app_spacing, app_theme
│ ├── database/ # Hào (seed/ chia theo người)
│ ├── services/ # session_service.dart (Hào)
│ └── utils/ # currency_formatter (Danh), validators
(Hào)
├── data/
│ ├── models/ # user (Hào) · product, category,
racket_spec (Kha) · cart_item, order, order_item (Danh)
│ ├── daos/ # user_dao (Hào) · product_dao (Kha +
Trọng) · cart_dao, order_dao (Danh)
│ └── repositories/ # auth_ (Hào) · product_ (Kha + Trọng) ·
cart_, order_ (Danh)
├── providers/ # auth_ (Hào) · home_, shop_ (Kha) ·
cart_ (Danh) · order_ (Lượng) · admin_product_ (Trọng)
├── routes/app_routes.dart # Lượng
├── shared/widgets/ # Lượng (+ ProductCard, CategoryCard của
Kha)
└── features/
├── auth/ profile/ # Hào
```


| Loại | Quy tắc | Ví dụ |
| --- | --- | --- |
| Class | PascalCase , màn hình kết thúc bằng | ProductDetailScreen , |
|   | Screen | CartRepository |
| Biến, hàm | camelCase , hàm bắt đầu bằng động | addToCart() , isLoading |
|   | từ |   |
| Cột DB | snake_case giống hệt | image_path → thuộc tính |
|   | db_schema.dart | imagePath |
| Route | Hằng số trong AppRoutes , không gõ | AppRoutes.productDetail |
|   | chuỗi |   |
| Ảnh | <loại>_<brand>_<model>.png | racket_yonex_astrox99pro.png |
| Nhánh / | type(scope): mô tả | feat(cart): add swipe to delete |
| commit |   |   |

## Checklist trước khi push lên develop

- git pull --rebase origin develop trước

- flutter analyze không còn error

- Không có import 'package:sqflite/...' trong features/ hay shared/

- Không Color(0xFF...) , fontSize: 17 … trong màn hình — dùng token trong core/theme/

- Màn hình có đủ loading / empty / error / success

- Chỉ sửa file của mình (bảng owner ở mục 4)

- App chạy được sau khi gỡ và cài lại
