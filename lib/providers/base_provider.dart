import 'package:flutter/foundation.dart';

/// ChangeNotifier bỏ qua notify khi đã dispose, vì kết quả async có thể về sau khi màn đóng.
abstract class BaseProvider extends ChangeNotifier {
  bool _disposed = false;

  /// `true` sau khi provider bị hủy.
  bool get isDisposed => _disposed;

  /// Báo UI vẽ lại; không làm gì nếu provider đã bị hủy.
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
