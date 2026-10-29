/// Tên danh mục tiếng Việt (DB lưu tiếng Anh, giống màn Shop). Dùng ở S14, S15.
String adminCategoryLabel(String name) {
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
