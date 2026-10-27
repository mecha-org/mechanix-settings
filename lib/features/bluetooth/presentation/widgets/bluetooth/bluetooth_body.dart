import 'dart:ui';

import 'package:equatable/equatable.dart';
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
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
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
                        l10n.bluetooth,
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

                // About Device
                BlocSelector<BluetoothBloc, BluetoothState, (String, bool)>(
                  selector: (state) =>
                      (state.localDeviceName, state.isBluetoothOn),
                  builder: (context, selectedValues) {
                    final deviceName = selectedValues.$1;
                    final isBluetoothOn = selectedValues.$2;

                    if (!isBluetoothOn) {
                      return const SizedBox.shrink();
                    }

                    return MechanixListTile(
                      key: const ValueKey('about_device_tile'),
                      contentPadding: const EdgeInsets.only(
                        left: 24,
                        right: 8,
                        top: 4,
                        bottom: 4,
                      ),
                      label: Text(
                        l10n.aboutDevice,
                        style: theme.textTheme.titleLarge!.copyWith(
                          color: theme.colorScheme.onSecondaryFixed,
                        ),
                      ),
                      onTap: () => _navigateToAboutDevice(context),
                      trailingWidgets: [
                        Text(
                          deviceName,
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: theme.colorScheme.onPrimaryFixed,
                          ),
                        ),
                        MechanixIconButton.standard(
                          key: const ValueKey('about_device_button'),
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

                const SizedBox(height: 12),

                // Connected, My Devices, Other Devices Header
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
                        BlocSelector<BluetoothBloc, BluetoothState, _Devices>(
                          selector: (state) => _Devices(
                            state.pairedDevices
                                .where((device) => device.isConnected)
                                .toList(),
                          ),
                          builder: (context, connected) {
                            final connectedDevices = connected.items;
                            if (connectedDevices.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                for (final device in connectedDevices)
                                  BluetoothConnectedDeviceTile(
                                    key: ValueKey(device.macAddress),
                                    device: device,
                                    onTap: () {},
                                    onSettingsTap: () =>
                                        _navigateToDetails(context, device),
                                  ),
                              ],
                            );
                          },
                        ),

                        // My Devices
                        BlocSelector<BluetoothBloc, BluetoothState, _Devices>(
                          selector: (state) => _Devices(
                            state.pairedDevices
                                .where((device) => !device.isConnected)
                                .map(
                                  (device) => device.copyWith(
                                    isConnecting: state.connectingDevices
                                        .contains(device.macAddress),
                                  ),
                                )
                                .toList(),
                          ),
                          builder: (context, myDevices) {
                            final devices = myDevices.items;
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.myDevices,
                                          style: context.textTheme.titleLarge
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
                                  onTap: () =>
                                      _connectToDevice(context, device),
                                  onSettingsTap: () =>
                                      _navigateToDetails(context, device),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Other Devices Header
                        BlocSelector<
                          BluetoothBloc,
                          BluetoothState,
                          (bool, int)
                        >(
                          selector: (state) => (
                            state.isScanning,
                            state.discoveredDevices.length,
                          ),
                          builder: (context, data) {
                            final (scanning, count) = data;
                            final countStr = count.toString().padLeft(2, '0');

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
                                          style: context.textTheme.titleLarge
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
                              showTopBorder: true,
                              showBottomBorder: true,
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
                                        size: IconButtonSize.small,
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
                              children: const [],
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

          // Discovered Devices Lazy List
          BlocSelector<BluetoothBloc, BluetoothState, (_Devices, bool)>(
            selector: (state) => (
              _Devices(
                state.discoveredDevices
                    .map(
                      (device) => device.copyWith(
                        isConnecting: state.connectingDevices.contains(
                          device.macAddress,
                        ),
                      ),
                    )
                    .toList(),
              ),
              state.isBluetoothOn,
            ),
            builder: (context, data) {
              final (discovered, isBluetoothOn) = data;
              if (!isBluetoothOn) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final devices = discovered.items;
              return SliverList.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return BluetoothDeviceListItem(
                    key: ValueKey(device.macAddress),
                    device: device,
                    onTap: () => _connectToDevice(context, device),
                    onSettingsTap: null,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _connectToDevice(BuildContext context, BluetoothDevice device) {
    context.read<BluetoothBloc>().add(ConnectToDeviceEvent(device));
  }

  void _navigateToDetails(BuildContext context, BluetoothDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BluetoothDeviceDetailScreen(
          macAddress: device.macAddress,
          title: device.name,
        ),
      ),
    );
  }

  void _navigateToAboutDevice(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AboutDeviceScreen()));
  }
}

/// Wraps device lists with value equality to prevent unnecessary rebuilds.
class _Devices extends Equatable {
  const _Devices(this.items);
  final List<BluetoothDevice> items;

  @override
  List<Object?> get props => [items];
}
