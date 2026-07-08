import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

class DatePickerColumn<T> extends StatefulWidget {
  final List<T> items;
  final T initialValue;
  final double width;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  const DatePickerColumn({
    super.key,
    required this.items,
    required this.initialValue,
    required this.labelBuilder,
    required this.onChanged,
    required this.width,
  });

  @override
  State<DatePickerColumn<T>> createState() => _DatePickerColumnState<T>();
}

class _DatePickerColumnState<T> extends State<DatePickerColumn<T>> {
  late FixedExtentScrollController _controller;
  late ValueNotifier<int> _selectedIndex;

  @override
  void initState() {
    super.initState();

    final index = widget.items.indexOf(widget.initialValue);

    _controller = FixedExtentScrollController(
      initialItem: index < 0 ? 0 : index,
    );

    _selectedIndex = ValueNotifier(index < 0 ? 0 : index);
  }

  @override
  void dispose() {
    _controller.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CupertinoPicker(
            itemExtent: 87,
            looping: true,
            scrollController: _controller,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: (index) {
              _selectedIndex.value = index;
              widget.onChanged(widget.items[index]);
            },

            children: List.generate(widget.items.length, (index) {
              return ValueListenableBuilder<int>(
                valueListenable: _selectedIndex,
                builder: (_, selected, __) {
                  final selectedItem = index == selected;

                  return Center(
                    child: Text(
                      widget.labelBuilder(widget.items[index]),
                      style: selectedItem
                          ? Theme.of(context).textTheme.displayMedium
                          : Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
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
