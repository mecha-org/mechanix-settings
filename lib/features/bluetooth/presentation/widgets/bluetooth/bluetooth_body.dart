import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';

import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';

import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_rename.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_device_list_item.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/config_row.dart';

import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_section_header.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class BluetoothBody extends StatefulWidget {
  const BluetoothBody({super.key});

  @override
  State<BluetoothBody> createState() => _BluetoothBodyState();
}

class _BluetoothBodyState extends State<BluetoothBody> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.bluetooth,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      CustomToggle(
                        value: isBluetoothOn,
                        onChanged: (value) {
                          context.read<BluetoothBloc>().add(
                            ToggleBluetoothPower(value),
                          );
                        },
                        l10n: l10n,
                      ),
                    ],
                  ),
                );
              },
            ),

            const CustomDivider(verticalPadding: 0),

            // Device Name
            BlocSelector<BluetoothBloc, BluetoothState, String>(
              selector: (state) => state.localDeviceName,
              builder: (context, deviceName) {
                return ConfigRow(
                  title: l10n.deviceName,
                  value: deviceName,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BluetoothRenameScreen(),
                      ),
                    );
                  },
                );
              },
            ),

            const CustomDivider(verticalPadding: 0),

            BlocSelector<BluetoothBloc, BluetoothState, bool>(
              selector: (state) => state.isBluetoothOn,
              builder: (context, isBluetoothOn) {
                if (!isBluetoothOn) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Discoverable
                    BlocSelector<BluetoothBloc, BluetoothState, bool>(
                      selector: (state) => state.isDiscoverable,
                      builder: (context, isDiscoverable) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.discoverable,
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                              CustomToggle(
                                value: isDiscoverable,
                                onChanged: (value) {
                                  context.read<BluetoothBloc>().add(
                                    ToggleBluetoothDiscoverable(value),
                                  );
                                },
                                l10n: l10n,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const CustomDivider(verticalPadding: 0),

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

                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: connectedDevices.length,
                              itemBuilder: (context, index) {
                                final device = connectedDevices[index];

                                return BluetoothDeviceListItem(
                                  device: device,
                                  onTap: () {},
                                  onSettingsTap: () =>
                                      _navigateToDetails(context, device),
                                );
                              },
                            ),

                            const CustomDivider(verticalPadding: 0),
                          ],
                        );
                      },
                    ),

                    // My Devices
                    SettingsSectionHeader(title: l10n.myDevices),

                    BlocSelector<
                      BluetoothBloc,
                      BluetoothState,
                      ({
                        List<BluetoothDevice> devices,
                        Set<String> connectingDevices,
                      })
                    >(
                      selector: (state) => (
                        devices: state.pairedDevices
                            .where((device) => !device.isConnected)
                            .map(
                              (device) => device.copyWith(
                                isConnecting: state.connectingDevices.contains(
                                  device.macAddress,
                                ),
                              ),
                            )
                            .toList(),
                        connectingDevices: state.connectingDevices,
                      ),
                      builder: (context, data) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: data.devices.length,
                          itemBuilder: (context, index) {
                            final device = data.devices[index];

                            return BluetoothDeviceListItem(
                              device: device,
                              onTap: () => _connectToDevice(context, device),
                              onSettingsTap: () =>
                                  _navigateToDetails(context, device),
                            );
                          },
                        );
                      },
                    ),

                    const CustomDivider(verticalPadding: 16),

                    // Other devices
                    SettingsSectionHeader(
                      title: l10n.otherDevices,
                      trailing:
                          BlocSelector<BluetoothBloc, BluetoothState, bool>(
                            selector: (state) => state.isScanning,
                            builder: (context, scanning) {
                              if (!scanning) {
                                return CustomIconButton.asset(
                                  assetPath: SettingIcons.refresh,
                                  onPressed: () {
                                    context.read<BluetoothBloc>().add(
                                      const ScanBluetoothDevices(),
                                    );
                                  },
                                );
                              }

                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),

                    BlocSelector<
                      BluetoothBloc,
                      BluetoothState,
                      ({List<BluetoothDevice> devices})
                    >(
                      selector: (state) => (devices: state.discoveredDevices),
                      builder: (context, data) {
                        final devices = data.devices;

                        return Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: devices.length,
                              itemBuilder: (context, index) {
                                final device = devices[index];

                                return Column(
                                  children: [
                                    BluetoothDeviceListItem(
                                      device: device,
                                      onTap: () =>
                                          _connectToDevice(context, device),
                                    ),

                                    const SizedBox(height: 12),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const CustomDivider(verticalPadding: 16),
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
}
