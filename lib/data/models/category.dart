class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String iconPath;
  final int sortOrder;

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      iconPath: map['icon_path'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_path': iconPath,
      'sort_order': sortOrder,
    };
  }
}
