/// Formats database timestamps as UTC with second precision.
String dbTime(DateTime time) {
  final utc = time.toUtc();
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  return '${utc.year.toString().padLeft(4, '0')}-'
      '${twoDigits(utc.month)}-${twoDigits(utc.day)} '
      '${twoDigits(utc.hour)}:${twoDigits(utc.minute)}:${twoDigits(utc.second)}';
}

/// Parses database timestamps as UTC, including legacy ISO strings with `T`.
DateTime parseDbTime(String value) {
  final isoTimestamp = value.trim().replaceFirst(' ', 'T');
  final hasTimezone = RegExp(
    r'(?:Z|[+-]\d{2}:?\d{2})$',
    caseSensitive: false,
  ).hasMatch(isoTimestamp);

  return DateTime.parse(hasTimezone ? isoTimestamp : '${isoTimestamp}Z')
      .toUtc();
}
