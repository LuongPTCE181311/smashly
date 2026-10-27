# **SMASHLY — Project Blueprint PRM393**

*Elevate Your Game.* · Oct 5, 2026 · @Lượng

## **1\. Executive Summary**

**Khuyến nghị: làm 15 màn hình, Provider \+ sqflite, kiến trúc 4 lớp mỏng (UI → Provider → Repository → DAO → SQLite), Home theo concept "Court Hero".** Đây là cấu hình đủ để demo một app thương mại điện tử hoàn chỉnh, mà 5 sinh viên trình độ Flutter trung bình vẫn hoàn thành trong 4 tuần.

* **Sản phẩm:** SMASHLY — app bán đồ cầu lông, light theme sạch, điểm nhấn "Smash Blue" và hero tối màu để tạo cảm giác premium.  
* **Phạm vi:** 2 vai trò (Customer, Admin), 15 màn hình thật, 0 màn hình filler. Search được gộp vào màn Shop để kết quả search và filter dùng chung một lưới sản phẩm.  
* **Dữ liệu:** SQLite local, 9 bảng (7 bắt buộc \+ racket\_specs \+ wishlists). Mỗi thành viên có DB riêng, Git chỉ chia sẻ schema, DAO, repository và seedDemoData().  
* **Ba quyết định quan trọng nhất cho điểm số:** (1) checkout chạy trong **SQLite transaction** và trừ tồn kho; (2) order\_items lưu **snapshot** tên \+ giá sản phẩm để xóa/sửa sản phẩm không làm hỏng lịch sử đơn; (3) mật khẩu được **hash SHA-256**, không lưu plain text.  
* **Chia việc theo domain:** mỗi người sở hữu một nhóm màn hình *và* phần data của nhóm đó, để không ai chỉ làm UI đơn giản trong khi người khác gánh toàn bộ database.  
* **Nguyên tắc cắt giảm:** gần deadline cắt NICE → SHOULD. Login/Register, checkout transaction và Product CRUD không bao giờ bị cắt.

Giả định: bắt đầu tuần này (05/10/2026), demo khoảng 01/11/2026. Nếu lịch môn khác, chỉ cần dời các mốc trong mục 29\.

## **2\. Product Vision**

**SMASHLY giúp người chơi cầu lông, kể cả người mới, chọn đúng vợt và phụ kiện trong vài phút mà không cần hiểu thuật ngữ kỹ thuật.**

* **Vấn đề:** người mới thấy "3U, head heavy, stiff shaft" nhưng không biết nghĩa là gì, nên chọn vợt theo giá hoặc theo màu.  
* **Giải pháp:** mỗi thông số được dịch thành ngôn ngữ người chơi ("Nặng đầu — đập cầu mạnh hơn"), kèm thanh chỉ báo trực quan, và Home có lối tắt "Shop by Play Style".  
* **Cảm giác thương hiệu:** *Elevate Your Game* — nhanh, sạch, tự tin. Futuristic ở mức chi tiết (glass nhẹ, gradient tối ở hero, chuyển động mượt), không phải giao diện game.  
* **Thước đo thành công khi demo:** một người chưa từng thấy app có thể tìm một cây vợt tấn công, thêm vào giỏ và đặt hàng trong dưới 60 giây.

**Không làm** (ngoài phạm vi): thanh toán thật, đăng nhập mạng xã hội, đồng bộ đám mây, chat, thông báo push.

## **3\. Target Users**

Ba persona đủ để mọi quyết định UI có người dùng cụ thể đứng sau; persona 1 là người dùng chính khi thiết kế.

| Persona | Mô tả | Nhu cầu chính | Hệ quả cho thiết kế |
| :---- | :---- | :---- | :---- |
| **Minh — người mới chơi** (19 tuổi, sinh viên) | Chơi 2 buổi/tuần, sắp mua cây vợt tốt đầu tiên, ngân sách 1–2 triệu | Hiểu thông số, được gợi ý theo lối chơi | Spec dạng chip \+ giải thích 1 dòng; filter "Player level"; shortcut Play Style ở Home |
| **Hà — người chơi phong trào** (28 tuổi, nhân viên văn phòng) | Biết mình thích vợt nặng đầu, mua thêm giày, cước, quấn cán | Tìm nhanh theo hãng/loại, mua lặp lại | Search theo brand, filter brand \+ giá, giỏ hàng nhiều món, lịch sử đơn |
| **Admin cửa hàng** | Quản lý kho sản phẩm của SMASHLY | Thêm/sửa/ẩn sản phẩm, xem tồn kho thấp | Dashboard có cảnh báo low stock, form sản phẩm có preview ảnh |

## **4\. Core Features**

Tất cả 19 feature bắt buộc trong đề đều được phủ; cột cuối cho biết feature nằm ở màn hình nào (mã S01–S15 ở mục 6).

| Nhóm | Feature | Mức | Màn hình |
| :---- | :---- | :---- | :---- |
| Auth | Splash \+ kiểm tra session | MUST | S01 |
| Auth | Login (email \+ password, phân role) | MUST | S02 |
| Auth | Register (validate, email unique, role CUSTOMER) | MUST | S03 |
| Auth | Logout xóa session | MUST | S12 |
| Auth | Forgot password (local: nhập email \+ SĐT khớp → đặt mật khẩu mới) | NICE | Bottom sheet trong S02 |
| Mua sắm | Home premium | MUST | S04 |
| Mua sắm | Product listing \+ Search \+ Filter | MUST | S05 |
| Mua sắm | Product detail với spec trực quan | MUST | S06 |
| Mua sắm | Wishlist (tim) | SHOULD | Icon trên card \+ tab trong S12 |
| Mua hàng | Cart lưu SQLite, chọn món, số lượng | MUST | S07 |
| Mua hàng | Checkout mock payment, transaction | MUST | S08 |
| Mua hàng | Order success | MUST | S09 |
| Đơn hàng | My Orders theo status | MUST | S10 |
| Đơn hàng | Order detail \+ timeline | MUST | S11 |
| Đơn hàng | Khách hủy đơn Pending (hoàn tồn kho) | SHOULD | S11 |
| Admin | Dashboard (số liệu, low stock) | MUST | S13 |
| Admin | Product CRUD | MUST | S14, S15 |
| Admin | Cập nhật trạng thái đơn | SHOULD | Bottom sheet trong S13 |
| Nền tảng | SQLite local \+ seed, ảnh local, design system, animation | MUST | Toàn app |

## **5\. Recommended Screen Count**

**15 màn hình: 12 customer \+ 3 admin.** Mỗi màn hình trả lời một câu hỏi riêng của người dùng; không có màn nào chỉ để tăng số lượng.

Đã cân nhắc và **không** tách thành màn riêng:

* **Search:** gộp vào Shop (S05). Nếu tách, app có hai lưới kết quả giống hệt nhau và người dùng phải học hai nơi lọc. Gộp lại thì search \+ filter \+ sort cùng tác động lên một danh sách — đây cũng là cách Shopee, Nike, Decathlon làm. Recent searches hiện khi ô tìm kiếm được focus và còn trống.  
* **Filter:** là bottom sheet, không phải màn hình — người dùng thấy ngay kết quả phía sau khi đóng sheet.  
* **Add Product / Edit Product:** một màn form dùng chung (S15), khác nhau ở tiêu đề và dữ liệu điền sẵn. Hai màn riêng sẽ trùng 90% code.  
* **Wishlist:** SHOULD, nằm trong Profile thay vì thêm tab thứ 6 ở bottom nav.

Số màn theo người: TV1 có 4 (2 màn nhỏ), TV2 có 2 (cả hai đều nặng nhất app), TV3–TV5 mỗi người 3\. Mục 25 cân bằng lại bằng điểm độ khó và shared tasks.

## **6\. Complete Screen List**

Độ khó tính theo thang 1–5 (gồm UI \+ logic \+ DB \+ animation); thời gian là ngày công của một người, đã gồm 4 trạng thái loading/empty/error/success.

| Mã | Màn hình | User | Mục đích | Owner | Độ khó | Ưu tiên | Ước lượng |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| S01 | Splash | Cả hai | Khởi tạo DB, đọc session, điều hướng theo role | TV1 | 1 | MUST | 0,5 ngày |
| S02 | Login | Cả hai | Đăng nhập, phân luồng Customer/Admin | TV1 | 2 | MUST | 1,5 ngày |
| S03 | Register | Customer | Tạo tài khoản CUSTOMER | TV1 | 2 | MUST | 1,5 ngày |
| S04 | Home | Customer | Khám phá: hero, danh mục, nổi bật, thương hiệu | TV2 | 4 | MUST | 4 ngày |
| S05 | Shop (Listing \+ Search \+ Filter) | Customer | Tìm và lọc sản phẩm | TV2 | 5 | MUST | 5 ngày |
| S06 | Product Detail | Customer | Hiểu sản phẩm và thêm vào giỏ | TV3 | 4 | MUST | 4 ngày |
| S07 | Cart | Customer | Xem, chỉnh và chọn món để mua | TV4 | 3 | MUST | 3 ngày |
| S08 | Checkout | Customer | Nhập giao hàng, chọn thanh toán, đặt đơn | TV4 | 3 | MUST | 3 ngày |
| S09 | Order Success | Customer | Xác nhận đặt hàng thành công | TV4 | 1 | MUST | 1 ngày |
| S10 | My Orders | Customer | Danh sách đơn theo trạng thái | TV3 | 2 | MUST | 2 ngày |
| S11 | Order Detail | Customer | Chi tiết \+ timeline đơn | TV3 | 3 | MUST | 2,5 ngày |
| S12 | Profile | Cả hai | Thông tin tài khoản, wishlist, logout | TV1 | 1 | MUST | 1 ngày |
| S13 | Admin Dashboard | Admin | Tổng quan kho, đơn gần đây, low stock | TV5 | 2 | MUST | 2 ngày |
| S14 | Admin Products | Admin | Danh sách \+ search/filter \+ xóa sản phẩm | TV5 | 2 | MUST | 2,5 ngày |
| S15 | Admin Product Form | Admin | Thêm / sửa sản phẩm và spec vợt | TV5 | 3 | MUST | 3 ngày |

Tổng khoảng 37 ngày công cho màn hình, cộng khoảng 13 ngày công shared tasks (mục 25\) — vừa với 5 người × 4 tuần khi còn chừa 1 tuần polish.

## **7\. Detailed Screen Specifications**

Mỗi spec dưới đây là "definition of done" của màn hình: chưa đủ 4 trạng thái thì chưa được merge vào develop.

### **S01 — Splash**

*Customer \+ Admin · TV1 · độ khó 1 · MUST · 0,5 ngày*

* **Mục đích:** mở DB (tạo bảng \+ seed lần đầu), đọc session, chuyển đúng màn.  
* **Layout:** nền gradient tối (Midnight → Navy), logo SMASHLY giữa màn, tagline nhỏ bên dưới, thanh tiến trình mảnh ở đáy.  
* **Components:** AppLogo, LinearProgressIndicator tùy biến.  
* **SQLite:** mở DB qua DatabaseHelper; đọc users theo userId trong session. **CRUD:** Read.  
* **Navigation:** có session \+ role ADMIN → S13; có session \+ CUSTOMER → App shell (S04); không có → S02. Dùng pushReplacement để Back không quay lại Splash.  
* **Animation:** logo fade \+ scale 0.9→1.0 trong 600 ms; tổng thời gian tối thiểu 1,2 s để không nháy.  
* **Loading:** chính là màn này. **Empty:** không áp dụng. **Error:** DB lỗi → thông báo "Không khởi tạo được dữ liệu" \+ nút Thử lại. **Success:** chuyển màn mượt (fade).

### **S02 — Login**

*Customer \+ Admin · TV1 · độ khó 2 · MUST · 1,5 ngày*

* **Layout:** 40% trên là header tối có logo \+ "Welcome back"; phần dưới là card trắng bo góc 24 chứa form, kéo lên đè lên header một chút (layered).  
* **Components:** AppTextField (email, password có toggle hiện/ẩn), PrimaryButton có trạng thái loading, link "Forgot password?" (NICE), link "Chưa có tài khoản? Đăng ký".  
* **SQLite:** users — SELECT \* FROM users WHERE email \= ? rồi so sánh hash. **CRUD:** Read.  
* **Interaction:** validate inline khi rời ô (email đúng định dạng, password không trống); nút Login disable khi form chưa hợp lệ; Enter ở ô password \= submit.  
* **Navigation:** ADMIN → S13, CUSTOMER → S04 (đều pushAndRemoveUntil); "Đăng ký" → S03.  
* **Animation:** form slide-up 300 ms khi vào; nút co nhẹ khi nhấn; lỗi thì card rung ngang nhẹ 1 lần.  
* **Loading:** spinner trong nút, khóa form. **Error:** banner đỏ nhạt trong card: "Email hoặc mật khẩu chưa đúng" (không nói rõ cái nào sai). **Success:** chuyển màn; không cần toast.

### **S03 — Register**

*Customer · TV1 · độ khó 2 · MUST · 1,5 ngày*

* **Layout:** cùng khung với Login (đổi tiêu đề "Create your account"), 5 ô: Full name, Email, Phone, Password, Confirm password.  
* **Components:** AppTextField với textInputAction: next, keyboard type phù hợp (email, phone), thanh độ mạnh mật khẩu 3 nấc dưới ô password.  
* **SQLite:** users — kiểm tra email tồn tại, INSERT với role \= 'CUSTOMER' (cứng trong code, không có ô chọn role), đồng thời tạo dòng carts. **CRUD:** Create \+ Read.  
* **Validation:** tên ≥ 2 ký tự; email hợp lệ và chưa tồn tại; SĐT 10 số bắt đầu bằng 0; password ≥ 8 ký tự, có chữ và số; confirm khớp.  
* **Navigation:** thành công → quay về S02 với email điền sẵn \+ SnackBar "Tạo tài khoản thành công". (Không auto-login để demo được cả hai luồng.)  
* **Animation:** check xanh xuất hiện cạnh ô khi hợp lệ; nút loading.  
* **Error:** "Email này đã được đăng ký" ngay dưới ô email. **Success:** SnackBar xanh \+ email điền sẵn.

### **S04 — Home**

*Customer · TV2 · độ khó 4 · MUST · 4 ngày*

* **Layout (concept Court Hero, mục 9):** header lời chào \+ icon giỏ có badge → ô search giả (tap mở S05 với bàn phím bật) → hero card tối có sản phẩm nổi bật → hàng danh mục cuộn ngang → "Shop by Play Style" (4 chip lớn) → "Featured Rackets" cuộn ngang → "Top Brands" → "Trending Now" lưới 2 cột.  
* **Components:** HeroBanner, CategoryCard, PlayStyleChip, ProductCard, SectionHeader (tiêu đề \+ "Xem tất cả"), BrandLogoTile.  
* **SQLite:** products (is\_featured, ORDER BY rating), categories, racket\_specs cho Play Style. **CRUD:** Read.  
* **Navigation:** tap danh mục/brand/play style → S05 với filter điền sẵn; tap sản phẩm → S06 (Hero transition ảnh); icon giỏ → tab Cart.  
* **Animation:** các section fade \+ trượt lên lệch nhau 60 ms khi lần đầu tải; pull-to-refresh.  
* **Loading:** shimmer skeleton đúng hình các section (không dùng spinner giữa màn). **Empty:** nếu không có sản phẩm nổi bật thì ẩn section đó. **Error:** ErrorState toàn màn \+ Thử lại.

### **S05 — Shop (Listing \+ Search \+ Filter)**

*Customer · TV2 · độ khó 5 · MUST · 5 ngày*

* **Layout:** AppBar có ô search thật (nút X để xóa) → hàng chip danh mục cuộn ngang (All, Rackets, Shoes…) → thanh "124 sản phẩm · Sắp xếp ▾ · Bộ lọc (2)" → lưới 2 cột ProductCard.  
* **Search:** debounce 300 ms, tìm theo name/brand/category (LIKE ? trên 3 cột, join categories). Khi ô focus và trống: hiện tối đa 6 recent searches (SharedPreferences) \+ nút xóa lịch sử.  
* **Filter (bottom sheet):** Category, Brand (chip chọn nhiều), Price (RangeSlider), Rating (≥3★, ≥4★, ≥4.5★); khi Category \= Rackets hiện thêm Weight, Balance, Shaft, Player level, Play style. Nút Reset \+ Apply ("Xem 18 kết quả" — đếm trực tiếp).  
* **Sort:** Phổ biến, Giá tăng, Giá giảm, Đánh giá cao.  
* **SQLite:** một query động trong ProductDao.search(ProductQuery q), LEFT JOIN racket\_specs. **CRUD:** Read.  
* **Animation:** lưới đổi bằng AnimatedSwitcher; số bộ lọc trên nút nảy nhẹ khi thay đổi.  
* **Loading:** skeleton lưới 6 ô. **Empty:** minh họa vợt \+ "Không tìm thấy "astrox 100"" \+ nút "Xóa bộ lọc". **Error:** ErrorState \+ Thử lại.

## **8\. UI/UX Concept**

**Concept: "Light Court, Dark Spotlight"** — nền sáng, sạch như sân thi đấu; chỉ những khoảnh khắc quan trọng (hero Home, Splash, header Login, thẻ sản phẩm nổi bật) dùng nền tối có gradient nhẹ như ánh đèn sân. Cách này cho cảm giác premium/futuristic mà vẫn dễ đọc và không mỏi mắt.

* **Light làm chủ đạo, dark làm điểm nhấn:** dark theme toàn app trông "ngầu" nhưng tăng gấp đôi việc kiểm tra contrast và dễ lệch giữa 5 người. Dark mode là NICE.  
* **Một màu hành động duy nhất:** Smash Blue cho mọi CTA chính. Người dùng học được "xanh \= bấm để đi tiếp" sau 1 màn.  
* **Màu lime (Volt) chỉ dùng cho badge trên nền tối** ("NEW", "-15%") — nhỏ, hiếm, nên mới nổi bật.  
* **Glassmorphism có giới hạn:** chỉ 2 chỗ — thanh bottom nav (blur nhẹ khi nội dung cuộn phía sau) và nhãn giá trên hero card. Không áp dụng cho form hay danh sách.  
* **Ảnh sản phẩm là nhân vật chính:** PNG nền trong suốt, đặt trên khối nền xám-xanh rất nhạt, bóng đổ mềm dưới sản phẩm để tạo chiều sâu.  
* **Bottom navigation 5 tab:** Home · Shop · Cart (badge) · Orders · Profile. Đúng với mô hình người dùng đã quen từ các app mua sắm; mọi tab dùng icon \+ nhãn chữ.  
* **Vùng chạm một tay:** CTA chính luôn nằm ở 1/3 dưới màn hình (thanh CTA cố định ở Detail, Cart, Checkout); vùng chạm tối thiểu 48×48.  
* **Ngôn ngữ giao diện:** tiếng Việt cho nội dung, giữ tiếng Anh cho tên thương hiệu, tagline và thuật ngữ cầu lông quen thuộc (Head Heavy, Stiff).

## **9\. 3 Home Page Concepts \+ Comparison**

**Chọn Concept A "Court Hero", mượn thêm module "Shop by Play Style" từ Concept B.** A cho điểm UX và độ chuyên nghiệp cao nhất với rủi ro thấp; module của B chỉ là một filter điền sẵn nên gần như không tốn thêm công nhưng tạo điểm nhấn khi demo.

### **Concept A — Court Hero (editorial premium)**

Header chào \+ giỏ → ô search → **hero card tối** (một cây vợt nổi bật, tên lớn, giá trong nhãn glass, nút "Khám phá") → danh mục dạng icon tròn → "Featured Rackets" cuộn ngang → logo thương hiệu → "Trending" lưới 2 cột. Giống trang chủ Nike/Yonex: rõ thứ bậc, ít chữ, ảnh lớn.

### **Concept B — Smart Finder (cá nhân hóa)**

Phần đầu là "Bạn chơi kiểu gì?" với 4 thẻ lớn: Tấn công · Kiểm soát · Toàn diện · Mới chơi. Chọn một thẻ thì toàn bộ phần dưới (vợt gợi ý, giày, phụ kiện) đổi theo. Ấn tượng về "tư vấn", nhưng người chỉ muốn lướt xem hàng phải chọn trước, và logic gợi ý phải viết riêng.

### **Concept C — Immersive Showcase (trình diễn)**

Cả màn là một PageView dọc toàn màn hình, mỗi trang một sản phẩm với nền gradient đổi màu, ảnh vợt xoay/parallax theo cử chỉ, thông tin trên tấm glass. Rất "wow" trong 10 giây đầu, nhưng không duyệt được nhiều sản phẩm, khó tìm danh mục, và animation nặng dễ giật trên máy yếu.

### **So sánh**

| Tiêu chí | A — Court Hero | B — Smart Finder | C — Immersive |
| :---- | :---- | :---- | :---- |
| Visual quality | 8/10 | 8/10 | 9/10 |
| UX | **9/10** | 8/10 | 5/10 |
| Professionalism | **9/10** | 8/10 | 7/10 |
| Futuristic feeling | 7/10 | 8/10 | 10/10 |
| Flutter difficulty (càng cao càng khó) | **4/10** | 6/10 | 9/10 |
| Animation potential | 7/10 | 8/10 | 10/10 |
| Development time | 4 ngày | 6–7 ngày | 9–10 ngày |
| Risk | Thấp | Trung bình | Cao |
| Demo impact | Cao | Cao | Rất cao nếu chạy mượt, thấp nếu giật |

**Vì sao không chọn C dù điểm visual cao nhất:** tiêu chí số 1 của project là UX \> Visual Effects. C hy sinh khả năng duyệt và tìm sản phẩm — đúng thứ giảng viên sẽ thử đầu tiên — và chiếm gấp đôi thời gian của một người.

**Bản kết hợp được chọn (A \+ 1 module B):** Header → Search → Hero → Danh mục → **Shop by Play Style** (4 chip lớn, tap → Shop với filter Play style) → Featured Rackets → Top Brands → Trending. Tổng \~4,5 ngày cho TV2.

## **10\. Product Detail UX**

**Mỗi thông số vợt được hiển thị bằng 3 lớp: nhãn ngắn → thanh chỉ báo trực quan → một câu "nghĩa là gì với bạn".** Người mới đọc câu giải thích, người chơi lâu năm chỉ cần liếc nhãn.

Thứ tự thông tin từ trên xuống: Ảnh → Brand \+ Tên → Giá → Rating → Key Specs → Mô tả → Tồn kho → CTA cố định ở đáy (luôn nhìn thấy, không cần cuộn).

**Key Specs — lưới 2 cột SpecCard cho vợt:**

| Spec | Cách hiển thị | Câu giải thích (ví dụ) |
| :---- | :---- | :---- |
| Weight (3U / 4U / 5U) | Chip \+ khoảng gram (4U \= 80–84 g) | "Nhẹ, xoay vợt nhanh, dễ phòng thủ" |
| Balance | Thanh trượt 3 vùng Head Light — Even — Head Heavy, chấm ở vị trí vợt | "Nặng đầu: đập cầu uy lực hơn" |
| Shaft stiffness | SpecMeter 4 nấc Flexible → Extra Stiff | "Cứng: kiểm soát chính xác, cần lực cổ tay tốt" |
| Max tension | Số lớn "28 lbs" | "Căng tối đa khuyến nghị của hãng" |
| Player level | Badge Beginner / Intermediate / Advanced | "Phù hợp người chơi trên 2 năm" |
| Play style | Icon \+ chữ Attack / Control / All-round / Defense | "Dành cho lối chơi tấn công" |

* **Gói gọn trong một câu "Hợp với ai":** ngay trên lưới spec, sinh tự động từ các spec, ví dụ: *"Vợt tấn công, nặng đầu, đũa cứng — hợp người chơi trình độ khá thích đập cầu."*  
* **Sản phẩm không phải vợt:** lưới spec được thay bằng 2–3 "điểm nổi bật" lấy từ mô tả và chọn size (giày/áo), để màn không bị trống.  
* **Tồn kho:** "Còn hàng" (xanh, icon check) · "Chỉ còn 3" (cam, icon cảnh báo) · "Hết hàng" (xám, nút CTA disable). Luôn có chữ, không chỉ dựa vào màu.  
* **CTA:** stepper số lượng bên trái (40%), nút "Thêm vào giỏ" Smash Blue bên phải (60%), cao 56\. Không có nút "Mua ngay" để tránh hai CTA ngang nhau làm người dùng phân vân.  
* **Giải thích thuật ngữ:** icon (i) cạnh tiêu đề "Thông số" mở bottom sheet "Đọc thông số vợt trong 30 giây" — rẻ để làm, rất được điểm khi thuyết trình.

## **11\. Search & Filter UX**

**Search, chip danh mục, filter và sort đều chỉnh một object ProductQuery duy nhất, và Shop hiển thị kết quả của object đó.** Một nguồn sự thật nên không bao giờ có chuyện search ra một kiểu, filter ra kiểu khác.

class ProductQuery {  
  final String keyword;  
  final int? categoryId;  
  final Set\<String\> brands;  
  final int? minPrice, maxPrice;  
  final double? minRating;  
  final Set\<String\> weights, balances, shafts, levels, styles; // chỉ dùng cho vợt  
  final ProductSort sort;  
  int get activeFilterCount { ... } // hiển thị trên nút "Bộ lọc (3)"  
}  
**Search**

* Ô search luôn ở trên cùng Shop; tap ô search giả ở Home → mở Shop với ô đã focus.  
* Debounce 300 ms, tìm trên name, brand, categories.name (không phân biệt hoa thường). Từ khóa khớp được **in đậm** trong tên trên card.  
* Ô trống \+ đang focus: "Tìm gần đây" (tối đa 6, lưu SharedPreferences, có nút xóa từng mục và "Xóa tất cả") \+ "Gợi ý": Yonex, Astrox, Giày, Quấn cán.  
* Nút X xóa từ khóa nhưng **giữ** filter; chip "Xóa bộ lọc" riêng.

**Filter (bottom sheet cao 85%)**

* Thứ tự nhóm: Danh mục → Thương hiệu → Khoảng giá → Đánh giá → (nếu là Vợt) Trọng lượng, Điểm cân bằng, Độ cứng đũa, Trình độ, Lối chơi.  
* Thương hiệu: chip chọn nhiều, có logo nhỏ. Giá: RangeSlider 0–5.000.000₫ bước 100.000 \+ 2 ô số hiển thị giá trị. Rating: 3 chip ≥3★ / ≥4★ / ≥4.5★.  
* Nhóm thông số vợt dùng chip có icon (giống trên Product Detail) để người dùng thấy cùng một "ngôn ngữ".  
* Nút Apply ghi số kết quả trực tiếp: "Xem 18 sản phẩm" (query COUNT khi đổi lựa chọn). Nếu 0 → nút ghi "Không có sản phẩm phù hợp" và disable.  
* "Đặt lại" ở góc trên phải sheet. Đóng sheet bằng vuốt xuống \= hủy thay đổi.  
* Dưới thanh kết quả, các filter đang áp dụng hiện thành chip có dấu X để gỡ nhanh từng cái mà không cần mở lại sheet.

**Empty state:** "Không tìm thấy kết quả cho 'astrox 100'" \+ gợi ý "Thử từ khóa ngắn hơn hoặc bỏ bớt bộ lọc" \+ nút "Xóa bộ lọc".

## **12\. Cart UX**

**Giỏ hàng sống trong SQLite (carts \+ cart\_items); CartProvider chỉ giữ bản đọc ra để vẽ UI và đọc lại DB sau mỗi thay đổi.** Thoát app, mở lại, đăng nhập lại — giỏ vẫn còn, và đây là điểm nên chỉ ra khi demo.

| Hành động | UI | SQLite |
| :---- | :---- | :---- |
| Thêm sản phẩm (từ Detail/Card) | SnackBar "Đã thêm · Xem giỏ", badge nảy | UPSERT cart\_items theo (cart\_id, product\_id, size); cộng dồn, chặn ở stock |
| Tăng / giảm | Stepper; số đổi bằng animation trượt dọc | UPDATE quantity; nút − disable ở 1, nút \+ disable ở stock |
| Xóa | Vuốt trái hoặc icon thùng rác; SnackBar có Undo 4 s | DELETE; Undo \= INSERT lại dòng đã giữ trong biến |
| Chọn / bỏ chọn món | Checkbox bên trái | UPDATE is\_selected (giữ lựa chọn khi thoát app) |
| Chọn tất cả | Checkbox trên AppBar; trạng thái 3 mức (tất cả / một phần / không) | UPDATE tất cả item còn hàng |
| Tính tiền | Thanh đáy: tạm tính các món được chọn | Tính trong Provider từ dữ liệu đã đọc — không lưu tổng vào DB |

* **Giá luôn lấy giá hiện tại** từ products (JOIN), không lưu giá trong cart\_items; giá chỉ bị "đóng băng" khi đặt hàng (snapshot ở order\_items).  
* **Sản phẩm bị admin ẩn hoặc hết hàng:** item vẫn hiện nhưng mờ, nhãn "Hết hàng" / "Ngừng bán", không chọn được, không tính tiền.  
* **Badge giỏ** trên tab Cart và icon ở Home hiển thị *tổng số lượng*; dùng AnimatedScale mỗi khi số thay đổi.  
* **Nút "Mua hàng (2)"** disable khi không có món nào được chọn, kèm dòng phụ "Chọn ít nhất 1 sản phẩm".  
* **Phí ship hiển thị ở Checkout, không ở Cart** để Cart chỉ trả lời một câu: "Mình đang chọn mua gì?".

## **13\. Checkout UX**

**Checkout là một màn, ba card, một nút; toàn bộ việc ghi dữ liệu nằm trong một SQLite transaction để không bao giờ có đơn "nửa vời".**

1. **Thông tin nhận hàng** — Họ tên, SĐT, Địa chỉ (điền sẵn từ users, sửa được). Checkbox "Lưu làm địa chỉ mặc định".  
2. **Phương thức thanh toán** — 3 radio card có icon: Thanh toán khi nhận hàng (COD, mặc định) · Chuyển khoản ngân hàng *(mô phỏng)* · Ví điện tử *(mô phỏng)*. Chọn chuyển khoản/ví thì hiện khung thông tin giả ("STK 0123456789 – SMASHLY DEMO") và ghi rõ "Demo — không phát sinh giao dịch thật".  
3. **Tóm tắt đơn** — danh sách thu gọn các món (ảnh nhỏ, tên, SL), Tạm tính, Phí vận chuyển (30.000₫; miễn phí khi tạm tính ≥ 1.000.000₫), **Tổng cộng**.

Nút cố định đáy: **"Đặt hàng · 4.610.000₫"** — số tiền nằm ngay trong nút để người dùng biết chính xác mình xác nhận điều gì.

**Transaction khi bấm Đặt hàng** (OrderRepository.placeOrder):

return db.transaction((txn) async {  
  // 1\. Đọc lại stock của từng món đã chọn; thiếu hàng \-\> throw OutOfStockException(productName)  
  // 2\. INSERT orders (order\_code, status \= 'PENDING', receiver..., subtotal, shipping\_fee, total)  
  // 3\. INSERT order\_items cho từng món (snapshot: product\_name, product\_image, unit\_price, size)  
  // 4\. UPDATE products SET stock \= stock \- ? WHERE id \= ?  
  // 5\. DELETE FROM cart\_items WHERE cart\_id \= ? AND is\_selected \= 1  
  return orderId;  
});

* Lỗi ở bất kỳ bước nào → toàn bộ rollback, giỏ hàng giữ nguyên, hiện dialog lỗi dễ hiểu.  
* Chặn bấm 2 lần: nút chuyển loading và disable ngay khi bấm.  
* order\_code dạng SML-YYYYMMDD-NNNN dễ đọc khi demo, thay vì chỉ hiện id số.

## **14\. Order UX**

**Đơn hàng đi theo một đường thẳng Pending → Confirmed → Shipping → Delivered, chỉ có một nhánh rẽ là Cancelled (từ Pending hoặc Confirmed).** Trạng thái luôn hiển thị bằng icon \+ chữ \+ màu, không bao giờ chỉ bằng màu.

| Status (DB) | Nhãn hiển thị | Icon | Màu | Ai đổi được |
| :---- | :---- | :---- | :---- | :---- |
| PENDING | Chờ xác nhận | schedule | Cam | Tạo khi đặt hàng |
| CONFIRMED | Đã xác nhận | check\_circle | Xanh dương | Admin (SHOULD) |
| SHIPPING | Đang giao | local\_shipping | Tím | Admin (SHOULD) |
| DELIVERED | Đã giao | inventory\_2 | Xanh lá | Admin (SHOULD) |
| CANCELLED | Đã hủy | cancel | Đỏ | Khách (khi Pending) hoặc Admin; hoàn lại stock |

* **Không có admin đổi trạng thái thì sao?** Seed sẵn 4 đơn cho customer demo ở 4 trạng thái khác nhau, nên My Orders và timeline vẫn đầy đủ ngay cả khi phần SHOULD bị cắt.  
* **My Orders:** tab theo trạng thái, mới nhất lên đầu. Mỗi OrderCard: mã đơn \+ ngày ("05/10/2026 · 15:42"), badge, ảnh món đầu \+ "Astrox 99 Pro và 2 sản phẩm khác", Tổng tiền in đậm bên phải.  
* **Order Detail — timeline dọc:** bước đã xong \= chấm đặc \+ đường nối màu primary \+ thời gian; bước hiện tại \= chấm có vòng sáng nhẹ; bước chưa tới \= chấm rỗng xám. Đơn hủy: timeline dừng ở bước cuối đã đạt và thêm một bước đỏ "Đã hủy".  
* **Thời gian từng bước:** lưu ở orders bằng các cột confirmed\_at, shipped\_at, delivered\_at, cancelled\_at (nullable) — đơn giản hơn tạo thêm bảng lịch sử, vì luồng trạng thái là cố định.  
* **Đơn cũ không bị ảnh hưởng khi admin sửa/xóa sản phẩm:** Order Detail đọc tên, ảnh, giá từ snapshot trong order\_items.

## **15\. Admin UX**

**Admin dùng cùng design system nhưng đổi "giọng": mật độ thông tin cao hơn, danh sách dạng hàng thay cho lưới ảnh, không có hero hay animation trang trí.** Admin làm việc, không mua sắm.

* **Điều hướng:** không dùng bottom nav của customer. Dashboard là gốc; từ đó vào Products → Form. Header có avatar mở menu: Hồ sơ, Đăng xuất. Header Admin dùng dải tối Midnight để admin luôn biết mình đang ở khu vực quản trị.  
* **Dashboard:** 4 thẻ số (mỗi thẻ tap được tới danh sách đã lọc tương ứng), danh sách "Sắp hết hàng" (stock ≤ 5, sắp xếp tăng dần), 5 đơn gần đây.  
* **Danh sách sản phẩm:** search theo tên/brand, chip danh mục, chip "Đang ẩn". Tồn kho hiển thị "12" (thường), "3 · Sắp hết" (cam), "0 · Hết" (đỏ).  
* **Form:** một màn cho cả thêm và sửa; nhóm field thành card (Thông tin chung · Giá & kho · Thông số vợt · Hiển thị); chọn ảnh từ lưới asset có sẵn (vì không có upload lên server) với preview lớn.

**Delete — quyết định quan trọng:**

| Trường hợp | Hành vi | Lý do |
| :---- | :---- | :---- |
| Sản phẩm **chưa từng** nằm trong đơn nào | DELETE thật khỏi products (+ racket\_specs cascade, \+ xóa khỏi giỏ/wishlist) | Đúng nghĩa CRUD, không để rác |
| Sản phẩm **đã có** trong order\_items | Soft delete: is\_active \= 0 ("Ngừng bán"), có Undo | Giữ toàn vẹn lịch sử đơn và báo cáo doanh thu |

Dialog xác nhận luôn nêu tên sản phẩm và hậu quả: *"Xóa 'Astrox 99 Pro'? Sản phẩm đã có trong 3 đơn hàng nên sẽ được chuyển sang Ngừng bán thay vì xóa vĩnh viễn."* Đây là chi tiết giảng viên thường hỏi; có câu trả lời sẵn là ghi điểm.

## **16\. SQLite Database Design**

**9 bảng: 7 bảng bắt buộc \+ racket\_specs (1–1 với products) \+ wishlists (SHOULD, tạo sẵn từ đầu để khỏi migration).** Tiền lưu INTEGER theo VND để tránh sai số số thực; thời gian lưu TEXT ISO-8601; boolean lưu INTEGER 0/1 vì SQLite không có kiểu bool. Bật PRAGMA foreign\_keys \= ON trong onConfigure — SQLite mặc định *tắt* khóa ngoại.

**Hai lựa chọn có chủ đích:**

* **Brand là cột TEXT, không phải bảng riêng:** chỉ \~6 thương hiệu, không có thuộc tính riêng; lấy danh sách bằng SELECT DISTINCT brand. Bảng riêng thêm 1 join và 1 màn quản lý mà không đem lại giá trị demo.  
* **Spec vợt ở bảng racket\_specs riêng thay vì 6 cột nullable trong products:** giày, áo không có các cột vô nghĩa; form admin chỉ ghi bảng này khi danh mục là Rackets.

### **users**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| id | INTEGER | PK, AUTOINCREMENT | No |  |  |
| full\_name | TEXT |  | No |  | Họ tên |
| email | TEXT | UNIQUE | No |  | Lưu lowercase, dùng để đăng nhập |
| phone | TEXT |  | No |  | 10 chữ số |
| password\_hash | TEXT |  | No |  | SHA-256(email \+ password), không lưu plain text |
| role | TEXT | CHECK IN ('CUSTOMER','ADMIN') | No | 'CUSTOMER' | Register luôn ghi CUSTOMER |
| address | TEXT |  | Yes | NULL | Địa chỉ mặc định cho Checkout |
| created\_at | TEXT |  | No | CURRENT\_TIMESTAMP |  |

### **categories**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| id | INTEGER | PK | No |  |  |
| name | TEXT | UNIQUE | No |  | Rackets, Shoes, Shirts, Shorts, Socks, Bags, Grips, Strings, Nets, Accessories |
| icon\_path | TEXT |  | No |  | assets/images/categories/rackets.png |
| sort\_order | INTEGER |  | No | 0 | Thứ tự trên Home |

### **products**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| id | INTEGER | PK | No |  |  |
| category\_id | INTEGER | FK → categories.id ON DELETE RESTRICT | No |  |  |
| name | TEXT |  | No |  |  |
| brand | TEXT | INDEX | No |  | Yonex, Victor, Li-Ning, Mizuno… |
| price | INTEGER | CHECK \> 0 | No |  | Giá bán (VND) |
| original\_price | INTEGER |  | Yes | NULL | Có giá trị và \> price → hiện % giảm |
| stock | INTEGER | CHECK ≥ 0 | No | 0 |  |
| rating | REAL | CHECK 0–5 | No | 0 | Điểm seed (chưa có bảng reviews) |
| rating\_count | INTEGER |  | No | 0 | "(128)" trên card |
| description | TEXT |  | No | '' |  |
| image\_path | TEXT |  | No |  | Đường dẫn asset |
| sizes | TEXT |  | Yes | NULL | "39,40,41,42" cho giày/áo; NULL \= không cần size |
| is\_featured | INTEGER |  | No | 0 | Hiện ở hero/Featured |
| is\_active | INTEGER |  | No | 1 | 0 \= ngừng bán (soft delete) |
| created\_at / updated\_at | TEXT |  | No | CURRENT\_TIMESTAMP |  |

### **racket\_specs (1–1 với products)**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| product\_id | INTEGER | PK, FK → products.id ON DELETE CASCADE | No |  |  |
| weight\_class | TEXT | CHECK IN ('2U','3U','4U','5U') | No |  |  |
| balance | TEXT | CHECK IN ('HEAD\_LIGHT','EVEN','HEAD\_HEAVY') | No |  |  |
| shaft | TEXT | CHECK IN ('FLEXIBLE','MEDIUM','STIFF','EXTRA\_STIFF') | No |  |  |
| max\_tension\_lbs | INTEGER |  | No |  |  |
| player\_level | TEXT | CHECK IN ('BEGINNER','INTERMEDIATE','ADVANCED') | No |  |  |
| play\_style | TEXT | CHECK IN ('ATTACK','CONTROL','ALL\_ROUND','DEFENSE') | No |  |  |

### **carts**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| id | INTEGER | PK | No |  |  |
| user\_id | INTEGER | FK → users.id ON DELETE CASCADE, UNIQUE | No |  | Mỗi user đúng 1 giỏ, tạo khi Register/seed |
| updated\_at | TEXT |  | No | CURRENT\_TIMESTAMP |  |

### **cart\_items**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| id | INTEGER | PK | No |  |  |
| cart\_id | INTEGER | FK → carts.id ON DELETE CASCADE | No |  |  |
| product\_id | INTEGER | FK → products.id ON DELETE CASCADE | No |  |  |
| quantity | INTEGER | CHECK \> 0 | No | 1 |  |
| size | TEXT |  | Yes | NULL |  |
| is\_selected | INTEGER |  | No | 1 | Món được chọn để mua |
| added\_at | TEXT |  | No | CURRENT\_TIMESTAMP |  |
|  |  | UNIQUE(cart\_id, product\_id, size) |  |  | Chặn trùng dòng |

### **orders**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| id | INTEGER | PK | No |  |  |
| order\_code | TEXT | UNIQUE | No |  | SML-20261005-0007 |
| user\_id | INTEGER | FK → users.id ON DELETE RESTRICT | No |  |  |
| status | TEXT | CHECK IN ('PENDING','CONFIRMED','SHIPPING','DELIVERED','CANCELLED') | No | 'PENDING' |  |
| receiver\_name / receiver\_phone / shipping\_address | TEXT |  | No |  | Snapshot thông tin giao hàng |
| payment\_method | TEXT | CHECK IN ('COD','BANK\_TRANSFER','E\_WALLET') | No | 'COD' |  |
| note | TEXT |  | Yes | NULL |  |
| subtotal / shipping\_fee / total | INTEGER |  | No |  | VND |
| created\_at | TEXT |  | No | CURRENT\_TIMESTAMP | Thời điểm Pending |
| confirmed\_at / shipped\_at / delivered\_at / cancelled\_at | TEXT |  | Yes | NULL | Cho timeline |

### **order\_items**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| id | INTEGER | PK | No |  |  |
| order\_id | INTEGER | FK → orders.id ON DELETE CASCADE | No |  |  |
| product\_id | INTEGER | FK → products.id ON DELETE SET NULL | Yes |  | NULL nếu sản phẩm bị xóa cứng |
| product\_name | TEXT |  | No |  | Snapshot |
| product\_image | TEXT |  | No |  | Snapshot |
| unit\_price | INTEGER |  | No |  | Snapshot giá lúc mua |
| quantity | INTEGER | CHECK \> 0 | No |  |  |
| size | TEXT |  | Yes | NULL |  |

### **wishlists (SHOULD)**

| Column | Type | Key | Null | Default | Mô tả |
| :---- | :---- | :---- | :---- | :---- | :---- |
| user\_id | INTEGER | PK(user\_id, product\_id), FK → users.id CASCADE | No |  |  |
| product\_id | INTEGER | FK → products.id CASCADE | No |  |  |
| created\_at | TEXT |  | No | CURRENT\_TIMESTAMP |  |

reviews (NICE) không tạo ở phiên bản 1; rating trong products là dữ liệu seed.

### **ERD (text)**

users 1 ──── 1 carts 1 ──── \* cart\_items \* ──── 1 products  
  │                                                │  │  
  │ 1                                              │  └── 1 ──── 0..1 racket\_specs  
  │                                                │  
  \* orders 1 ──── \* order\_items \* ──── 0..1 ───────┘  
  │                                                │  
  └── \* wishlists \* ───────────────────────────── 1┘

categories 1 ──── \* products  
Index nên tạo: products(category\_id), products(brand), orders(user\_id, created\_at), cart\_items(cart\_id).

## **17\. SQLite Architecture**

**Bốn lớp code mỏng nằm trên SQLite; mỗi lớp có đúng một việc và chỉ gọi lớp ngay dưới nó.** Không interface, không abstract class, không DI framework — các object được tạo một lần trong main.dart và truyền qua MultiProvider.

![kiến trúc dữ liệu · 6 lớp từ UI xuống SQLite][image1]

kiến trúc dữ liệu · 6 lớp từ UI xuống SQLite

Luồng đi xuống là lời gọi hàm (async), luồng đi lên là Future trả về Model hoặc ném AppException; Provider bắt exception và chuyển thành status \= error \+ câu thông báo thân thiện.

**Ba luật kiểm tra trong code review:**

* Thấy db.query / rawQuery ngoài thư mục data/daos/ → yêu cầu sửa.  
* Thấy BuildContext, Navigator, SnackBar trong repository hoặc DAO → yêu cầu sửa.  
* Thao tác ghi nhiều bảng cùng lúc (đặt hàng, hủy đơn, lưu sản phẩm \+ spec) → phải nằm trong db.transaction ở repository; DAO nhận tham số DatabaseExecutor để chạy được cả trong và ngoài transaction.

**Session không nằm trong SQLite:** SessionService bọc SharedPreferences (isLoggedIn, userId), được AuthRepository gọi khi login/logout và Splash đọc khi mở app.

## **18\. Local Image Architecture**

**Ảnh là asset đóng gói trong app; SQLite chỉ lưu đường dẫn chuỗi, UI hiển thị bằng Image.asset(product.imagePath).** Không BLOB, không tải mạng.

assets/  
  images/  
    brand/        logo\_smashly.png, logo\_mark.png  
    banners/      hero\_astrox99.png  
    categories/   rackets.png, shoes.png, ... (10 icon)  
    brands/       yonex.png, victor.png, lining.png, mizuno.png  
    products/  
      rackets/    racket\_yonex\_astrox99pro.png ...  
      shoes/      shoe\_yonex\_65z3.png ...  
      apparel/    shirt\_victor\_t40000.png, short\_lining\_aaps.png, socks\_yonex\_19120.png  
      bags/  grips/  strings/  nets/  accessories/  
    states/       empty\_cart.png, empty\_search.png, empty\_orders.png, error.png  
  fonts/          PlusJakartaSans-\*.ttf, Inter-\*.ttf

* **Quy ước tên file:** \<loại\>\_\<brand\>\_\<model\>.png, chữ thường, gạch dưới, không dấu, không khoảng trắng. Tên file \= định danh, nên hai người không thể vô tình tạo trùng.  
* **Chuẩn ảnh:** PNG nền trong suốt, vuông 800×800, sản phẩm chiếm \~80% khung, mỗi file ≤ 200 KB (nén bằng TinyPNG). Đồng nhất nền là thứ làm lưới sản phẩm trông "thương mại" nhất.  
* **pubspec.yaml khai báo theo thư mục, không theo file** (\- assets/images/products/rackets/) để thêm ảnh không phải sửa pubspec — giảm conflict.  
* **Hằng số đường dẫn** cho ảnh dùng chung (logo, empty state) nằm trong core/constants/app\_assets.dart; ảnh sản phẩm chỉ đến từ DB.  
* **Ảnh thiếu/sai đường dẫn:** mọi chỗ hiển thị dùng ProductImage widget có errorBuilder → icon cầu lông xám trên nền nhạt, để app không bao giờ hiện khung lỗi đỏ khi demo.  
* **Admin chọn ảnh:** form hiển thị lưới các asset có sẵn (danh sách lấy từ AssetManifest hoặc một const list trong app\_assets.dart). Upload ảnh từ thư viện máy là NICE — nếu làm thì copy file vào thư mục documents bằng path\_provider và lưu đường dẫn file, phân biệt bằng tiền tố file://.  
* **Nguồn ảnh:** tự chụp, ảnh có license miễn phí, hoặc ảnh báo chí của hãng dùng cho mục đích học tập; không dùng ảnh có watermark của shop khác.

## **19\. Flutter Architecture**

**State management: Provider (ChangeNotifier \+ MultiProvider).** Đây là lựa chọn ít khái niệm mới nhất, được tài liệu chính thức của Flutter dùng làm ví dụ, và đủ cho app có 6–7 nhóm state.

| Tiêu chí | Provider | Riverpod | Bloc | GetX |
| :---- | :---- | :---- | :---- | :---- |
| Khái niệm cần học | ChangeNotifier, notifyListeners, context.watch/read | Provider types, ref, code gen tùy chọn | Event, State, Bloc, Stream | Controller, .obs, routing, DI riêng |
| Boilerplate cho một feature | Thấp | Trung bình | Cao (3 file/feature) | Rất thấp |
| Thời gian để cả nhóm dùng được | \~1 ngày | 3–4 ngày | 4–5 ngày | \~1 ngày |
| Dễ debug, dễ giải thích khi vấn đáp | Cao | Trung bình | Cao | Thấp (nhiều "phép màu") |
| Rủi ro với nhóm 5 người, 4 tuần | **Thấp** | Trung bình | Cao | Trung bình — thường bị giảng viên hỏi vặn vì trộn navigation/DI/state |

**Danh sách Provider (7):** AuthProvider (user hiện tại, login/register/logout), HomeProvider, ShopProvider (giữ ProductQuery \+ kết quả), ProductDetailProvider, CartProvider (toàn app — badge), OrderProvider, AdminProductProvider. CartProvider và AuthProvider đặt ở gốc app; các provider của từng màn tạo bằng ChangeNotifierProvider ngay tại route đó để tự hủy khi rời màn.

**Mẫu state cho mọi màn:** mỗi provider có ViewStatus status (initial / loading / success / empty / error) \+ String? errorMessage. Màn hình chỉ switch trên status để chọn LoadingState, EmptyState, ErrorState hay nội dung — 5 người viết theo cùng một khuôn.

**Luồng code ví dụ — "Thêm vào giỏ":**

1. ProductDetailScreen: nút gọi context.read\<CartProvider\>().addToCart(productId, qty, size).  
2. CartProvider.addToCart → bật loading, gọi CartRepository.addItem(userId, productId, qty, size).  
3. CartRepository.addItem → kiểm tra stock qua ProductDao.findById, rồi gọi CartDao.upsertItem(...); nếu vượt stock thì throw AppException('Chỉ còn 3 sản phẩm').  
4. CartDao.upsertItem → chạy SQL INSERT ... ON CONFLICT(cart\_id, product\_id, size) DO UPDATE SET quantity \= quantity \+ excluded.quantity.  
5. Quay ngược lại: provider đọc lại giỏ (CartRepository.getCart), cập nhật items, notifyListeners() → badge nảy, SnackBar hiện.

**Navigation:** MaterialApp với named routes \+ onGenerateRoute trong một file app\_routes.dart. Bottom nav là AppShell dùng IndexedStack (giữ vị trí cuộn của từng tab). Không dùng go\_router — thêm một thứ cần học mà không cần deep link.

**Package (chốt danh sách ngay tuần 1):** provider, sqflite, path, shared\_preferences, crypto (hash), intl (định dạng tiền/ngày). Tùy chọn: flutter\_animate (micro-animation gọn), shimmer (skeleton). path\_provider chỉ cần nếu làm upload ảnh (NICE).

## **20\. Folder Structure**

**Cấu trúc lai: phần dữ liệu chia theo lớp (data/), phần giao diện chia theo feature (features/).** Lớp dữ liệu nhỏ và dùng chung nên gom một chỗ cho dễ tìm; màn hình chia theo feature để mỗi người làm việc trong thư mục của mình, giảm conflict Git đáng kể so với gom hết vào một screens/.

lib/  
├── main.dart                     \# khởi tạo DB, MultiProvider, runApp  
├── app.dart                      \# MaterialApp: theme, routes, initialRoute \= splash  
│  
├── core/  
│   ├── constants/                \# app\_assets.dart, app\_strings.dart, enums.dart (OrderStatus, Role...)  
│   ├── theme/                    \# app\_colors.dart, app\_text\_styles.dart, app\_spacing.dart, app\_theme.dart  
│   ├── database/  
│   │   ├── database\_helper.dart  \# singleton, open/onCreate/onUpgrade/onConfigure  
│   │   ├── db\_schema.dart        \# toàn bộ CREATE TABLE \+ index, DB\_VERSION  
│   │   └── seed/                 \# seed\_users.dart, seed\_catalog.dart, seed\_orders.dart, seed\_demo\_data.dart  
│   ├── services/                 \# session\_service.dart (SharedPreferences)  
│   └── utils/                    \# currency\_formatter.dart, validators.dart, password\_hasher.dart, app\_exception.dart  
│  
├── data/  
│   ├── models/                   \# user.dart, category.dart, product.dart, racket\_spec.dart, cart\_item.dart, order.dart, order\_item.dart, product\_query.dart  
│   ├── daos/                     \# user\_dao.dart, product\_dao.dart, cart\_dao.dart, order\_dao.dart, wishlist\_dao.dart  
│   └── repositories/             \# auth\_repository.dart, product\_repository.dart, cart\_repository.dart, order\_repository.dart  
│  
├── providers/                    \# auth\_provider.dart, cart\_provider.dart, shop\_provider.dart, ...  
│  
├── routes/  
│   └── app\_routes.dart           \# tên route \+ onGenerateRoute  
│  
├── shared/  
│   └── widgets/                  \# buttons/, inputs/, product\_card.dart, price\_text.dart, rating\_view.dart,  
│                                 \# states/ (loading\_state, empty\_state, error\_state), app\_dialog.dart, badges.dart  
│  
└── features/  
    ├── auth/        splash\_screen.dart, login\_screen.dart, register\_screen.dart, widgets/  
    ├── shell/       app\_shell.dart (bottom nav)  
    ├── home/        home\_screen.dart, widgets/ (hero\_banner, play\_style\_section, ...)  
    ├── shop/        shop\_screen.dart, widgets/ (filter\_sheet, recent\_searches, ...)  
    ├── product/     product\_detail\_screen.dart, widgets/ (spec\_card, spec\_meter, ...)  
    ├── cart/        cart\_screen.dart, widgets/  
    ├── checkout/    checkout\_screen.dart, order\_success\_screen.dart, widgets/  
    ├── orders/      my\_orders\_screen.dart, order\_detail\_screen.dart, widgets/ (order\_timeline, ...)  
    ├── profile/     profile\_screen.dart  
    └── admin/       admin\_dashboard\_screen.dart, admin\_products\_screen.dart, admin\_product\_form\_screen.dart, widgets/  
**Quy tắc đi kèm:**

* Widget chỉ dùng trong một feature → features/\<feature\>/widgets/. Dùng từ 2 feature trở lên → chuyển lên shared/widgets/ qua PR.  
* Không file nào trong features/ được import 'package:sqflite/...'. Có thể kiểm tra nhanh bằng tìm kiếm trước khi merge.  
* Một file một class công khai; tên file snake\_case, tên class PascalCase, màn hình kết thúc bằng Screen.  
* .gitignore thêm \*.db, \*.db-journal.

## **21\. Design System**

**Toàn bộ màu, chữ, khoảng cách nằm trong core/theme/ và được dùng qua token; trong code màn hình không được viết Color(0xFF...) hay fontSize: 17.** Đây là cách duy nhất để 5 người làm ra một app trông như một người làm.

### **Colors**

| Token | Hex | Dùng cho |
| :---- | :---- | :---- |
| primary — Smash Blue | \#1F4BFF | CTA chính, link, tab đang chọn, viền focus |
| primaryDark | \#1636C7 | Trạng thái nhấn của nút |
| primarySoft | \#E8EDFF | Nền chip đang chọn, nền icon |
| accentVolt | \#C6F23A | Chỉ badge nhỏ trên nền tối (NEW, \-15%) |
| midnight | \#0B1220 | Nền hero, Splash, header Login, header Admin |
| navy | \#16213A | Điểm cuối gradient hero |
| ink | \#0F172A | Chữ chính |
| inkMuted | \#64748B | Chữ phụ, caption |
| background | \#F5F7FB | Nền màn hình |
| surface | \#FFFFFF | Card, sheet |
| productTile | \#EEF2F7 | Nền sau ảnh sản phẩm |
| border | \#E2E8F0 | Viền ô nhập, divider |
| success / warning / error / info | \#16A34A / \#F59E0B / \#DC2626 / \#0EA5E9 | Trạng thái, luôn đi kèm icon \+ chữ |

Gradient duy nhất của app: midnight → navy (góc 135°). Chữ ink trên background đạt contrast \~16:1; chữ trắng trên primary \~6:1 — đều vượt mức AA 4.5:1.

### **Typography**

Font đóng gói trong assets/fonts/ (không phụ thuộc mạng khi demo): **Plus Jakarta Sans** cho tiêu đề và giá (hình khối thể thao, hiện đại), **Inter** cho nội dung (rất dễ đọc ở cỡ nhỏ).

| Style | Font / weight | Size / line height | Dùng cho |
| :---- | :---- | :---- | :---- |
| display | Jakarta 800 | 32 / 38 | Tên hero, Order Success |
| h1 | Jakarta 700 | 24 / 30 | Tiêu đề màn hình |
| h2 | Jakarta 700 | 20 / 26 | Tiêu đề section |
| subtitle | Inter 600 | 16 / 22 | Tên sản phẩm ở Detail, tiêu đề card |
| body | Inter 400 | 14 / 20 | Nội dung, mô tả |
| caption | Inter 500 | 12 / 16 | Brand, ngày, nhãn phụ |
| button | Jakarta 700 | 15 / 20 | Mọi nút |
| price | Jakarta 800, tabularFigures | 16–24 | Giá (chữ số thẳng hàng) |

### **Spacing, radius, elevation**

* **Spacing (lưới 4):** xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32. Lề màn hình 16; khoảng giữa section 24\.  
* **Radius:** sm 8 (chip, ô nhỏ) · md 12 (ô nhập, nút) · lg 16 (card) · xl 24 (sheet, hero).  
* **Shadow:** 1 mức duy nhất cho card — 0 4 16 rgba(15,23,42,0.06). Không chồng nhiều lớp bóng.  
* **Touch target:** tối thiểu 48×48; nút chính cao 52–56.

### **Components dùng chung**

| Component | Biến thể / API chính | Ghi chú |
| :---- | :---- | :---- |
| SmashAppBar | title, actions, transparent cho Detail | Back luôn ở trái, cỡ 48 |
| PrimaryButton / SecondaryButton / TextLinkButton | isLoading, icon, expanded | Co 0.97 khi nhấn; loading thay chữ bằng spinner, giữ nguyên kích thước |
| AppTextField | label, hint, validator, obscure \+ toggle, prefix icon | Lỗi đỏ dưới ô, kèm icon |
| ProductCard | grid / horizontal | Ảnh 1:1, brand, tên 2 dòng, rating, giá, tim |
| CategoryCard | icon \+ tên | Vuông 72, nền primarySoft khi chọn |
| PriceText | price, originalPrice, size | Định dạng 2.890.000₫, giá gốc gạch ngang \+ % giảm |
| RatingView | rating, count, compact | ★ 4.8 (128) |
| SmashSearchBar | readOnly (Home) / thật (Shop) | Nút X khi có chữ |
| SmashFilterChip | selected, icon, count | Chọn \= nền primarySoft \+ viền primary \+ icon check |
| AppBottomNav | 5 tab, badge Cart | Icon \+ nhãn luôn hiện |
| EmptyState / LoadingState / ErrorState | illustration, title, message, CTA | Bắt buộc dùng ở mọi màn có dữ liệu |
| AppDialog | confirm, destructive | Nút hành động nguy hiểm màu đỏ, nằm bên phải |
| StatusBadge / StockBadge / PromoBadge | theo enum | Icon \+ chữ \+ màu |
| QuantityStepper | min, max, value | Nút 40×40, số ở giữa có animation |

**Widget Catalog (khuyến nghị mạnh):** một màn debug ẩn hiển thị tất cả component ở mọi trạng thái. TV3 làm tuần 1; cả nhóm nhìn vào đó thay vì tự chế component mới.

## **22\. Animation Strategy**

**Mọi animation phải trả lời câu hỏi "người dùng hiểu thêm điều gì?" — phản hồi một thao tác, cho biết đã chuyển đi đâu, hoặc cho biết hệ thống đang làm việc.** Không có animation chạy liên tục, không có animation chặn thao tác.

**Thông số chuẩn (đặt trong core/theme/app\_motion.dart):**

| Token | Thời lượng | Curve | Dùng cho |
| :---- | :---- | :---- | :---- |
| fast | 150 ms | easeOut | Nhấn nút, đổi màu chip, checkbox |
| normal | 250 ms | easeOutCubic | Đổi số lượng, đổi nội dung, AnimatedSwitcher |
| page | 320 ms | easeOutCubic | Chuyển màn, mở sheet |
| emphasis | 600 ms | easeOutBack | Badge nảy, check thành công, đếm số dashboard (dùng ít) |

| Mức | Animation | Kỹ thuật Flutter (built-in trước) | Owner |
| :---- | :---- | :---- | :---- |
| MUST | Phản hồi nhấn nút (co 0.97) | AnimatedScale trong PrimaryButton | TV3 |
| MUST | Chuyển màn | PageRouteBuilder fade \+ trượt 8% từ phải, dùng chung trong app\_routes.dart | TV3 |
| MUST | Loading skeleton | shimmer hoặc AnimatedOpacity lặp trên khối xám | TV2 |
| MUST | Badge giỏ cập nhật | AnimatedScale \+ AnimatedSwitcher cho con số | TV4 |
| SHOULD | Tim yêu thích | TweenSequence scale 1 → 1.3 → 1 \+ đổi màu | TV2 |
| SHOULD | Hero ảnh sản phẩm Card → Detail | Hero(tag: 'product-\${id}') | TV3 |
| SHOULD | Thêm vào giỏ | Nút đổi thành ✓ "Đã thêm" 800 ms | TV3 |
| SHOULD | Đổi số lượng | AnimatedSwitcher \+ SlideTransition dọc | TV4 |
| SHOULD | Xóa item giỏ | AnimatedList thu gọn \+ fade | TV4 |
| SHOULD | Timeline đơn tô dần | TweenAnimationBuilder lệch nhau 120 ms | TV3 |
| SHOULD | Section Home xuất hiện lệch nhau | flutter\_animate .fadeIn().slideY() delay 60 ms/section, chỉ lần đầu | TV2 |
| NICE | Check thành công đặt hàng | CustomPainter vẽ nét hoặc Lottie local | TV4 |
| NICE | Đếm số Dashboard | TweenAnimationBuilder\<int\> | TV5 |
| NICE | Ảnh sản phẩm parallax nhẹ khi cuộn Detail | Transform.translate theo ScrollController | TV3 |

**Luật:**

* Không quá 1 animation "emphasis" trên một màn tại một thời điểm.  
* Danh sách dài không animate từng item khi cuộn — chỉ animate lần tải đầu.  
* Tôn trọng cài đặt giảm chuyển động: nếu MediaQuery.of(context).disableAnimations là true, dùng Duration.zero.  
* Kiểm tra trên máy thật Android tầm trung ở chế độ \--profile; khung hình nào giật thì cắt animation đó trước khi tối ưu.

## **23\. Customer User Flow**

**Từ Home đến đơn hàng thành công chỉ có 5 lần chuyển màn (Home → Shop → Detail → Cart → Checkout → Success); không có bước nào dư thừa.** Checkout là bước duy nhất ghi nhiều bảng cùng lúc nên được tô nổi.

![luồng khách hàng · 12 màn, 1 nhánh role][image2]

luồng khách hàng · 12 màn, 1 nhánh role

Người dùng có thể đi tắt: tap sản phẩm ngay ở Home để vào thẳng Detail, hoặc vào Cart từ tab bất cứ lúc nào.

### **Customer Journey Review**

| Bước | Biết mình đang ở đâu? | CTA / bước tiếp theo | Back | Điểm cần sửa đã xử lý |
| :---- | :---- | :---- | :---- | :---- |
| Splash | Logo \+ thanh tiến trình | Tự chuyển | Không quay lại được (pushReplacement) | Không để Splash \> 2 s |
| Login | Tiêu đề "Welcome back" | Nút Đăng nhập (duy nhất, nổi bật) \+ link Đăng ký | Thoát app | Lỗi chung chung để không lộ email tồn tại; không xóa chữ đã nhập khi lỗi |
| Register | Tiêu đề "Create your account" | Tạo tài khoản | Về Login | 5 ô là tối thiểu theo đề; bàn phím Next nhảy ô |
| Home | Tab Home sáng trên bottom nav | Hero "Khám phá", Play Style, sản phẩm | Thoát app (hỏi xác nhận nếu bấm Back 2 lần) | Không quá 7 section, tránh cuộn vô tận |
| Shop | Tab Shop \+ số kết quả "18 sản phẩm" | Tap sản phẩm | Tab trước | Filter đang áp dụng hiển thị thành chip để không "mất" sản phẩm mà không biết vì sao |
| Product Detail | Ảnh lớn \+ tên; AppBar trong suốt có Back | Thêm vào giỏ (cố định đáy) | Về đúng vị trí cuộn trước đó | Thuật ngữ có giải thích; một CTA duy nhất |
| Cart | Tiêu đề "Giỏ hàng (3)" | Mua hàng (số món) | Tab trước | Chọn/bỏ chọn dễ hiểu; Undo khi xóa nhầm |
| Checkout | Tiêu đề "Thanh toán" \+ 3 card | Đặt hàng · số tiền | Về Cart, giữ nguyên lựa chọn | Điền sẵn địa chỉ; ghi rõ "Demo" ở thanh toán mô phỏng |
| Order Success | Icon check \+ mã đơn | Xem đơn hàng | Về Home (không quay lại Checkout) | Chặn đặt hàng trùng |
| My Orders | Tab Orders | Tap đơn | Tab trước | Tab trạng thái có chữ, không chỉ màu |
| Order Detail | Mã đơn \+ badge | (Hủy đơn nếu Pending) | Về My Orders | Timeline giải thích đơn đang ở đâu mà không cần đọc chữ |

## **24\. Admin User Flow**

**Admin đi thẳng từ Login vào Dashboard, không có Register, không thấy giao diện mua sắm.** Mọi thao tác CRUD nằm trong 2 màn Products và Product Form.

![luồng admin · 3 màn, 1 quyết định xóa][image3]

luồng admin · 3 màn, 1 quyết định xóa

Từ Dashboard, admin còn có thể tap sản phẩm sắp hết hàng để mở thẳng Product Form, đổi trạng thái đơn gần đây (SHOULD), và đăng xuất từ menu avatar.

**Kiểm tra quyền:** Splash và Login điều hướng theo role; ngoài ra mỗi màn admin kiểm tra authProvider.currentUser.role \== Role.admin trong initState và đưa về Login nếu sai — một dòng code, nhưng chứng minh được tư duy phân quyền khi vấn đáp.

## **25\. Team Assignment**

**Chia theo domain dọc: mỗi người sở hữu màn hình *và* DAO/repository/provider của domain đó.** Nhờ vậy ai cũng có phần SQLite thật để trình bày, và người viết query cũng là người dùng query.

Điểm tải \= độ khó màn hình (mục 6\) \+ shared tasks (1 điểm ≈ 1 ngày công). Mục tiêu: mỗi người 9–11 điểm. Gán người thật vào TV1–TV5 theo năng lực: **TV1** nên là người vững Dart/SQL nhất (kiêm leader kỹ thuật), **TV2** và **TV3** là hai người có mắt thẩm mỹ tốt nhất.

| Thành viên | Vai trò | Màn hình | Shared tasks | Điểm tải |
| :---- | :---- | :---- | :---- | :---- |
| **TV1** | Tech lead · Auth & Database | S01 Splash, S02 Login, S03 Register, S12 Profile | DatabaseHelper, db\_schema.dart, seed\_users, SessionService, PasswordHasher, validators, UserDao, AuthRepository, AuthProvider; setup repo \+ pubspec.yaml; review PR về DB | 6 \+ 4 \= **10** |
| **TV2** | Discovery · Home & Shop | S04 Home, S05 Shop (Listing \+ Search \+ Filter) | ProductDao (đọc \+ query động \+ count), ProductRepository (đọc), ProductQuery, HomeProvider, ShopProvider, ProductCard, CategoryCard, recent searches; Wishlist (SHOULD) | 9 \+ 2 \= **11** |
| **TV3** | Product & Experience · UI kit | S06 Product Detail, S10 My Orders, S11 Order Detail | **Design system** (core/theme/, app\_motion), shared widgets (buttons, inputs, states, dialog, badges), Widget Catalog, AppShell \+ app\_routes.dart \+ page transition, SpecCard/SpecMeter, OrderTimeline | 9 \+ 3 \= **12** → TV4 hỗ trợ OrderDao đọc |
| **TV4** | Purchase · Cart & Checkout | S07 Cart, S08 Checkout, S09 Order Success | CartDao, CartRepository, CartProvider \+ badge, OrderDao, OrderRepository.placeOrder (transaction), seed\_orders, CurrencyFormatter; tạo OrderDao.getByUser/getById cho TV3 | 7 \+ 3 \= **10** |
| **TV5** | Admin · Catalog & QA | S13 Admin Dashboard, S14 Admin Products, S15 Admin Product Form | ProductDao ghi (insert/update/delete/soft delete), AdminProductProvider, **seed\_catalog** (20 sản phẩm \+ specs) và **chuẩn hóa toàn bộ ảnh asset**; QA lead tuần 4: checklist test, ghi bug | 7 \+ 3 \= **10** |

**Vì sao chia như vậy:**

* TV2 chỉ có 2 màn hình nhưng là 2 màn nặng và lộ diện nhất (Home \+ Shop chiếm phần lớn thời gian demo); thêm màn thứ 3 sẽ kéo chất lượng Home xuống.  
* TV3 có tải cao nhất nhưng phần lớn shared task (design system, routes) dồn vào tuần 1, trước khi các màn hình của TV3 cần làm; My Orders/Order Detail rơi vào tuần 3 khi việc chung đã xong.  
* TV4 và TV5 cùng chạm products (trừ stock vs. CRUD) nhưng ở các hàm khác nhau trong ProductDao; TV2 sở hữu file, TV5 thêm phần ghi qua PR riêng.  
* Không ai "chỉ làm UI": cả 5 người đều có DAO \+ repository \+ ít nhất một thao tác ghi SQLite để tự trình bày khi vấn đáp.

**Cặp review chéo (mỗi PR cần 1 người duyệt):** TV1 ↔ TV4 (dữ liệu & transaction), TV2 ↔ TV3 (UI & design system), TV5 → TV1 (DB). Cặp cố định giúp người review hiểu ngữ cảnh.

## **26\. Git Workflow**

**Git Flow rút gọn: main (luôn demo được) ← develop (tích hợp) ← feature/\* (mỗi việc một nhánh, sống ≤ 3 ngày).** Squash merge vào develop; merge develop → main mỗi cuối tuần và gắn tag.

**Branch naming:** feature/\<tv\>-\<việc\>, fix/\<tv\>-\<lỗi\>, chore/\<việc\>. Ví dụ: feature/tv1-login, feature/tv2-filter-sheet, fix/tv4-cart-stock-limit, chore/update-seed-images.

**Commit convention (Conventional Commits):** \<type\>(\<scope\>): \<mô tả ngắn\> — type: feat, fix, refactor, style, chore, docs, test. Ví dụ: feat(cart): add swipe-to-delete with undo, fix(db): enable foreign keys in onConfigure.

**Pull Request:**

* Một PR \= một màn hình hoặc một phần việc nhỏ; mục tiêu \< 400 dòng thay đổi.  
* Mô tả PR có: việc đã làm, ảnh chụp màn hình (đủ 4 trạng thái nếu là màn hình), cách test, có đổi DB không.  
* Checklist trước khi mở PR: flutter analyze sạch · không có màu/size hard-code · không import sqflite trong features/ · chạy được sau khi xóa app cài lại.  
* Cần 1 approve từ cặp review (mục 25). PR đổi db\_schema.dart, pubspec.yaml, app\_theme.dart cần thêm approve của owner file đó.  
* Merge: **Squash and merge** vào develop, xóa nhánh sau khi merge.

**Nhịp tích hợp:** mỗi người git pull \--rebase origin develop mỗi sáng; tích hợp chính vào **thứ Tư và thứ Bảy**; mỗi Chủ nhật merge develop → main \+ tag v0.1, v0.2, v0.3, v1.0.

**Điểm nóng conflict và cách tránh:**

| File / vùng | Vì sao hay conflict | Quy tắc |
| :---- | :---- | :---- |
| pubspec.yaml | Ai cũng muốn thêm package; thứ tự asset | Chỉ TV1 sửa. Danh sách package chốt tuần 1; muốn thêm → nhắn nhóm, TV1 thêm. Asset khai báo theo thư mục |
| app\_routes.dart | Mọi màn đều thêm route | TV3 tạo sẵn **toàn bộ 15 route** ngày 2 (trỏ tới màn placeholder). Người làm màn chỉ thay placeholder bằng màn thật, không thêm dòng mới |
| core/theme/ | Ai cũng muốn "chỉnh chút màu" | Chỉ TV3 sửa; cần token mới → đề xuất trong PR của TV3 |
| db\_schema.dart \+ DB\_VERSION | Hai người cùng thêm cột | Chỉ TV1 sửa; schema chốt hết tuần 1\. Đổi sau đó phải tăng DB\_VERSION và báo cả nhóm |
| assets/ | Trùng tên file, file nặng | Quy ước tên mục 18; TV5 là người duy nhất commit ảnh sản phẩm |
| Seed data | Cùng sửa một file seed lớn | Tách 3 file: seed\_users (TV1), seed\_catalog (TV5), seed\_orders (TV4); seed\_demo\_data.dart chỉ gọi lần lượt 3 hàm |
| main.dart (MultiProvider) | Ai cũng thêm provider | TV1 khai báo sẵn danh sách provider gốc tuần 1; provider theo màn tạo ở route, không thêm vào main.dart |

## **27\. Development Workflow with Separate SQLite Per Member**

**Code tạo database là thứ được chia sẻ; file database thì không.** Mỗi máy tự sinh DB của riêng mình từ cùng một db\_schema.dart và cùng một seedDemoData(), nên dữ liệu khởi đầu luôn giống nhau dù trong lúc dev mỗi người thêm/xóa dữ liệu khác nhau.

**Git chia sẻ:** db\_schema.dart (CREATE TABLE \+ DB\_VERSION) · database\_helper.dart · seed/\*.dart · DAO · repository · model. **Git không chia sẻ:** \*.db, \*.db-journal (đã ignore).

**Vòng đời DB trên mỗi máy:**

// database\_helper.dart (rút gọn)  
Future\<Database\> \_open() async {  
  final path \= join(await getDatabasesPath(), 'smashly.db');  
  return openDatabase(  
    path,  
    version: DbSchema.version,  
    onConfigure: (db) \=\> db.execute('PRAGMA foreign\_keys \= ON'),  
    onCreate: (db, v) async {  
      for (final sql in DbSchema.createStatements) { await db.execute(sql); }  
      await seedDemoData(db);              // chỉ chạy khi DB mới được tạo  
    },  
    onUpgrade: (db, oldV, newV) async {   // giai đoạn dev: xóa và tạo lại  
      for (final t in DbSchema.tablesInDropOrder) { await db.execute('DROP TABLE IF EXISTS \$t'); }  
      for (final sql in DbSchema.createStatements) { await db.execute(sql); }  
      await seedDemoData(db);  
    },  
  );  
}

Future\<void\> resetDatabase() async { /\* close \+ deleteDatabase(path) \+ \_open() \*/ }  
**Quy trình khi schema thay đổi (sau tuần 1, hạn chế tối đa):**

1. TV1 sửa db\_schema.dart, tăng DB\_VERSION, cập nhật seed nếu cần, mở PR có nhãn **DB-CHANGE**.  
2. Sau merge, TV1 báo nhóm. Mỗi người pull về và chạy lại app — onUpgrade tự xóa và tạo lại DB.  
3. Ai gặp lỗi lạ: bấm "Reset demo data" trong Profile (chỉ hiện ở debug) hoặc gỡ app cài lại.

**Vì sao drop-and-recreate được chấp nhận:** dữ liệu dev không có giá trị cần giữ. Khi nộp bài nên nói rõ với giảng viên: bản thật sẽ viết migration ALTER TABLE theo từng version — điểm hiểu biết, không phải điểm thiếu sót.

**Kiểm tra dữ liệu trong lúc dev:** dùng Database Inspector của Android Studio (App Inspection) hoặc DB Browser for SQLite với file kéo từ máy ảo — chỉ để xem, không commit.

**Quy trình demo trên điện thoại:** gỡ bản cũ → cài bản build từ main → mở app → Splash tạo DB, tạo bảng, seed admin, customer, 20 sản phẩm, 4 đơn mẫu → chạy demo. Kiểm tra lại toàn bộ luồng này vào ngày tổng duyệt.

## **28\. Demo Data Strategy**

**Seed 3 tài khoản, 10 danh mục, 22 sản phẩm và 4 đơn mẫu — mỗi bản ghi được chọn để làm sáng một màn hình hoặc một trạng thái cụ thể khi demo.** Seed chạy trong một transaction (db.batch()), chỉ ở onCreate, nên không bao giờ bị nhân đôi.

### **Tài khoản**

| Email | Mật khẩu | Role | Dùng để demo |
| :---- | :---- | :---- | :---- |
| admin@smashly.com | Admin@123 | ADMIN | Dashboard, CRUD |
| customer@smashly.com | Customer@123 | CUSTOMER | Luồng mua chính; có sẵn 4 đơn \+ 1 món trong giỏ |
| newbie@smashly.com | Newbie@123 | CUSTOMER | Empty state: giỏ trống, chưa có đơn |

Demo Register bằng một email mới (ví dụ lan@smashly.com) ngay trên sân khấu.

### **Sản phẩm (22)**

Giá là giá demo (VND) và thông số vợt là giá trị tham khảo — TV5 đối chiếu trang chính thức của hãng trước khi seed.

| \# | Sản phẩm | Danh mục | Giá demo | Ghi chú cho demo |
| :---- | :---- | :---- | :---- | :---- |
| 1 | Yonex Astrox 99 Pro | Rackets | 4.290.000 | **Featured / hero**; 4U · Head Heavy · Stiff · Advanced · Attack |
| 2 | Yonex Astrox 77 Pro | Rackets | 3.690.000 | Head Heavy · Medium · Intermediate · Attack; giảm giá 10% |
| 3 | Yonex Nanoflare 800 Pro | Rackets | 4.190.000 | Head Light · Stiff · Advanced · Control; **stock 3 (sắp hết)** |
| 4 | Yonex Arcsaber 11 Pro | Rackets | 4.090.000 | Even · Stiff · Advanced · Control |
| 5 | Yonex Astrox 01 Ability | Rackets | 890.000 | Beginner · Flexible — cho filter "Mới chơi" |
| 6 | Victor Thruster Ryuga II | Rackets | 3.590.000 | Featured; Head Heavy · Stiff · Attack |
| 7 | Victor Auraspeed 90K II | Rackets | 3.490.000 | Head Light · Stiff · All-round |
| 8 | Li-Ning Axforce 80 | Rackets | 3.390.000 | Head Heavy · Stiff · Attack; **stock 0 (hết hàng)** |
| 9 | Li-Ning Halbertec 8000 | Rackets | 3.190.000 | Even · Medium · Intermediate · All-round |
| 10 | Yonex Power Cushion 65 Z3 | Shoes | 2.590.000 | Featured; sizes 39–44 |
| 11 | Victor A970 Ace | Shoes | 2.290.000 | Sizes 39–44; giảm giá 15% |
| 12 | Mizuno Wave Fang Pro | Shoes | 2.690.000 | Sizes 40–44 |
| 13 | Yonex Game Shirt | Shirts | 590.000 | Sizes S–XL |
| 14 | Li-Ning Training Tee | Shirts | 450.000 | Sizes S–XL |
| 15 | Victor Game Shorts | Shorts | 390.000 | Sizes S–XL |
| 16 | Yonex Sport Socks (3 đôi) | Socks | 150.000 |  |
| 17 | Yonex Pro Racquet Bag 6 cây | Bags | 1.890.000 | Featured |
| 18 | Victor Backpack | Bags | 1.190.000 | **stock 4 (sắp hết)** |
| 19 | Yonex Super Grap (3 cuộn) | Grips | 150.000 | Món có sẵn trong giỏ customer |
| 20 | Yonex BG66 Ultimax | Strings | 220.000 |  |
| 21 | Li-Ning Tournament Net | Nets | 690.000 |  |
| 22 | Yonex Aerosensa 30 (ống 12 quả) | Accessories | 750.000 | Giảm giá 5% |

Phủ đủ 4 thương hiệu, 10 danh mục, giá từ 150.000 đến 4.290.000 (RangeSlider có ý nghĩa), rating trải từ 4.1 đến 4.9 (filter rating có ý nghĩa), đủ 4 lối chơi và 3 trình độ.

### **Đơn hàng mẫu của customer@smashly.com**

| Mã đơn | Trạng thái | Thời điểm | Nội dung |
| :---- | :---- | :---- | :---- |
| SML-…-0001 | DELIVERED | 14 ngày trước | Astrox 77 Pro \+ BG66 — timeline đủ 4 bước |
| SML-…-0002 | SHIPPING | 3 ngày trước | Power Cushion 65 Z3 (size 42\) |
| SML-…-0003 | CONFIRMED | Hôm qua | Game Shirt × 2 |
| SML-…-0004 | CANCELLED | 7 ngày trước | Astrox 01 Ability — nhánh hủy màu đỏ |

Ngày đơn mẫu tính tương đối theo DateTime.now() lúc seed, để demo vào ngày nào cũng trông "mới". Đơn đặt trực tiếp khi demo sẽ là PENDING — đủ cả 5 trạng thái.

## **29\. 4-Week Roadmap**

**Mỗi Chủ nhật có một bản trên main chạy được từ đầu đến cuối phần đã làm; tích hợp vào thứ Tư và thứ Bảy từ tuần 1\.** Code freeze thứ Năm 29/10; từ đó chỉ sửa bug.

![lộ trình 4 tuần · 4 mốc phát hành][image4]

lộ trình 4 tuần · 4 mốc phát hành

Ngày được tính từ tuần này; nếu ngày thuyết trình khác 01/11, dời toàn bộ mốc theo cùng số ngày.

| Tuần | TV1 · Auth & DB | TV2 · Home & Shop | TV3 · Product & UI kit | TV4 · Cart & Checkout | TV5 · Admin & Catalog |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **1** (05–11/10) | Repo, pubspec, DatabaseHelper, schema 9 bảng, seed\_users, SessionService, AuthRepository; S01, S02, S03 | Phác Home; ProductDao đọc, ProductQuery; ProductCard, CategoryCard | Theme \+ motion tokens, shared widgets, 4 state widget, 15 route placeholder, AppShell, Widget Catalog | Model Cart/Order, CurrencyFormatter, CartDao \+ CartRepository (thêm/đọc) | Chốt 22 sản phẩm, chụp/lấy ảnh, seed\_catalog bản 1 |
| **2** (12–18/10) | S12 Profile \+ logout; hỗ trợ review DB; validators hoàn chỉnh | **S04 Home** hoàn chỉnh; S05 Shop: listing \+ chip danh mục \+ search | **S06 Product Detail** \+ SpecCard, SpecMeter, Hero; page transition | Hoàn thiện CartRepository (số lượng, chọn, xóa), CartProvider \+ badge; bắt đầu S07 | Ảnh chuẩn hóa 800×800; ProductDao ghi; bắt đầu S14 |
| **3** (19–25/10) | Forgot password (NICE nếu dư); viết test repository; hỗ trợ tích hợp | S05 Filter sheet \+ sort \+ recent searches \+ empty state | S10 My Orders, S11 Order Detail \+ timeline | S07 Cart xong, **S08 Checkout transaction**, S09, seed\_orders | S13 Dashboard, S14, **S15 Form** (transaction 2 bảng) |
| **4** (26/10–01/11) | Kiểm tra luồng cài mới \+ seed; README | Wishlist (SHOULD); polish Home | Rà soát UI toàn app; animation SHOULD; hủy đơn | Animation giỏ/checkout; size trong giỏ (SHOULD) | **QA lead**: checklist test, đổi trạng thái đơn (SHOULD); slide demo |

**Ngày quan trọng tuần 4:** 27/10 chốt SHOULD nào giữ · 29/10 code freeze \+ build v1.0-rc · 30/10 tổng duyệt lần 1 trên điện thoại demo · 31/10 sửa lỗi cuối, tổng duyệt lần 2, quay video dự phòng, tag v1.0.

## **30\. MVP / MUST / SHOULD / NICE**

**MVP \= mọi thứ MUST chạy trọn vẹn trên một điện thoại cài mới.** Thứ tự cắt khi trễ: NICE trước, rồi SHOULD theo thứ tự từ dưới lên của bảng SHOULD. Bốn thứ không bao giờ cắt: Login/Register, checkout transaction, Product CRUD, 4 trạng thái loading/empty/error/success.

| Mức | Hạng mục | Deadline mục tiêu |
| :---- | :---- | :---- |
| **MUST** | Splash \+ session, Login, Register (validate, email unique), Logout | Hết tuần 1 |
| **MUST** | Phân role Customer/Admin, admin seed sẵn | Hết tuần 1 |
| **MUST** | Home (Court Hero \+ Play Style), Shop (listing \+ search \+ filter \+ sort), Product Detail với spec trực quan | Hết tuần 2 |
| **MUST** | Cart SQLite (thêm, xóa, số lượng, chọn, chọn tất cả, tổng), Checkout transaction, Order Success | Giữa tuần 3 |
| **MUST** | My Orders, Order Detail \+ timeline | Hết tuần 3 |
| **MUST** | Admin Dashboard, Product CRUD (thêm, sửa, xóa có xác nhận) | Hết tuần 3 |
| **MUST** | SQLite \+ seed, ảnh local, design system, animation mức MUST | Xuyên suốt |
| SHOULD (giữ đến cuối) | Hero transition, add-to-cart animation, badge animation, quantity animation | Tuần 4 |
| SHOULD | Wishlist (tim \+ danh sách trong Profile) | Tuần 4 |
| SHOULD | Khách hủy đơn Pending (hoàn stock) | Tuần 4 |
| SHOULD | Admin đổi trạng thái đơn | Tuần 4 |
| SHOULD (cắt đầu tiên trong nhóm) | Size cho giày/áo trong giỏ và đơn | Tuần 4 |
| NICE | Forgot password local, đổi mật khẩu | Chỉ khi dư thời gian |
| NICE | Animation check thành công vẽ nét / Lottie, đếm số dashboard, parallax ảnh | Chỉ khi dư thời gian |
| NICE | Reviews, dark mode, upload ảnh từ thư viện, thống kê admin nâng cao | Không làm trong 4 tuần |

**Luật chống feature creep:** sau thứ Tư tuần 3, không thêm hạng mục mới nào ngoài bảng này. Ý tưởng mới ghi vào "Hướng phát triển" ở slide cuối.

## **31\. Risk Analysis**

**Ba rủi ro lớn nhất là kỹ năng Flutter không đều, tích hợp dồn cuối và UI lệch phong cách — cả ba đều được chặn từ tuần 1 bằng design system, route placeholder và lịch tích hợp 2 lần/tuần.**

| Rủi ro | Xác suất | Tác động | Giải pháp khi xảy ra | Phòng ngừa |
| :---- | :---- | :---- | :---- | :---- |
| Kỹ năng Flutter không đồng đều | Cao | Cao | Ghép người yếu với TV1/TV3 pair-programming 1 buổi; giao phần UI theo mẫu có sẵn | Tuần 1 làm chung 1 màn mẫu (Login) làm khuôn; Widget Catalog; mẫu ViewStatus dùng chung |
| Chỉ còn 4 tuần / trễ tiến độ | Cao | Cao | Cắt theo bảng mục 30, không cắt MUST | Mốc tích hợp hằng tuần; mỗi màn có ước lượng; standup 15 phút mỗi tối qua chat |
| Tích hợp dồn sang tuần 4 | Trung bình | Rất cao | Dừng tính năng mới 2 ngày để tích hợp | Tích hợp thứ Tư \+ thứ Bảy từ tuần 1; main luôn chạy được |
| Git / merge conflict | Cao | Trung bình | Người sở hữu file giải quyết conflict của file đó | Bảng điểm nóng mục 26; nhánh sống ≤ 3 ngày; pull rebase mỗi sáng |
| Conflict pubspec.yaml | Trung bình | Trung bình | TV1 sửa tay, chạy flutter pub get lại | Chỉ TV1 sửa; package chốt tuần 1; asset khai báo theo thư mục |
| Navigation conflict / route lẫn lộn | Trung bình | Trung bình | Gộp vào app\_routes.dart, test lại toàn bộ đường đi | 15 route tạo sẵn ngày 2; dùng hằng số tên route, không gõ chuỗi |
| UI không đồng nhất | Cao | Cao | TV3 rà soát UI mỗi thứ Bảy, mở PR sửa | Token bắt buộc; cấm hard-code màu/size; review chéo UI |
| Schema DB thay đổi giữa chừng | Trung bình | Cao | DB\_VERSION \+ drop-recreate \+ reset | Chốt schema hết tuần 1 (bản này đã có đủ cột cho SHOULD); mọi đổi phải qua TV1 |
| "SQLite conflict" (dùng chung file .db) | Thấp | Cao | Xóa .db khỏi repo, mỗi người tạo lại | \*.db trong .gitignore; tài liệu mục 27 |
| Feature creep | Cao | Trung bình | Đưa ý tưởng vào "Hướng phát triển" | Đóng băng phạm vi từ thứ Tư tuần 3 |
| Animation quá phức tạp / giật | Trung bình | Trung bình | Bỏ animation đó, giữ trạng thái tĩnh đẹp | Chỉ dùng built-in; token thời lượng; test trên máy thật ở \--profile |
| CRUD lỗi (xóa làm hỏng đơn, sửa mất spec) | Trung bình | Cao | Rollback bằng transaction, sửa và test lại | Snapshot ở order\_items; hard/soft delete theo mục 15; form ghi 2 bảng trong transaction; test case CRUD |
| Demo data thiếu / xấu | Trung bình | Cao | TV5 bổ sung seed trong 1 ngày | Danh sách 22 sản phẩm chốt tuần 1; ảnh chuẩn hóa tuần 2 |
| Lỗi trên máy demo (máy khác, DB cũ) | Trung bình | Rất cao | Gỡ cài lại; có video quay sẵn dự phòng | Tổng duyệt 2 lần trên đúng điện thoại demo; quay video luồng đầy đủ |
| Thành viên vắng/không hoàn thành | Thấp–TB | Cao | Người cùng cặp review nhận lại phần việc | Cặp review hiểu code của nhau; task nhỏ, PR nhỏ |

## **32\. Demo Script 7–10 Minutes**

**Kịch bản 9 phút, kể như một câu chuyện: "Minh — người mới chơi — mua cây vợt tấn công đầu tiên", rồi đổi vai sang admin.** Một người cầm máy (thao tác), một người dẫn chuyện; mỗi phần do owner của màn đó dẫn để cả 5 người đều xuất hiện.

| Thời gian | Màn hình / hành động | Lời dẫn chính | Điều chứng minh |
| :---- | :---- | :---- | :---- |
| 0:00–0:45 | Mở app vừa cài → Splash | "App vừa cài: Splash đang tạo SQLite, tạo 9 bảng, seed admin, khách hàng, 22 sản phẩm." | SQLite local, seed |
| 0:45–1:45 | Register tài khoản mới: thử email đã tồn tại → lỗi inline; confirm sai → lỗi; đăng ký thành công → về Login với email điền sẵn | "Validate ngay khi nhập, email unique, user mới luôn là CUSTOMER." | Register, validation |
| 1:45–2:15 | Login bằng customer@smashly.com (tài khoản có sẵn đơn) | "Mật khẩu được hash SHA-256; session lưu SharedPreferences." | Auth, session |
| 2:15–3:15 | Home: cuộn qua hero, danh mục, chạm "Tấn công" ở Shop by Play Style | "Người mới không cần biết thông số — chọn lối chơi." | UI premium, UX |
| 3:15–4:00 | Shop: đã lọc Attack; mở Filter thêm Yonex \+ giá ≤ 4,5 triệu (nút báo "Xem 2 sản phẩm"); gõ search "astrox"; xóa search | "Search, filter, sort cùng tác động một danh sách." | Search, filter |
| 4:00–5:00 | Tap Astrox 99 Pro (Hero transition) → giải thích Head Heavy, Stiff, 4U bằng spec card; mở (i) | "Mỗi thông số có câu giải thích cho người mới." | Product Detail UX, animation |
| 5:00–5:30 | Thêm vào giỏ (nút → ✓, badge nảy); thử tăng quá tồn kho | "Giỏ lưu SQLite, chặn vượt tồn kho." | Cart, animation |
| 5:30–6:15 | Cart: chọn/bỏ chọn món grip có sẵn, đổi số lượng, vuốt xóa \+ Undo → Mua hàng | "Tổng tiền cập nhật theo món được chọn." | Cart logic |
| 6:15–7:00 | Checkout: địa chỉ điền sẵn, chọn Ví điện tử (mô phỏng) → Đặt hàng → Order Success | "Một transaction: tạo đơn, lưu snapshot, trừ kho, xóa món đã mua khỏi giỏ." | Checkout, transaction |
| 7:00–7:45 | Xem đơn hàng → Order Detail (timeline Pending); quay về My Orders xem đơn Delivered và Cancelled | "5 trạng thái, timeline dùng icon \+ chữ, không chỉ màu." | Order flow |
| 7:45–8:00 | Profile → Đăng xuất (dialog) | "Logout xóa session." | Session |
| 8:00–9:00 | Login admin → Dashboard (low stock: Nanoflare 800 Pro còn 3, Victor Backpack còn 4; Axforce 80 hết hàng) → Products → Thêm sản phẩm mới (chọn ảnh, spec vợt) → Sửa giá → Xóa sản phẩm chưa có đơn (xóa thật) và thử xóa Astrox 99 Pro (đã có đơn → Ngừng bán) | "Đã bán thì không xóa cứng để giữ lịch sử đơn hàng." | CRUD, admin |
| 9:00–9:30 | (tùy thời gian) Đăng nhập lại customer → Astrox 99 Pro tồn kho đã giảm 1; sản phẩm Ngừng bán không còn trong Shop | "Dữ liệu nhất quán giữa hai vai trò." | Tích hợp |

**Chuẩn bị trước buổi demo:** cài bản v1.0 mới trên điện thoại đã sạc đầy; tắt thông báo; độ sáng cao; bật Show taps (Developer options) để khán giả thấy thao tác; giữ sẵn video quay toàn bộ luồng trên laptop nếu máy gặp sự cố. Tập đủ 2 lần, bấm giờ.

## **33\. PRM393 Lecturer Evaluation**

**Nếu làm đúng blueprint ở mức MUST, điểm dự kiến khoảng 8/10; lên 9 cần SHOULD \+ demo trơn tru; 10 đòi hỏi không có lỗi nào và trả lời vấn đáp vững về SQLite/kiến trúc.** "Điểm dự kiến" giả định MUST hoàn thành đầy đủ, SHOULD làm được khoảng một nửa.

| Tiêu chí | Dự kiến | Vì sao | Để đạt 8 | Để đạt 9 | Để đạt 10 |
| :---- | :---- | :---- | :---- | :---- | :---- |
| UI/UX | 8 | Hierarchy rõ, CTA cố định, 4 trạng thái mọi màn | Không màn nào dùng widget mặc định thô; empty state có CTA | Kiểm tra lại toàn bộ hành trình (mục 23), sửa mọi chỗ "khựng" | Người lạ dùng thử không cần hướng dẫn; mọi chuỗi tiếng Việt trau chuốt, không lỗi chính tả |
| Visual Design | 8 | Design system token, palette có kiểm soát | Không hard-code; ảnh sản phẩm đồng nhất nền | Hero, Detail, Order Success đạt mức "ảnh chụp được đưa vào portfolio" | Pixel-consistent mọi màn; dark spotlight dùng đúng chỗ; icon cùng bộ |
| Login/Register | 8 | Validate inline, hash, role, session | Đủ validation \+ lỗi thân thiện \+ loading | Password strength, giữ email sau đăng ký, chặn bấm 2 lần | Forgot password local \+ đổi mật khẩu; giải thích được vì sao hash |
| Ecommerce flow | 8 | Đủ luồng Home → Order Detail | Luồng không gãy, Back hợp lý | Wishlist, hủy đơn, size giày | Tồn kho nhất quán mọi nơi; mọi trường hợp biên (hết hàng giữa chừng) được xử lý |
| SQLite | 8.5 | 9 bảng, FK bật, transaction checkout, snapshot | CRUD thật trên mọi bảng chính | Index, CHECK constraint, transaction ở cả form admin và hủy đơn | Migration ALTER TABLE thật cho 1 version; giải thích được ON DELETE từng FK |
| CRUD | 8 | Admin thêm/sửa/xóa có xác nhận | Validation form, xác nhận xóa | Hard/soft delete theo ngữ cảnh, Undo | Search/filter trong admin, form không mất dữ liệu khi rời màn |
| Architecture | 8 | UI → Provider → Repository → DAO tách bạch | Không SQL trong widget | Mẫu ViewStatus thống nhất; feature folder | Vẽ và giải thích được luồng một thao tác qua mọi lớp; unit test cho repository |
| Animation | 7.5 | Có MUST \+ vài SHOULD | Đủ 4 MUST mượt | Hero, add-to-cart, badge, timeline | Mọi animation có mục đích, không giật trên máy tầm trung, tôn trọng reduce motion |
| User flow | 8 | Bottom nav quen thuộc, ít bước | Không ngõ cụt | Mọi màn có đường quay lại rõ ràng | Đặt hàng \< 60 giây với người lạ |
| Code quality | 7.5 | Có quy ước, nhưng 5 người viết | flutter analyze sạch, đặt tên rõ | Không trùng code; widget nhỏ; xử lý lỗi qua AppException | Có test (widget test cho form, unit test cho repository), README hướng dẫn chạy |
| Team collaboration | 8 | Git flow, PR, review chéo | Ai cũng có commit đều đặn | PR có mô tả \+ ảnh; lịch sử commit sạch | Mỗi người trả lời được câu hỏi về code của mình và của cặp |
| Demo | 8 | Kịch bản có cốt truyện | Demo không lỗi trong thời gian quy định | Mỗi thành viên dẫn phần của mình | Trả lời mọi câu hỏi "nếu… thì sao?" bằng cách thao tác trực tiếp trên app |

**Câu hỏi vấn đáp nên chuẩn bị:** Vì sao chọn Provider? Nếu xóa sản phẩm đã có trong đơn thì sao? Vì sao không lưu ảnh dạng BLOB? Checkout lỗi giữa chừng thì dữ liệu thế nào? Mỗi người một DB thì demo dữ liệu giống nhau bằng cách nào? Mật khẩu lưu ra sao?

## **34\. Final Recommendation**

**Làm 15 màn hình bằng Provider \+ sqflite, chốt schema và design system trong 5 ngày đầu, tích hợp 2 lần mỗi tuần, và dành trọn tuần 4 cho polish \+ demo.** Chất lượng của SMASHLY sẽ đến từ sự nhất quán và các chi tiết đúng chỗ, không phải từ số lượng tính năng.

Bảy việc cần làm ngay trong 3 ngày tới:

* ☐ TV1 tạo repo, nhánh main/develop, pubspec.yaml với đủ package, .gitignore có \*.db  
* ☐ Cả nhóm đọc mục 16 và chốt schema (họp 45 phút); TV1 viết db\_schema.dart \+ DatabaseHelper  
* ☐ TV3 tạo core/theme/ (màu, chữ, spacing, motion) và 15 route placeholder trong app\_routes.dart  
* ☐ TV5 chốt danh sách 22 sản phẩm, gom và chuẩn hóa ảnh 800×800 nền trong suốt  
* ☐ TV2 phác Home Court Hero trên Figma (hoặc giấy) để cả nhóm thống nhất "cảm giác" trước khi code  
* ☐ TV4 viết CurrencyFormatter \+ model CartItem, Order, OrderItem theo schema  
* ☐ Cả nhóm cùng làm màn Login như "màn mẫu" (pair với TV1) để học khuôn Provider \+ Repository \+ DAO

Nguyên tắc để quay lại mỗi khi phân vân: **UX \> Visual Effects · Usability \> Animation · Clarity \> Decoration · Consistency \> Complexity · Professionalism \> Excessive Effects.** Beautiful by default, simple by design, fast to understand, motion with purpose, premium without being excessive.

### **S06 — Product Detail**

*Customer · TV3 · độ khó 4 · MUST · 4 ngày*

* **Layout:** ảnh lớn 45% chiều cao trên nền xám rất nhạt (Hero từ card) → brand \+ tên → giá (giá gốc gạch ngang nếu có giảm) \+ rating → **Key Specs** (chi tiết ở mục 10\) → mô tả rút gọn 4 dòng \+ "Xem thêm" → tồn kho. Thanh CTA cố định ở đáy: chọn số lượng \+ nút "Thêm vào giỏ".  
* **Components:** SpecCard, SpecMeter (thanh 5 nấc), StockBadge, QuantityStepper, FavoriteButton, SizeSelector (chỉ hiện với giày/áo nếu products.sizes có giá trị).  
* **SQLite:** products \+ LEFT JOIN racket\_specs; cart\_items khi thêm giỏ (UPSERT: có rồi thì cộng số lượng, không vượt stock). **CRUD:** Read \+ Create/Update cart.  
* **Navigation:** Back về màn trước; sau khi thêm giỏ hiện SnackBar "Đã thêm · Xem giỏ".  
* **Animation:** Hero ảnh; nút đổi thành check 800 ms; badge giỏ nảy (scale 1→1.3→1).  
* **Loading:** skeleton phần thông tin, ảnh đã có nhờ Hero. **Empty:** sản phẩm bị ẩn/không tồn tại → "Sản phẩm không còn bán" \+ về Shop. **Error:** lỗi thêm giỏ → SnackBar đỏ. **Success:** hết hàng → nút disable "Hết hàng" (chữ \+ màu, không chỉ màu).

### **S07 — Cart**

*Customer · TV4 · độ khó 3 · MUST · 3 ngày*

* **Layout:** AppBar "Giỏ hàng (3)" \+ nút "Chọn tất cả" → danh sách item (checkbox, ảnh 72, tên 2 dòng, size, giá, stepper) → thanh tổng cố định đáy: "Tạm tính 4.580.000₫" \+ "Mua hàng (2)".  
* **Components:** CartItemTile, QuantityStepper, AppCheckbox, CheckoutBar.  
* **SQLite:** carts, cart\_items JOIN products (lấy giá, stock hiện tại). **CRUD:** Read, Update (quantity, is\_selected), Delete.  
* **Interaction:** vuốt trái để xóa (có Undo 4 s); stepper không cho \< 1 và \> stock; item hết hàng bị mờ, không chọn được, có nhãn "Hết hàng".  
* **Navigation:** "Mua hàng" → S08 (chỉ khi có ≥ 1 món được chọn).  
* **Animation:** item xóa thu gọn bằng AnimatedList; số tiền đổi bằng AnimatedSwitcher.  
* **Empty:** icon túi \+ "Giỏ hàng đang chờ một món thật xịn." \+ nút "Khám phá sản phẩm". **Error:** ErrorState. **Success:** cập nhật tổng tức thì.

### **S08 — Checkout**

*Customer · TV4 · độ khó 3 · MUST · 3 ngày*

* **Layout:** 3 card dọc: Thông tin nhận hàng (tên, SĐT, địa chỉ — điền sẵn từ users) → Phương thức thanh toán (3 radio card) → Tóm tắt đơn (món, tạm tính, phí ship, tổng). CTA đáy "Đặt hàng · 4.610.000₫".  
* **SQLite:** một **transaction**: kiểm tra stock → INSERT orders → INSERT order\_items (snapshot) → UPDATE products.stock → DELETE các cart\_items đã chọn. **CRUD:** Create \+ Update \+ Delete.  
* **Navigation:** thành công → S09 (pushReplacement, Back không quay lại Checkout).  
* **Animation:** radio card viền sáng khi chọn; nút loading.  
* **Error:** hết hàng giữa chừng → dialog "Astrox 99 Pro chỉ còn 1 sản phẩm" \+ quay về giỏ; form thiếu → lỗi inline. **Success:** S09.

### **S09 — Order Success**

*Customer · TV4 · độ khó 1 · MUST · 1 ngày*

* **Layout:** icon check lớn, "Đặt hàng thành công\!", mã đơn SML-20261005-0007, tổng tiền, phương thức. Hai nút: "Xem đơn hàng" (chính) và "Tiếp tục mua sắm".  
* **SQLite:** đọc orders theo id vừa tạo. **CRUD:** Read.  
* **Navigation:** "Xem đơn hàng" → S11; "Tiếp tục" → tab Home. Nút Back hệ thống → tab Home.  
* **Animation:** vòng tròn vẽ nét \+ check bật lên (CustomPainter hoặc Lottie local — NICE).

### **S10 — My Orders**

*Customer · TV3 · độ khó 2 · MUST · 2 ngày*

* **Layout:** TabBar cuộn ngang: Tất cả · Chờ xác nhận · Đã xác nhận · Đang giao · Đã giao · Đã hủy → danh sách OrderCard (mã đơn, ngày, badge trạng thái icon \+ chữ, ảnh món đầu \+ "và 2 sản phẩm khác", tổng).  
* **SQLite:** orders WHERE user\_id, kèm item đầu tiên và số item. **CRUD:** Read.  
* **Navigation:** tap → S11.  
* **Empty (theo tab):** "Chưa có đơn đang giao" \+ nút "Mua sắm ngay" (chỉ ở tab Tất cả). **Loading:** skeleton 3 card. **Error:** ErrorState.

### **S11 — Order Detail**

*Customer · TV3 · độ khó 3 · MUST · 2,5 ngày*

* **Layout:** header mã đơn \+ badge → **timeline dọc** 4 bước (Pending → Confirmed → Shipping → Delivered; đơn hủy thì hiện nhánh Cancelled màu đỏ) → card người nhận \+ địa chỉ → danh sách món (ảnh, tên, SL × đơn giá) → card thanh toán (tạm tính, ship, tổng, phương thức).  
* **SQLite:** orders, order\_items (dùng snapshot, không cần join products). **CRUD:** Read; Update status \= CANCELLED (SHOULD).  
* **Interaction (SHOULD):** đơn Pending có nút "Hủy đơn" → dialog xác nhận → transaction đổi status \+ cộng lại stock.  
* **Animation:** các bước timeline đã qua tô màu lần lượt 120 ms/bước khi mở màn.

### **S12 — Profile**

*Customer \+ Admin · TV1 · độ khó 1 · MUST · 1 ngày*

* **Layout:** avatar chữ cái đầu \+ tên \+ email \+ badge role → danh sách mục: Thông tin cá nhân (sửa tên, SĐT, địa chỉ mặc định — bottom sheet), Sản phẩm yêu thích (SHOULD), Đổi mật khẩu (NICE), **Đăng xuất** (màu đỏ, cuối danh sách). Ở bản debug thêm "Reset demo data".  
* **SQLite:** users (Read, Update), wishlists (Read). **SharedPreferences:** xóa session khi logout.  
* **Interaction:** logout có dialog xác nhận → xóa session → pushAndRemoveUntil về S02.  
* **Success:** sửa thông tin → SnackBar "Đã lưu". **Error:** lỗi validate inline.

### **S13 — Admin Dashboard**

*Admin · TV5 · độ khó 2 · MUST · 2 ngày*

* **Layout:** header "SMASHLY Admin" \+ avatar (tap → Profile/Logout) → lưới 4 thẻ số liệu (Tổng sản phẩm, Sắp hết hàng ≤ 5, Đơn chờ xác nhận, Doanh thu đơn đã giao) → "Sắp hết hàng" (danh sách ngắn, tap → S15) → "Đơn gần đây" (5 đơn; SHOULD: tap → bottom sheet đổi trạng thái) → nút lớn "Quản lý sản phẩm".  
* **SQLite:** COUNT, SUM trên products, orders. **CRUD:** Read; Update orders.status (SHOULD).  
* **Navigation:** Admin không có bottom nav của customer; dùng nút điều hướng rõ ràng tới S14.  
* **Animation:** số liệu đếm từ 0 lên (TweenAnimationBuilder, 600 ms, một lần).

### **S14 — Admin Products**

*Admin · TV5 · độ khó 2 · MUST · 2,5 ngày*

* **Layout:** ô search \+ chip lọc danh mục \+ chip "Đang ẩn" → danh sách dạng hàng (ảnh 56, tên, brand, giá, tồn kho có màu \+ chữ) → FAB "+ Thêm sản phẩm".  
* **SQLite:** products (Read), Delete (mục 15 giải thích hard/soft delete).  
* **Interaction:** tap hàng → S15 chế độ sửa; menu ⋮ → Sửa / Ẩn-Hiện / Xóa; Xóa luôn có dialog xác nhận nêu tên sản phẩm.  
* **Empty:** "Chưa có sản phẩm nào" \+ nút thêm. **Success:** SnackBar "Đã xóa Astrox 99 Pro" (+ Undo nếu là soft delete).

### **S15 — Admin Product Form (Add / Edit)**

*Admin · TV5 · độ khó 3 · MUST · 3 ngày*

* **Layout:** chọn ảnh từ danh sách asset có sẵn (lưới thumbnail theo danh mục) → Tên, Brand (dropdown \+ nhập mới), Danh mục, Giá, Giá gốc (tùy chọn), Tồn kho, Rating, Mô tả, Sizes (tùy chọn), switch Nổi bật. Khi danh mục \= Rackets mở thêm nhóm "Thông số vợt" (segmented button cho Weight/Balance/Shaft/Level/Style, số cho Max tension). Nút "Lưu" cố định đáy.  
* **SQLite:** INSERT/UPDATE products \+ racket\_specs trong **một transaction**. **CRUD:** Create, Read, Update.  
* **Validation:** tên bắt buộc; giá \> 0; stock ≥ 0; rating 0–5; ảnh bắt buộc.  
* **Interaction:** rời màn khi có thay đổi chưa lưu → dialog "Bỏ thay đổi?".  
* **Success:** quay về S14, SnackBar "Đã lưu sản phẩm", hàng vừa sửa nháy nền 1 lần.

[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,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>

[image3]: <data:image/png;base64,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>

[image4]: <data:image/png;base64,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>