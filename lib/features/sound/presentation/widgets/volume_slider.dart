import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/features/sound/presentation/widgets/rectangular_slider_thumb_shape.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class VolumeSlider extends StatefulWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final bool showSlider;

  const VolumeSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.showSlider = true,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  late double _value;
  late double _lastNonZeroValue;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _lastNonZeroValue = widget.value > 0.0 ? widget.value : 0.5;
  }

  @override
  void didUpdateWidget(covariant VolumeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update local value when the volume changes externally.
    if (oldWidget.value != widget.value) {
      _value = widget.value;
      if (widget.value > 0.0) {
        _lastNonZeroValue = widget.value;
      }
    }
  }

  IconData _getIconData() {
    final isInput = widget.title.toLowerCase().contains('input');
    if (_value == 0.0) {
      return isInput ? Icons.mic_off_outlined : Icons.volume_off_outlined;
    } else {
      return isInput ? Icons.mic_none_outlined : Icons.volume_up_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (_value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            if (widget.showSlider)
              Text(
                AppLocalizations.of(context)!.volumePercentage(percentage),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
          ],
        ),

        if (widget.showSlider) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              CustomIconButton.icon(
                iconData: _getIconData(),
                onPressed: () {
                  if (_value > 0.0) {
                    setState(() {
                      _lastNonZeroValue = _value;
                      _value = 0.0;
                    });
                    widget.onChanged(0.0);
                  } else {
                    setState(() {
                      _value = _lastNonZeroValue;
                    });
                    widget.onChanged(_lastNonZeroValue);
                  }
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: AppColors.backgroundVariant,
                    thumbColor: Colors.white,
                    thumbShape: const RectangularSliderThumbShape(
                      thumbWidth: 16,
                      thumbHeight: 16,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _value.clamp(0.0, 1.0),
                    onChanged: (value) {
                      setState(() {
                        _value = value;
                        if (value > 0.0) {
                          _lastNonZeroValue = value;
                        }
                      });
                    },
                    onChangeEnd: (value) {
                      widget.onChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
