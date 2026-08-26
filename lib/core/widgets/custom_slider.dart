import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

class CustomSlider extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const CustomSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double height = 36;
        const double thumbWidth = 32;

        void handleDragOrTap(double localX) {
          final double newValue = (localX / width).clamp(0.0, 1.0);
          onChanged(newValue);
        }

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            handleDragOrTap(details.localPosition.dx);
          },
          onHorizontalDragEnd: (details) {
            if (onChangeEnd != null) {
              onChangeEnd!(value);
            }
          },
          onTapDown: (details) {
            final double newValue = (details.localPosition.dx / width).clamp(0.0, 1.0);
            onChanged(newValue);
            if (onChangeEnd != null) {
              onChangeEnd!(newValue);
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: Container(
              width: width,
              height: height,
              color: AppColors.backgroundVariant,
              child: Stack(
                children: [
                  // Active track
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  // Thumb
                  Positioned(
                    left: (value * width - thumbWidth / 2).clamp(0.0, width - thumbWidth),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: thumbWidth,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
