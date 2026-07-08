import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_rename.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_device_list_item.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/config_row.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/connection_sheets.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_section_header.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class BluetoothBody extends StatefulWidget {
  const BluetoothBody({super.key});

  @override
  State<BluetoothBody> createState() => _BluetoothBodyState();
}

class _BluetoothBodyState extends State<BluetoothBody> {
  bool _isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<BluetoothBloc, BluetoothState>(
      listener: (context, state) {
        final bloc = context.read<BluetoothBloc>();

        // Handle PIN input sheet
        if (state.pairingRequestDevice != null && !_isDialogShowing) {
          _isDialogShowing = true;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => PairingPinInputSheet(
              deviceName: state.pairingRequestDevice!.name,
              onSubmit: (pin) {
                bloc.add(CompletePairingEvent(state.pairingRequestDevice!));
                Navigator.pop(context);
              },
              onCancel: () {
                bloc.add(const CancelPairingEvent());
                Navigator.pop(context);
              },
            ),
          ).then((_) {
            _isDialogShowing = false;
            if (bloc.state.pairingRequestDevice != null) {
              bloc.add(const CancelPairingEvent());
            }
          });
        }

        // Handle Connection Code Display sheet
        if (state.pairingCodeDisplayDevice != null && !_isDialogShowing) {
          _isDialogShowing = true;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ConnectionCodeSheet(
              deviceName: state.pairingCodeDisplayDevice!.name,
              code: '445120',
              onCancel: () {
                bloc.add(const CancelPairingEvent());
                Navigator.pop(context);
              },
              onPair: () {
                bloc.add(CompletePairingEvent(state.pairingCodeDisplayDevice!));
                Navigator.pop(context);
              },
            ),
          ).then((_) {
            _isDialogShowing = false;
            if (bloc.state.pairingCodeDisplayDevice != null) {
              bloc.add(const CancelPairingEvent());
            }
          });
        }
      },
      child: BlocBuilder<BluetoothBloc, BluetoothState>(
        builder: (context, state) {
          final isBluetoothOn = state.isBluetoothOn;
          final isScanning = state.isScanning;
          final pairedDevices = state.pairedDevices;
          final discoveredDevices = state.discoveredDevices;
          // Separate the connected devices
          final connectedList = pairedDevices
              .where((d) => d.isConnected)
              .toList();
          final otherPaired = pairedDevices
              .where((d) => !d.isConnected)
              .toList();

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bluetooth Toggle Row
                  Padding(
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
                          onChanged: (val) {
                            context.read<BluetoothBloc>().add(
                              ToggleBluetoothPower(val),
                            );
                          },
                          l10n: l10n,
                        ),
                      ],
                    ),
                  ),
                  const CustomDivider(verticalPadding: 0),

                  ConfigRow(
                    title: l10n.deviceName,
                    value: state.localDeviceName,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BluetoothRenameScreen(),
                        ),
                      );
                    },
                  ),
                  const CustomDivider(verticalPadding: 0),

                  if (isBluetoothOn) ...[
                    // Connected Device Section
                    if (connectedList.isNotEmpty) ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: connectedList.length,
                        itemBuilder: (context, index) {
                          final device = connectedList[index];
                          return Column(
                            children: [
                              BluetoothDeviceListItem(
                                device: device,
                                onTap: () {},
                                onSettingsTap: () =>
                                    _navigateToDetails(context, device),
                              ),
                            ],
                          );
                        },
                      ),
                      const CustomDivider(verticalPadding: 0),
                    ],

                    // Paired/My Devices List
                    SettingsSectionHeader(title: l10n.myDevices),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: otherPaired.length,
                      itemBuilder: (context, index) {
                        final device = otherPaired[index];
                        return Column(
                          children: [
                            BluetoothDeviceListItem(
                              device: device,
                              onTap: () => _connectToDevice(context, device),
                              onSettingsTap: () =>
                                  _navigateToDetails(context, device),
                            ),
                          ],
                        );
                      },
                    ),
                    const CustomDivider(verticalPadding: 16),

                    // Discovered/Other Devices List
                    SettingsSectionHeader(title: l10n.otherDevices),
                    if (isScanning) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: discoveredDevices.length,
                        itemBuilder: (context, index) {
                          final device = discoveredDevices[index];
                          return Column(
                            children: [
                              BluetoothDeviceListItem(
                                device: device,
                                onTap: () => _connectToDevice(context, device),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                      ),
                    ],
                    const CustomDivider(verticalPadding: 16),
                  ],
                ],
              ),
            ),
          );
        },
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
