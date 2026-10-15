import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';

import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/about_device_screen.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_connected_device_tile.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_device_list_item.dart';

import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class BluetoothBody extends StatefulWidget {
  const BluetoothBody({super.key});

  @override
  State<BluetoothBody> createState() => _BluetoothBodyState();
}

class _BluetoothBodyState extends State<BluetoothBody> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bluetooth Toggle
            BlocSelector<BluetoothBloc, BluetoothState, bool>(
              selector: (state) => state.isBluetoothOn,
              builder: (context, isBluetoothOn) {
                return MechanixListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 24,
                  ),
                  label: Text(
                    l10n.bluetooth.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  trailingWidgets: [
                    MechanixSwitch(
                      value: isBluetoothOn,
                      onChanged: (value) {
                        context.read<BluetoothBloc>().add(
                          ToggleBluetoothPower(value),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            BlocSelector<BluetoothBloc, BluetoothState, String>(
              selector: (state) => state.localDeviceName,
              builder: (context, deviceName) {
                return MechanixListTile(
                  contentPadding: const EdgeInsets.only(
                    left: 24,
                    right: 8,
                    top: 4,
                    bottom: 4,
                  ),
                  labelText: l10n.aboutDevice,
                  onTap: () => _navigateToAboutDevice(context),
                  trailingWidgets: [
                    Text(
                      deviceName,
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: theme.colorScheme.onSecondaryFixed,
                      ),
                    ),
                    MechanixIconButton.standard(
                      type: IconButtonType.rounded,
                      icon: ImageIcon(
                        const AssetImage(SettingIcons.caretRight),
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () => _navigateToAboutDevice(context),
                    ),
                  ],
                );
              },
            ),

            BlocSelector<BluetoothBloc, BluetoothState, bool>(
              selector: (state) => state.isBluetoothOn,
              builder: (context, isBluetoothOn) {
                if (!isBluetoothOn) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connected devices
                    BlocSelector<
                      BluetoothBloc,
                      BluetoothState,
                      List<BluetoothDevice>
                    >(
                      selector: (state) {
                        return state.pairedDevices
                            .where((device) => device.isConnected)
                            .toList();
                      },
                      builder: (context, connectedDevices) {
                        if (connectedDevices.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        const MechanixDivider(
                          indent: 24,
                          endIndent: 24,
                          space: 0,
                        );

                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: connectedDevices.length,
                              itemBuilder: (context, index) {
                                final device = connectedDevices[index];

                                return BluetoothConnectedDeviceTile(
                                  key: ValueKey(device.macAddress),
                                  device: device,
                                  onTap: () {},
                                  onSettingsTap: () =>
                                      _navigateToDetails(context, device),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    // My Devices
                    BlocSelector<
                      BluetoothBloc,
                      BluetoothState,
                      List<BluetoothDevice>
                    >(
                      selector: (state) => state.pairedDevices
                          .where((device) => !device.isConnected)
                          .map(
                            (device) => device.copyWith(
                              isConnecting: state.connectingDevices.contains(
                                device.macAddress,
                              ),
                            ),
                          )
                          .toList(),
                      builder: (context, devices) {
                        final countStr = devices.length.toString().padLeft(
                          2,
                          '0',
                        );

                        return MechanixExpandableListTile(
                          key: const ValueKey('my_devices'),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 24,
                          ),
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const MechanixDivider(space: 0),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.myDevices,
                                      style: context.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: context
                                                .colorScheme
                                                .onSecondaryFixed,
                                            fontWeight: FontWeight.w400,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Transform.translate(
                                      offset: const Offset(0, -4),
                                      child: Text(
                                        '[$countStr]',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: context
                                                  .colorScheme
                                                  .onSecondaryFixed,
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const MechanixDivider(space: 0),
                            ],
                          ),
                          showAccordionButton: false,
                          backgroundColor:
                              context.colorScheme.surfaceContainerLowest,
                          initiallyExpanded: true,
                          children: devices.map((device) {
                            return BluetoothDeviceListItem(
                              key: ValueKey(device.macAddress),
                              device: device,
                              onTap: () => _connectToDevice(context, device),
                              onSettingsTap: () =>
                                  _navigateToDetails(context, device),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    // Other Devices
                    BlocSelector<BluetoothBloc, BluetoothState, bool>(
                      selector: (state) => state.isScanning,
                      builder: (context, scanning) {
                        return BlocSelector<
                          BluetoothBloc,
                          BluetoothState,
                          List<BluetoothDevice>
                        >(
                          selector: (state) => state.discoveredDevices,
                          builder: (context, devices) {
                            final countStr = devices.length.toString().padLeft(
                              2,
                              '0',
                            );

                            return MechanixExpandableListTile(
                              key: const ValueKey('other_devices'),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 24,
                              ),
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.otherDevices,
                                          style: context.textTheme.headlineSmall
                                              ?.copyWith(
                                                color: context
                                                    .colorScheme
                                                    .onSecondaryFixed,
                                                fontWeight: FontWeight.w400,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Transform.translate(
                                          offset: const Offset(0, -4),
                                          child: Text(
                                            '[$countStr]',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .colorScheme
                                                      .onSecondaryFixed,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              showTopDivider: true,
                              showBottomDivider: true,
                              trailingWidgets: [
                                scanning
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.colorScheme.primary,
                                              ),
                                          backgroundColor: theme
                                              .colorScheme
                                              .secondaryContainer,
                                        ),
                                      )
                                    : MechanixIconButton.standard(
                                        type: IconButtonType.rounded,
                                        icon: ImageIcon(
                                          const AssetImage(
                                            SettingIcons.refresh,
                                          ),
                                          color: theme.colorScheme.onSurface,
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          context.read<BluetoothBloc>().add(
                                            const ScanBluetoothDevices(),
                                          );
                                        },
                                      ),
                              ],

                              showAccordionButton: false,
                              backgroundColor:
                                  context.colorScheme.surfaceContainerLowest,
                              initiallyExpanded: true,
                              children: devices.map((device) {
                                return BluetoothDeviceListItem(
                                  key: ValueKey(device.macAddress),
                                  device: device,
                                  onTap: () =>
                                      _connectToDevice(context, device),
                                  onSettingsTap: () =>
                                      _navigateToDetails(context, device),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _connectToDevice(BuildContext context, BluetoothDevice device) {
    context.read<BluetoothBloc>().add(ConnectToDeviceEvent(device));
  }

  void _navigateToDetails(BuildContext context, BluetoothDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BluetoothDeviceDetailScreen(deviceName: device.name),
      ),
    );
  }

  void _navigateToAboutDevice(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AboutDeviceScreen()));
  }
}
