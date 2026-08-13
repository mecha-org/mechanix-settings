import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_body.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_app_bar.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BluetoothBloc>().add(const ScanBluetoothDevices());
      }
    });
  }

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothBloc, BluetoothState>(
      builder: (context, state) {
        return Scaffold(
          appBar: BluetoothAppBar(breadcrumbController: _breadcrumbController),
          body: BlocListener<BluetoothBloc, BluetoothState>(
            listenWhen: (previous, current) =>
                current.error != null && previous.error != current.error,
            listener: (context, state) {
              if (state.error != null) {
                final failure = state.error!;
                final l10n = AppLocalizations.of(context)!;
                String message = '';

                final deviceName = failure.data?['deviceName'] as String?;

                switch (failure.type) {
                  case BluetoothErrorType.connectionFailed:
                    if (deviceName != null) {
                      message = l10n.bluetoothConnectionFailedWithName(
                        deviceName,
                      );
                    } else {
                      message = l10n.bluetoothConnectionFailed;
                    }
                    break;
                  case BluetoothErrorType.pairingFailed:
                    if (deviceName != null) {
                      message = l10n.bluetoothPairingFailedWithName(deviceName);
                    } else {
                      message = l10n.bluetoothPairingFailed;
                    }
                    break;
                  case BluetoothErrorType.unknown:
                    message = l10n.unknownError;
                    break;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const BluetoothBody(),
          ),
          bottomNavigationBar: BottomBar(
            leading: CustomIconButton.asset(
              assetPath: SettingIcons.back,
              enabled: true,
              onPressed: () {
                context.read<BluetoothBloc>().add(
                  const StopBluetoothDiscovery(),
                );
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }
}
