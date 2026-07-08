import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class AmPmPicker extends StatefulWidget {
  final bool initialIsAm;
  final ValueChanged<bool> onChanged;

  const AmPmPicker({
    super.key,
    required this.initialIsAm,
    required this.onChanged,
  });

  @override
  State<AmPmPicker> createState() => AmPmPickerState();
}

class AmPmPickerState extends State<AmPmPicker> {
  late final ValueNotifier<bool> _isAm;

  @override
  void initState() {
    super.initState();
    _isAm = ValueNotifier(widget.initialIsAm);
  }

  @override
  void dispose() {
    _isAm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 116,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CupertinoPicker(
            itemExtent: 87,
            scrollController: FixedExtentScrollController(
              initialItem: widget.initialIsAm ? 0 : 1,
            ),
            onSelectedItemChanged: (v) {
              _isAm.value = v == 0;
              widget.onChanged(v == 0); // plain assignment in parent
            },
            selectionOverlay: const SizedBox.shrink(),
            looping: false,
            children: [
              _AmPmItem(
                label: l10n.am,
                isAmNotifier: _isAm,
                representsAm: true,
              ),
              _AmPmItem(
                label: l10n.pm,
                isAmNotifier: _isAm,
                representsAm: false,
              ),
            ],
          ),
          Positioned(
            top: (220 - 87) / 2,
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
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmPmItem extends StatelessWidget {
  final String label;
  final ValueNotifier<bool> isAmNotifier;
  final bool representsAm;

  const _AmPmItem({
    required this.label,
    required this.isAmNotifier,
    required this.representsAm,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isAmNotifier,
      builder: (_, isAm, __) {
        final isSelected = isAm == representsAm;
        return Center(
          child: Text(
            label,
            style: isSelected
                ? Theme.of(context).textTheme.displayMedium
                : Theme.of(context).textTheme.displaySmall,
          ),
        );
      },
    );
  }
}
