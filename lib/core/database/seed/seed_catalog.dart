import 'package:sqflite/sqflite.dart';

import '../../utils/db_time.dart';
import '../db_schema.dart';

/// OWNER: TV5.
///
/// Giá là giá demo (VND). Thông số vợt là giá trị tham khảo —
/// đối chiếu trang chính thức của hãng trước khi demo.
/// Ảnh: đặt file đúng đường dẫn image_path trong assets/images/products/...
/// (thiếu ảnh thì UI hiện ảnh dự phòng, app không crash).

const _img = 'assets/images/products';

Future<void> seedCatalog(DatabaseExecutor db, DateTime now) async {
  final time = dbTime(now);

  // ---------- 10 danh mục (id cố định) ----------
  const categories = [
    'Rackets', 'Shoes', 'Shirts', 'Shorts', 'Socks',
    'Bags', 'Grips', 'Strings', 'Nets', 'Accessories',
  ];
  for (var i = 0; i < categories.length; i++) {
    await db.insert(DbSchema.categories, {
      'id': i + 1,
      'name': categories[i],
      'icon_path': 'assets/images/categories/${categories[i].toLowerCase()}.png',
      'sort_order': i,
    });
  }

  // ---------- 22 sản phẩm ----------
  for (final p in _products) {
    await db.insert(DbSchema.products, {...p, 'created_at': time, 'updated_at': time});
  }

  // ---------- Thông số cho 9 cây vợt ----------
  for (final s in _racketSpecs) {
    await db.insert(DbSchema.racketSpecs, s);
  }
}

// Id danh mục
const _rackets = 1, _shoes = 2, _shirts = 3, _shorts = 4, _socks = 5,
    _bags = 6, _grips = 7, _strings = 8, _nets = 9, _accessories = 10;

Map<String, Object?> _product({
  required int id,
  required int category,
  required String name,
  required String brand,
  required int price,
  int? originalPrice,
  required int stock,
  required double rating,
  required int ratingCount,
  required String description,
  required String image,
  String? sizes,
  bool featured = false,
}) =>
    {
      'id': id,
      'category_id': category,
      'name': name,
      'brand': brand,
      'price': price,
      'original_price': originalPrice,
      'stock': stock,
      'rating': rating,
      'rating_count': ratingCount,
      'description': description,
      'image_path': '$_img/$image',
      'sizes': sizes,
      'is_featured': featured ? 1 : 0,
      'is_active': 1,
    };

final _products = [
  // ===== Rackets =====
  _product(id: 1, category: _rackets, name: 'Yonex Astrox 99 Pro', brand: 'Yonex',
      price: 4290000, stock: 12, rating: 4.9, ratingCount: 128, featured: true,
      image: 'rackets/racket_yonex_astrox99pro.png',
      description: 'Vợt tấn công đầu bảng của Yonex. Nặng đầu, đũa cứng giúp những cú đập cầu uy lực và cắm sâu. Dành cho người chơi có lực cổ tay tốt.'),
  _product(id: 2, category: _rackets, name: 'Yonex Astrox 77 Pro', brand: 'Yonex',
      price: 3690000, originalPrice: 4090000, stock: 15, rating: 4.7, ratingCount: 94,
      image: 'rackets/racket_yonex_astrox77pro.png',
      description: 'Phiên bản dễ đánh hơn của dòng Astrox: vẫn nặng đầu để tấn công nhưng đũa trung bình, phù hợp người chơi trình độ khá.'),
  _product(id: 3, category: _rackets, name: 'Yonex Nanoflare 800 Pro', brand: 'Yonex',
      price: 4190000, stock: 3, rating: 4.8, ratingCount: 76,
      image: 'rackets/racket_yonex_nanoflare800pro.png',
      description: 'Nhẹ đầu, vung vợt cực nhanh. Mạnh ở đánh phẳng, chặn cầu và điều cầu trên lưới.'),
  _product(id: 4, category: _rackets, name: 'Yonex Arcsaber 11 Pro', brand: 'Yonex',
      price: 4090000, stock: 9, rating: 4.8, ratingCount: 65,
      image: 'rackets/racket_yonex_arcsaber11pro.png',
      description: 'Cân bằng giữa công và thủ, cảm giác giữ cầu tốt. Lựa chọn của người thích kiểm soát và đặt cầu chính xác.'),
  _product(id: 5, category: _rackets, name: 'Yonex Astrox 01 Ability', brand: 'Yonex',
      price: 890000, stock: 30, rating: 4.4, ratingCount: 210,
      image: 'rackets/racket_yonex_astrox01ability.png',
      description: 'Vợt nhẹ, đũa dẻo, dễ trợ lực. Phù hợp người mới bắt đầu chơi cầu lông.'),
  _product(id: 6, category: _rackets, name: 'Victor Thruster Ryuga II', brand: 'Victor',
      price: 3590000, stock: 10, rating: 4.7, ratingCount: 58, featured: true,
      image: 'rackets/racket_victor_ryuga2.png',
      description: 'Vợt tấn công nặng đầu của Victor, đầu vợt đầm giúp đập cầu chắc tay.'),
  _product(id: 7, category: _rackets, name: 'Victor Auraspeed 90K II', brand: 'Victor',
      price: 3490000, stock: 11, rating: 4.6, ratingCount: 47,
      image: 'rackets/racket_victor_auraspeed90k2.png',
      description: 'Nhẹ đầu, phản xạ nhanh, mạnh ở phòng thủ và đôi.'),
  _product(id: 8, category: _rackets, name: 'Li-Ning Axforce 80', brand: 'Li-Ning',
      price: 3390000, stock: 0, rating: 4.6, ratingCount: 39,
      image: 'rackets/racket_lining_axforce80.png',
      description: 'Vợt tấn công cao cấp của Li-Ning, đũa cứng, nặng đầu.'),
  _product(id: 9, category: _rackets, name: 'Li-Ning Halbertec 8000', brand: 'Li-Ning',
      price: 3190000, stock: 14, rating: 4.5, ratingCount: 33,
      image: 'rackets/racket_lining_halbertec8000.png',
      description: 'Cân bằng, đũa trung bình, dễ làm quen. Phù hợp lối chơi toàn diện.'),

  // ===== Shoes =====
  _product(id: 10, category: _shoes, name: 'Yonex Power Cushion 65 Z3', brand: 'Yonex',
      price: 2590000, stock: 20, rating: 4.8, ratingCount: 152, featured: true,
      image: 'shoes/shoe_yonex_65z3.png', sizes: '39,40,41,42,43,44',
      description: 'Giày cầu lông êm chân với đệm Power Cushion, bám sân tốt khi di chuyển nhanh.'),
  _product(id: 11, category: _shoes, name: 'Victor A970 Ace', brand: 'Victor',
      price: 2290000, originalPrice: 2690000, stock: 16, rating: 4.6, ratingCount: 71,
      image: 'shoes/shoe_victor_a970ace.png', sizes: '39,40,41,42,43,44',
      description: 'Giày ổn định cổ chân, đế chống trượt, phù hợp người chơi thường xuyên.'),
  _product(id: 12, category: _shoes, name: 'Mizuno Wave Fang Pro', brand: 'Mizuno',
      price: 2690000, stock: 12, rating: 4.7, ratingCount: 44,
      image: 'shoes/shoe_mizuno_wavefangpro.png', sizes: '40,41,42,43,44',
      description: 'Form giày ôm chân, phản hồi nhanh khi bật nhảy và đổi hướng.'),

  // ===== Apparel =====
  _product(id: 13, category: _shirts, name: 'Yonex Game Shirt', brand: 'Yonex',
      price: 590000, stock: 40, rating: 4.5, ratingCount: 88,
      image: 'apparel/shirt_yonex_game.png', sizes: 'S,M,L,XL',
      description: 'Áo thi đấu vải thoáng khí, khô nhanh.'),
  _product(id: 14, category: _shirts, name: 'Li-Ning Training Tee', brand: 'Li-Ning',
      price: 450000, stock: 35, rating: 4.3, ratingCount: 52,
      image: 'apparel/shirt_lining_training.png', sizes: 'S,M,L,XL',
      description: 'Áo tập co giãn, nhẹ, phù hợp tập luyện hằng ngày.'),
  _product(id: 15, category: _shorts, name: 'Victor Game Shorts', brand: 'Victor',
      price: 390000, stock: 30, rating: 4.4, ratingCount: 41,
      image: 'apparel/short_victor_game.png', sizes: 'S,M,L,XL',
      description: 'Quần thi đấu co giãn 4 chiều, không cản trở bước chân.'),
  _product(id: 16, category: _socks, name: 'Yonex Sport Socks (3 đôi)', brand: 'Yonex',
      price: 150000, stock: 60, rating: 4.2, ratingCount: 120,
      image: 'apparel/socks_yonex_sport.png',
      description: 'Tất thể thao dày ở gót và mũi, giảm ma sát khi di chuyển.'),

  // ===== Bags =====
  _product(id: 17, category: _bags, name: 'Yonex Pro Racquet Bag 6 cây', brand: 'Yonex',
      price: 1890000, stock: 8, rating: 4.7, ratingCount: 36, featured: true,
      image: 'bags/bag_yonex_pro6.png',
      description: 'Túi đựng được 6 cây vợt, có ngăn giày riêng và ngăn cách nhiệt.'),
  _product(id: 18, category: _bags, name: 'Victor Backpack', brand: 'Victor',
      price: 1190000, stock: 4, rating: 4.5, ratingCount: 27,
      image: 'bags/bag_victor_backpack.png',
      description: 'Balo gọn nhẹ, đựng 2 cây vợt và đồ tập.'),

  // ===== Phụ kiện =====
  _product(id: 19, category: _grips, name: 'Yonex Super Grap (3 cuộn)', brand: 'Yonex',
      price: 150000, stock: 80, rating: 4.6, ratingCount: 300,
      image: 'grips/grip_yonex_supergrap.png',
      description: 'Quấn cán mỏng, bám tay và thấm mồ hôi tốt.'),
  _product(id: 20, category: _strings, name: 'Yonex BG66 Ultimax', brand: 'Yonex',
      price: 220000, stock: 50, rating: 4.7, ratingCount: 180,
      image: 'strings/string_yonex_bg66ultimax.png',
      description: 'Cước mảnh 0.65 mm, tiếng nổ to, độ nảy cao.'),
  _product(id: 21, category: _nets, name: 'Li-Ning Tournament Net', brand: 'Li-Ning',
      price: 690000, stock: 10, rating: 4.3, ratingCount: 15,
      image: 'nets/net_lining_tournament.png',
      description: 'Lưới thi đấu tiêu chuẩn, sợi bền, viền chắc chắn.'),
  _product(id: 22, category: _accessories, name: 'Yonex Aerosensa 30 (ống 12 quả)', brand: 'Yonex',
      price: 750000, originalPrice: 790000, stock: 25, rating: 4.6, ratingCount: 64,
      image: 'accessories/shuttle_yonex_as30.png',
      description: 'Cầu lông vũ thi đấu, đường bay ổn định.'),
];

Map<String, Object?> _spec(int productId, String weight, String balance,
        String shaft, int tension, String level, String style) =>
    {
      'product_id': productId,
      'weight_class': weight,
      'balance': balance,
      'shaft': shaft,
      'max_tension_lbs': tension,
      'player_level': level,
      'play_style': style,
    };

// Đủ 4 lối chơi, 3 trình độ, 3 kiểu cân bằng để filter có ý nghĩa.
final _racketSpecs = [
  _spec(1, '4U', 'HEAD_HEAVY', 'STIFF', 28, 'ADVANCED', 'ATTACK'),
  _spec(2, '4U', 'HEAD_HEAVY', 'MEDIUM', 28, 'INTERMEDIATE', 'ATTACK'),
  _spec(3, '4U', 'HEAD_LIGHT', 'STIFF', 28, 'ADVANCED', 'CONTROL'),
  _spec(4, '4U', 'EVEN', 'STIFF', 28, 'ADVANCED', 'CONTROL'),
  _spec(5, '5U', 'HEAD_HEAVY', 'FLEXIBLE', 24, 'BEGINNER', 'ALL_ROUND'),
  _spec(6, '4U', 'HEAD_HEAVY', 'STIFF', 30, 'ADVANCED', 'ATTACK'),
  _spec(7, '4U', 'HEAD_LIGHT', 'STIFF', 28, 'ADVANCED', 'DEFENSE'),
  _spec(8, '4U', 'HEAD_HEAVY', 'STIFF', 30, 'ADVANCED', 'ATTACK'),
  _spec(9, '4U', 'EVEN', 'MEDIUM', 28, 'INTERMEDIATE', 'ALL_ROUND'),
];
