import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

import 'package:mechanix_settings/features/date_time/presentation/widgets/date_picker/date_picker_column.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/date_picker/month_picker_column.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/date_picker/date_picker_utils.dart';

class CustomDatePicker extends StatelessWidget {
  final int selectedDay;
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const CustomDatePicker({
    super.key,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Format day numbers as two digits using locale-aware numerals.
    final twoDigit = NumberFormat("00");

    final days = List.generate(
      getDaysInMonth(selectedYear, selectedMonth),
      (index) => index + 1,
    );
    final weekday = getWeekday(selectedYear, selectedMonth, selectedDay);

    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day
          DatePickerColumn<int>(
            width: 80,
            items: days,
            initialValue: selectedDay > days.length ? days.length : selectedDay,
            labelBuilder: (day) => twoDigit.format(day),
            onChanged: onDayChanged,
          ),

          const SizedBox(width: 8),

          // Month
          MonthPickerColumn(
            selectedMonth: selectedMonth,
            onChanged: onMonthChanged,
            width: 120,
          ),

          const SizedBox(width: 8),

          // Year
          DatePickerColumn<int>(
            width: 130,
            items: yearsOptions.map((e) => e.value).toList(),
            initialValue: selectedYear,
            labelBuilder: (year) => year.toString(),
            onChanged: onYearChanged,
          ),

          const SizedBox(width: 8),

          // Weekday (readonly)
          SizedBox(
            width: 100,
            height: 220,
            child: Center(
              child: Text(
                weekday,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
