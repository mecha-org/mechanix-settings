import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/date_picker/date_picker_column.dart';

class MonthPickerColumn extends StatelessWidget {
  final int selectedMonth;

  final ValueChanged<int> onChanged;

  final double width;

  const MonthPickerColumn({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
    this.width = 120,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return DatePickerColumn<int>(
      width: width,

      items: List.generate(12, (index) => index + 1),

      initialValue: selectedMonth,

      labelBuilder: (month) {
        final dateTime = DateTime(2020, month, 1);
        return DateFormat.MMM(locale).format(dateTime);
      },

      onChanged: onChanged,
    );
  }
}
