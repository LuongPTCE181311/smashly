/// Ảnh sản phẩm có sẵn trong `assets/images/products/` để admin chọn ở S15.
///
/// Ảnh đóng gói cùng app, DB chỉ lưu chuỗi đường dẫn. Thêm ảnh mới vào thư
/// mục (đã khai báo trong pubspec theo thư mục) → thêm 1 dòng vào đây.
abstract final class ProductImageAssets {
  static const _root = 'assets/images/products';

  /// Tên nhóm → danh sách đường dẫn ảnh, theo thư mục con.
  static const Map<String, List<String>> groups = {
    'Vợt': [
      '$_root/rackets/racket_yonex_astrox99pro.png',
      '$_root/rackets/racket_yonex_astrox77pro.png',
      '$_root/rackets/racket_yonex_nanoflare800pro.png',
      '$_root/rackets/racket_yonex_arcsaber11pro.png',
      '$_root/rackets/racket_yonex_astrox01ability.png',
      '$_root/rackets/racket_victor_ryuga2.png',
      '$_root/rackets/racket_victor_auraspeed90k2.png',
      '$_root/rackets/racket_lining_axforce80.png',
      '$_root/rackets/racket_lining_halbertec8000.png',
    ],
    'Giày': [
      '$_root/shoes/shoe_yonex_65z3.png',
      '$_root/shoes/shoe_victor_a970ace.png',
      '$_root/shoes/shoe_mizuno_wavefangpro.png',
    ],
    'Quần áo': [
      '$_root/apparel/shirt_yonex_game.png',
      '$_root/apparel/shirt_lining_training.png',
      '$_root/apparel/short_victor_game.png',
      '$_root/apparel/socks_yonex_sport.png',
    ],
    'Túi': [
      '$_root/bags/bag_yonex_pro6.png',
      '$_root/bags/bag_victor_backpack.png',
    ],
    'Quấn cán': ['$_root/grips/grip_yonex_supergrap.png'],
    'Cước': ['$_root/strings/string_yonex_bg66ultimax.png'],
    'Lưới': ['$_root/nets/net_lining_tournament.png'],
    'Phụ kiện': ['$_root/accessories/shuttle_yonex_as30.png'],
  };
}
