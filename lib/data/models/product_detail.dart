import 'product.dart';
import 'racket_spec.dart';

class ProductDetail {
  const ProductDetail({required this.product, this.racketSpec});

  final Product product;
  final RacketSpec? racketSpec;

  bool get isRacket => racketSpec != null;

  bool get isAvailable => product.isActive;

  List<String> get sizes => (product.sizes ?? '')
      .split(',')
      .map((size) => size.trim())
      .where((size) => size.isNotEmpty)
      .toList();
}
