/// Mã đơn dễ đọc, ví dụ SML-20261005-0007; dùng cho cả đơn seed và đơn thật.
String orderCode(DateTime date, int sequence) {
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${date.year}${two(date.month)}${two(date.day)}';
  return 'SML-$day-${sequence.toString().padLeft(4, '0')}';
}
