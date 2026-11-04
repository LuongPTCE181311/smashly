/// Tên tiếng Việt của danh mục; DB lưu tên tiếng Anh, tên lạ giữ nguyên.
String categoryLabel(String name) {
  return switch (name) {
    'Rackets' => 'Vợt',
    'Shoes' => 'Giày',
    'Shirts' => 'Áo',
    'Shorts' => 'Quần',
    'Socks' => 'Tất',
    'Bags' => 'Túi',
    'Grips' => 'Quấn cán',
    'Strings' => 'Cước',
    'Nets' => 'Lưới',
    'Accessories' => 'Phụ kiện',
    _ => name,
  };
}
