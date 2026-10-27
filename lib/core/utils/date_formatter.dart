import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _dateTime = DateFormat('dd/MM/yyyy · HH:mm');

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());
}
