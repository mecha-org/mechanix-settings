import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless/wireless_body.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class WirelessScreen extends StatelessWidget {
  const WirelessScreen({super.key});

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
          l10n.wireless.toUpperCase(),
          style: theme.textTheme.headlineSmall!.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocListener<WirelessBloc, WirelessState>(
        listenWhen: (previous, current) =>
            current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            final failure = state.error!;
            String message = '';

            final networkName = failure.data?['networkName'] as String?;

            switch (failure.type) {
              case WirelessErrorType.connectionFailed:
                if (networkName != null) {
                  message = l10n.connectionFailedWithNetwork(networkName);
                } else {
                  message = l10n.connectionFailed;
                }
                break;
              case WirelessErrorType.addNetworkFailed:
                if (networkName != null) {
                  message = l10n.addNetworkFailedWithNetwork(networkName);
                } else {
                  message = l10n.addNetworkFailed;
                }
                break;
              case WirelessErrorType.unknown:
                message = l10n.unknownError;
                break;
            }

            MechanixSnackbar.text(
              position: MechanixSnackbarPosition.top,
              text: message,
            ).show(context);
          }
        },
        child: const WirelessBody(),
      ),
    );
  }
}
