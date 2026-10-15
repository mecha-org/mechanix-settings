import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class BluetoothDeviceDetailScreen extends StatelessWidget {
  final String deviceName;

  const BluetoothDeviceDetailScreen({super.key, required this.deviceName});

  String _getLocalizedType(BluetoothDeviceType type, AppLocalizations l10n) {
    switch (type) {
      case BluetoothDeviceType.mobile:
        return l10n.mobileType;

      case BluetoothDeviceType.speaker:
        return l10n.speakerType;

      case BluetoothDeviceType.unknown:
        return l10n.unknownType;

      case BluetoothDeviceType.headphones:
        return l10n.headphones;

      case BluetoothDeviceType.computer:
        return l10n.computer;

      case BluetoothDeviceType.tv:
        return l10n.tv;

      case BluetoothDeviceType.car:
        return l10n.car;
    }
  }

  BluetoothDevice _selectDevice(BluetoothState state) {
    return state.pairedDevices.firstWhere(
      (d) => d.name == deviceName,
      orElse: () => state.discoveredDevices.firstWhere(
        (d) => d.name == deviceName,
        orElse: () => BluetoothDevice(
          name: deviceName,
          deviceName: deviceName,
          type: BluetoothDeviceType.unknown,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocSelector<BluetoothBloc, BluetoothState, BluetoothDevice>(
      selector: (state) => _selectDevice(state),
      builder: (context, device) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          appBar: MechanixAppBar.small(
            primary: false,
            backgroundColor: Colors.transparent,
            leading: MechanixIconButton.standard(
              icon: ImageIcon(
                const AssetImage(SettingIcons.back),
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              deviceName.toUpperCase(),
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w300,
              ),
            ),
            actions: [
              MechanixMenu(
                alignment: MechanixMenuAlignment.end,
                anchorBuilder: (context, controller, child) {
                  return MechanixIconButton.standard(
                    type: IconButtonType.rounded,
                    size: IconButtonSize.small,
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.moreVert),
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.toggle();
                    },
                  );
                },
                entries: [
                  MechanixMenuItem(
                    value: 'refresh',
                    leading: ImageIcon(
                      AssetImage(
                        device.isConnected
                            ? SettingIcons.disconnect
                            : SettingIcons.connect,
                      ),
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    label: Text(
                      device.isConnected ? l10n.disconnect : l10n.connect,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryFixed,
                        letterSpacing: 1,
                      ),
                    ),
                    onTap: device.isConnected
                        ? () {
                            context.read<BluetoothBloc>().add(
                              DisconnectFromDeviceEvent(device),
                            );
                            Navigator.pop(context);
                          }
                        : () {
                            context.read<BluetoothBloc>().add(
                              ConnectToDeviceEvent(device),
                            );
                            Navigator.pop(context);
                          },
                  ),
                  MechanixMenuItem(
                    value: 'forget',
                    leading: ImageIcon(
                      const AssetImage(SettingIcons.delete),
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      l10n.forgetDevice,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                        letterSpacing: 1,
                      ),
                    ),
                    onTap: () {
                      context.read<BluetoothBloc>().add(
                        ForgetDeviceEvent(device),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
          body: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device type
                  MechanixListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    labelText: l10n.deviceType,
                    trailingWidgets: [
                      ImageIcon(
                        AssetImage(device.type.icon),
                        size: 20,
                        color: theme.colorScheme.onSecondaryFixed,
                      ),
                      Text(
                        _getLocalizedType(device.type, l10n).toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryFixed,
                        ),
                      ),
                    ],
                  ),

                  // Device status
                  MechanixListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    labelText: l10n.deviceStatus,
                    trailingWidgets: [
                      if (device.isConnected)
                        ImageIcon(
                          const AssetImage(SettingIcons.ellipse),
                          size: 8,
                          color: theme.colorScheme.primary,
                        ),
                      Text(
                        (device.isConnected
                                ? l10n.connected
                                : l10n.notConnected)
                            .toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryFixed,
                        ),
                      ),
                    ],
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
