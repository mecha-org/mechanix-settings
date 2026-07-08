import 'package:flutter/material.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/time_picker/am_pm_picker.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/time_picker/time_picker_column.dart';

class CustomTimePicker extends StatelessWidget {
  final int selectedHour;
  final int selectedMinute;
  final bool isAm;
  final bool is12Hour;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<bool> onAmPmChanged;

  const CustomTimePicker({
    super.key,
    required this.selectedHour,
    required this.selectedMinute,
    required this.isAm,
    required this.is12Hour,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onAmPmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PickerColumn(
            itemCount: is12Hour ? 12 : 24,
            initialValue: selectedHour,
            isHour: true,
            is12Hour: is12Hour,
            width: 150,
            onChanged: onHourChanged,
          ),
          const SizedBox(width: 10),
          PickerColumn(
            itemCount: 60,
            initialValue: selectedMinute,
            isHour: false,
            is12Hour: is12Hour,
            width: 139,
            onChanged: onMinuteChanged,
          ),
          if (is12Hour) ...[
            const SizedBox(width: 10),
            AmPmPicker(initialIsAm: isAm, onChanged: onAmPmChanged),
          ],
        ],
      ),
    );
  }
}
