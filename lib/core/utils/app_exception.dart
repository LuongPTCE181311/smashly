class AppException implements Exception {
  const AppException(this.message, {this.field});

  final String message;
  final String? field;

  @override
  String toString() => message;
}
