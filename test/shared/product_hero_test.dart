import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/theme/app_theme.dart';
import 'package:smashly/data/models/product.dart';
import 'package:smashly/routes/app_page_route.dart';
import 'package:smashly/shared/widgets/product_card.dart';

const _product = Product(
  id: 1,
  categoryId: 1,
  name: 'Yonex Astrox 99 Pro',
  brand: 'Yonex',
  price: 4290000,
  stock: 12,
  rating: 4.9,
  ratingCount: 128,
  description: '',
  imagePath: 'assets/images/products/rackets/racket_yonex_astrox99pro.png',
  isFeatured: true,
  isActive: true,
);

void main() {
  testWidgets('ảnh bay từ thẻ sang màn chi tiết, tab ẩn trùng tag không lỗi', (
    tester,
  ) async {
    final tag = ProductCard.heroTagFor(_product.id);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: ProductCard(
                    product: _product,
                    heroTag: tag,
                    onTap: () => Navigator.of(context).push(
                      AppPageRoute<void>(
                        builder: (_) => Scaffold(
                          body: Hero(
                            tag: tag,
                            child: const SizedBox.square(dimension: 200),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: HeroMode(
                    enabled: false,
                    child: ProductCard(
                      product: _product,
                      heroTag: tag,
                      onTap: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ProductCard).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(of: find.byType(Overlay), matching: find.byType(Hero)),
      findsWidgets,
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
