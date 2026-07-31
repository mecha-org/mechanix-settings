import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

class PickerColumn extends StatefulWidget {
  final int itemCount;
  final int initialValue;
  final bool isHour;
  final double width;
  final ValueChanged<int> onChanged;
  final bool is12Hour;

  const PickerColumn({
    super.key,
    required this.itemCount,
    required this.initialValue,
    required this.isHour,
    required this.width,
    required this.onChanged,
    required this.is12Hour,
  });

  @override
  State<PickerColumn> createState() => PickerColumnState();
}

class PickerColumnState extends State<PickerColumn> {
  late final FixedExtentScrollController _controller;
  late final ValueNotifier<int> _selectedIndex;

  @override
  void initState() {
    super.initState();
    final initial = widget.isHour
        ? (widget.is12Hour ? widget.initialValue - 1 : widget.initialValue)
        : widget.initialValue;
    _controller = FixedExtentScrollController(initialItem: initial);
    _selectedIndex = ValueNotifier(initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format picker values as two digits using locale-aware numerals.
    final twoDigit = NumberFormat("00");

    return SizedBox(
      width: widget.width,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CupertinoPicker(
            itemExtent: 87,
            scrollController: _controller,
            selectionOverlay: const SizedBox.shrink(),
            squeeze: 1.0,
            diameterRatio: 200,
            looping: true,
            onSelectedItemChanged: (index) {
              _selectedIndex.value = index;
              final value = widget.isHour
                  ? (widget.is12Hour ? index + 1 : index)
                  : index;
              widget.onChanged(value);
            },
            children: List.generate(widget.itemCount, (index) {
              final value = widget.isHour
                  ? (widget.is12Hour ? index + 1 : index)
                  : index;
              final label = twoDigit.format(value);

              return ValueListenableBuilder<int>(
                valueListenable: _selectedIndex,
                builder: (_, selected, __) {
                  final isSelected = index == selected;
                  return Center(
                    child: Text(
                      label,
                      style: isSelected
                          ? Theme.of(context).textTheme.displayLarge
                          : Theme.of(context).textTheme.displaySmall,
                    ),
                  );
                },
              );
            }),
          ),
          Positioned(
            top: 66.5,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 87,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.backgroundVariant,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
