import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless/wireless_body.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless/wireless_app_bar.dart';

import 'package:mechanix_settings/l10n/app_localizations.dart';

class WirelessScreen extends StatefulWidget {
  const WirelessScreen({super.key});

  @override
  State<WirelessScreen> createState() => _WirelessScreenState();
}

class _WirelessScreenState extends State<WirelessScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WirelessAppBar(breadcrumbController: _breadcrumbController),
      body: BlocListener<WirelessBloc, WirelessState>(
        listenWhen: (previous, current) =>
            current.error != null && previous.error != current.error,
        listener: (context, state) {
          if (state.error != null) {
            final failure = state.error!;
            final l10n = AppLocalizations.of(context)!;
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

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: const WirelessBody(),
      ),
      bottomNavigationBar:
          BlocSelector<
            WirelessBloc,
            WirelessState,
            ({bool isWirelessOn, bool isScanning})
          >(
            selector: (state) => (
              isWirelessOn: state.isWirelessOn,
              isScanning: state.isScanning,
            ),
            builder: (context, state) {
              return BottomBar(
                leading: CustomIconButton.asset(
                  assetPath: SettingIcons.back,
                  enabled: true,
                  onPressed: () => Navigator.pop(context),
                ),
                trailing: state.isWirelessOn && !state.isScanning
                    ? [
                        CustomIconButton.asset(
                          assetPath: SettingIcons.refresh,
                          enabled: true,
                          onPressed: () {
                            context.read<WirelessBloc>().add(
                              const ToggleWirelessPower(true),
                            );
                          },
                        ),
                      ]
                    : null,
              );
            },
          ),
    );
  }
}
