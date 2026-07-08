import 'package:intl/intl.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/date_picker/wheel_scroll_options.dart';

final List<WheelScrollOption<int>> yearsOptions = List.generate(201, (index) {
  final year = DateTime.now().year - 100 + index;

  return WheelScrollOption<int>(label: year.toString(), value: year);
});

final List<WheelScrollOption<int>> monthsOptions = List.generate(12, (index) {
  final month = index + 1;

  return WheelScrollOption<int>(
    label: DateFormat('MMM').format(DateTime(DateTime.now().year, month)),
    value: month,
  );
});

List<WheelScrollOption<int>> getDaysOptions(int year, int month) {
  final days = getDaysInMonth(year, month);

  // Format day numbers as two digits using locale-aware numerals.
  final twoDigit = NumberFormat("00");

  return List.generate(days, (index) {
    final day = index + 1;

    return WheelScrollOption<int>(label: twoDigit.format(day), value: day);
  });
}

int getDaysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

bool isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

String getWeekday(int year, int month, int day) {
  return DateFormat('EEE').format(DateTime(year, month, day));
}

int normalizeDay(int year, int month, int selectedDay) {
  final maxDay = getDaysInMonth(year, month);

  if (selectedDay > maxDay) {
    return maxDay;
  }

  return selectedDay;
}
