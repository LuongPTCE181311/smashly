import 'package:flutter_test/flutter_test.dart';
import 'package:smashly/core/constants/enums.dart';

/// Luật chuyển trạng thái UC19: duyệt ĐỦ 5 × 5 cặp, ngoài bảng này đều cấm.
void main() {
  const allowed = {
    OrderStatus.pending: {OrderStatus.confirmed, OrderStatus.cancelled},
    OrderStatus.confirmed: {OrderStatus.shipping, OrderStatus.cancelled},
    OrderStatus.shipping: {OrderStatus.delivered},
    OrderStatus.delivered: <OrderStatus>{},
    OrderStatus.cancelled: <OrderStatus>{},
  };

  for (final from in OrderStatus.values) {
    for (final to in OrderStatus.values) {
      final expected = allowed[from]!.contains(to);
      test('${from.name} → ${to.name}: ${expected ? 'được' : 'cấm'}', () {
        expect(from.canTransitionTo(to), expected);
      });
    }
  }

  test('chỉ DELIVERED và CANCELLED là trạng thái cuối', () {
    expect(OrderStatus.values.where((status) => status.isFinal), [
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ]);
  });
}
