import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/data/models/category.dart';
import 'package:smashly/shared/category_label.dart';

void main() {
  test('categoryLabel đổi tên tiếng Anh sang tiếng Việt', () {
    expect(categoryLabel('Rackets'), 'Vợt');
    expect(categoryLabel('Grips'), 'Quấn cán');
    expect(categoryLabel('Accessories'), 'Phụ kiện');
  });

  test('categoryLabel giữ nguyên tên lạ', () {
    expect(categoryLabel('Unknown'), 'Unknown');
  });

  test('Category.isRacket chỉ đúng với Rackets', () {
    const rackets = Category(
      id: 1,
      name: 'Rackets',
      iconPath: '',
      sortOrder: 1,
    );
    const shoes = Category(id: 2, name: 'Shoes', iconPath: '', sortOrder: 2);

    expect(rackets.isRacket, isTrue);
    expect(shoes.isRacket, isFalse);
  });
}
