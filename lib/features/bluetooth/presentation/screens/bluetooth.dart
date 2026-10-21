import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_body.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final ScrollController _breadcrumbController = ScrollController();
  late final BluetoothBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<BluetoothBloc>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bloc.add(const ScanBluetoothDevices());
      }
    });
  }

  @override
  void dispose() {
    _bloc.add(const StopBluetoothDiscovery());
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
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
          l10n.bluetooth.toUpperCase(),
          style: theme.textTheme.headlineSmall!.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
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
                  message = l10n.bluetoothConnectionFailedWithName(deviceName);
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

            MechanixSnackbar.text(
              position: MechanixSnackbarPosition.top,
              text: message,
            ).show(context);
          }
        },
        child: const BluetoothBody(),
      ),
    );
  }
}
