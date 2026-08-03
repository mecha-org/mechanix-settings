import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_bloc.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_state.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:upower/upower.dart';

class BatteryStatusSection extends StatelessWidget {
  const BatteryStatusSection({super.key});

  String _formatBatteryStatus(UPowerDeviceState state, AppLocalizations l10n) {
    switch (state) {
      case UPowerDeviceState.charging:
        return l10n.charging;
      case UPowerDeviceState.fullyCharged:
        return l10n.fullCharged;
      case UPowerDeviceState.discharging:
        return l10n.discharging;
      case UPowerDeviceState.empty:
        return l10n.empty;
      case UPowerDeviceState.unknown:
        return l10n.unknown;
      case UPowerDeviceState.pendingCharge:
        return l10n.pendingCharge;
      case UPowerDeviceState.pendingDischarge:
        return l10n.pendingDischarge;
    }
  }

  String _formatDuration(int totalSeconds, AppLocalizations l10n) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return [
      if (hours > 0) l10n.batteryHours(hours),
      if (minutes > 0) l10n.batteryMinutes(minutes),
    ].join(' ');
  }

  String _getChargingTimeText(BatteryState state, AppLocalizations l10n) {
    final chargingTime = state.batteryChargingTime;

    if (state.batteryStatus != UPowerDeviceState.charging ||
        chargingTime == null ||
        chargingTime <= 0) {
      return '';
    }

    return l10n.batteryTimeUntilFull(_formatDuration(chargingTime, l10n));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocSelector<BatteryBloc, BatteryState, BatteryState>(
      selector: (state) => state,
      builder: (context, state) {
        final isCharging = state.batteryStatus == UPowerDeviceState.charging;

        final chargingTimeText = _getChargingTimeText(state, l10n);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.batteryStatus,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCharging) ...[
                      const CustomImage(assetPath: SettingIcons.charging),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatBatteryStatus(state.batteryStatus, l10n),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                if (chargingTimeText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    chargingTimeText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
