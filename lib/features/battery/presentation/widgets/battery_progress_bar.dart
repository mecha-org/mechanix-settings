import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

class BatteryProgressBar extends StatelessWidget {
  final double percentage;

  const BatteryProgressBar({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: _BatteryProgressPainter.barHeight,
        width: double.infinity,
        child: CustomPaint(
          painter: _BatteryProgressPainter(
            percentage: percentage.clamp(0.0, 100.0),
            fillColor: AppColors.onSurfaceVariant,
            backgroundColor: AppColors.backgroundVariant,
            tipColor: AppColors.backgroundVariant,
          ),
        ),
      ),
    );
  }
}

class _BatteryProgressPainter extends CustomPainter {
  static const double barHeight = 36.0;
  static const double tipWidth = 8.0;
  static const double tipHeight = 14.0;
  static const double tipGap = 4.0;
  static const double borderRadius = 4.0;
  static const double tipRadius = 2.0;
  static const double tipFilledThreshold = 100.0;

  final double percentage;
  final Color fillColor;
  final Color backgroundColor;
  final Color tipColor;

  const _BatteryProgressPainter({
    required this.percentage,
    required this.fillColor,
    required this.backgroundColor,
    required this.tipColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mainWidth = size.width - tipWidth - tipGap;
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw battery body background.
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, mainWidth, size.height),
      const Radius.circular(borderRadius),
    );

    paint.color = backgroundColor;
    canvas.drawRRect(background, paint);

    // Draw battery fill.
    if (percentage > 0) {
      final fillWidth = mainWidth * (percentage / 100);

      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        const Radius.circular(borderRadius),
      );

      paint.color = fillColor;
      canvas.drawRRect(fill, paint);
    }

    // Draw battery tip.
    final tipRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(
        mainWidth + (tipGap / 2),
        (size.height - tipHeight) / 2,
        tipWidth,
        tipHeight,
      ),
      topRight: const Radius.circular(tipRadius),
      bottomRight: const Radius.circular(tipRadius),
    );

    paint.color = percentage >= tipFilledThreshold ? fillColor : tipColor;

    canvas.drawRRect(tipRect, paint);
  }

  @override
  bool shouldRepaint(covariant _BatteryProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.tipColor != tipColor;
  }
}
