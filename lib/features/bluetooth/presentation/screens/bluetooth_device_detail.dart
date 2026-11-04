import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class BluetoothDeviceDetailScreen extends StatelessWidget {
  final String macAddress;
  final String title;

  const BluetoothDeviceDetailScreen({
    super.key,
    required this.macAddress,
    required this.title,
  });

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

  BluetoothDevice? _selectDevice(BluetoothState state) {
    return state.pairedDevices.firstWhereOrNull(
          (d) => d.macAddress == macAddress,
        ) ??
        state.discoveredDevices.firstWhereOrNull(
          (d) => d.macAddress == macAddress,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocSelector<BluetoothBloc, BluetoothState, BluetoothDevice?>(
      selector: (state) => _selectDevice(state),
      builder: (context, device) {
        if (device == null) {
          return Scaffold(
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            body: const SizedBox.shrink(),
          );
        }

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
              (device.name.isNotEmpty ? device.name : title),
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w300,
              ),
            ),
            actions: [
              MechanixIconButton.filled(
                backgroundColor: theme.colorScheme.secondaryContainer,
                type: IconButtonType.rounded,
                size: IconButtonSize.small,
                icon: ImageIcon(
                  AssetImage(
                    device.isConnected
                        ? SettingIcons.disconnect
                        : SettingIcons.bluetooth,
                  ),
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: device.isConnected
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

              MechanixIconButton.filled(
                backgroundColor: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.08,
                ),
                type: IconButtonType.rounded,
                size: IconButtonSize.small,
                icon: ImageIcon(
                  const AssetImage(SettingIcons.delete),
                  size: 24,
                  color: theme.colorScheme.error,
                ),
                onPressed: () {
                  context.read<BluetoothBloc>().add(ForgetDeviceEvent(device));
                  Navigator.pop(context);
                },
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
                        color: theme.colorScheme.onPrimary,
                      ),
                      Text(
                        _getLocalizedType(device.type, l10n).toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
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
                            : l10n.disonnected),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
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
