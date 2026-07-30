import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_bloc.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_state.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_event.dart';
import 'package:mechanix_settings/features/battery/presentation/widgets/battery_progress_bar.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:upower/upower.dart';

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

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

  String _getTimeText(BatteryState state, AppLocalizations l10n) {
    final totalSeconds = state.batteryRemainingTime ?? 0;
    if (totalSeconds <= 0) {
      return "";
    }

    final time = _formatDuration(totalSeconds, l10n);
    if (time.isNotEmpty) {
      return l10n.batteryTimeRemaining(time);
    }

    return "";
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

    return BlocListener<BatteryBloc, BatteryState>(
      listenWhen: (previous, current) =>
          previous.error != current.error && current.error != null,
      listener: (context, state) {
        if (state.error == null) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getBatteryErrorMessage(
                AppLocalizations.of(context)!,
                state.error!,
              ),
            ),
          ),
        );
      },
      child: BlocBuilder<BatteryBloc, BatteryState>(
        builder: (context, state) {
          final isCharging = state.batteryStatus == UPowerDeviceState.charging;
          final timeText = _getTimeText(state, l10n);
          final displayPercentage = state.batteryPercentage.toInt();

          // Calculate time details to render under the Status title if charging
          final chargeTimeRemainingStr = _getChargingTimeText(state, l10n);

          return Scaffold(
            appBar: AppBar(
              scrolledUnderElevation: 0,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: AppBreadcrumbs(
                scrollController: _breadcrumbController,
                items: [
                  BreadcrumbItem(
                    label: l10n.settings,
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  BreadcrumbItem(label: l10n.battery),
                ],
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: CustomDivider(verticalPadding: 0),
              ),
            ),
            body: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Card 1: Battery Telemetry Detail
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundVariantDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Time Left & Percentage Text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (timeText.isNotEmpty)
                                Text(
                                  timeText,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 18,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Text(
                                l10n.batteryPercentage(displayPercentage),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Row 2: Battery Progress Bar
                          BatteryProgressBar(
                            percentage: state.batteryPercentage,
                          ),
                          const SizedBox(height: 16),

                          // Row 3: Status
                          Row(
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
                                        const CustomImage(
                                          assetPath: SettingIcons.charging,
                                        ),

                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        _formatBatteryStatus(
                                          state.batteryStatus,
                                          l10n,
                                        ),
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                  if (chargeTimeRemainingStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      chargeTimeRemainingStr,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Battery Saver Toggle
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundVariantDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.batterySaver,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.onSurface,
                              fontSize: 18,
                            ),
                          ),
                          CustomToggle(
                            value: state.isBatterySaverOn,
                            onChanged: (val) {
                              context.read<BatteryBloc>().add(
                                ToggleBatterySaver(val),
                              );
                            },
                            l10n: l10n,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomBar(
              leading: CustomIconButton.asset(
                assetPath: SettingIcons.back,
                enabled: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          );
        },
      ),
    );
  }
}
