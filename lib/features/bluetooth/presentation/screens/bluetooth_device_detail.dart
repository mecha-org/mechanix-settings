import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_app_bar.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/info_row.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class BluetoothDeviceDetailScreen extends StatefulWidget {
  final String deviceName;

  const BluetoothDeviceDetailScreen({super.key, required this.deviceName});

  @override
  State<BluetoothDeviceDetailScreen> createState() =>
      _BluetoothDeviceDetailScreenState();
}

class _BluetoothDeviceDetailScreenState
    extends State<BluetoothDeviceDetailScreen> {
  final ScrollController _breadcrumbScrollController = ScrollController();

  @override
  void dispose() {
    _breadcrumbScrollController.dispose();
    super.dispose();
  }

  String _getLocalizedType(BluetoothDeviceType type, AppLocalizations l10n) {
    switch (type) {
      case BluetoothDeviceType.mobile:
        return l10n.mobileType;
      case BluetoothDeviceType.speaker:
        return l10n.speakerType;
      case BluetoothDeviceType.other:
        return l10n.otherType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BluetoothBloc, BluetoothState>(
      builder: (context, state) {
        final device = state.pairedDevices.firstWhere(
          (d) => d.name == widget.deviceName,
          orElse: () => state.discoveredDevices.firstWhere(
            (d) => d.name == widget.deviceName,
            orElse: () => BluetoothDevice(
              name: widget.deviceName,
              deviceName: widget.deviceName,
              type: BluetoothDeviceType.other,
            ),
          ),
        );

        return Scaffold(
          appBar: BluetoothAppBar(
            deviceName: widget.deviceName,
            breadcrumbController: _breadcrumbScrollController,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(title: l10n.deviceName, value: device.deviceName),
                InfoRow(
                  title: l10n.deviceType,
                  value: _getLocalizedType(device.type, l10n),
                ),
                InfoRow(
                  title: l10n.deviceStatus,
                  value: device.isConnected
                      ? l10n.connected
                      : l10n.notConnected,
                  showConnectedIcon: device.isConnected ? true : false,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomBar(
            leading: CustomIconButton.asset(
              assetPath: SettingIcons.back,
              enabled: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            center: [
              if (device.isConnected) ...[
                // Disconnect
                CustomIconButton.asset(
                  assetPath: SettingIcons.disconnect,
                  enabled: true,
                  onPressed: () {
                    context.read<BluetoothBloc>().add(
                      DisconnectFromDeviceEvent(device),
                    );
                    Navigator.pop(context);
                  },
                ),
              ] else ...[
                // Connect
                CustomIconButton.asset(
                  assetPath: SettingIcons.connect,
                  enabled: true,
                  onPressed: () {
                    context.read<BluetoothBloc>().add(
                      ConnectToDeviceEvent(device),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
            trailing: [
              // Forget
              CustomIconButton.asset(
                assetPath: SettingIcons.delete,
                enabled: true,
                onPressed: () {
                  context.read<BluetoothBloc>().add(ForgetDeviceEvent(device));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
