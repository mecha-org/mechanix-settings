import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/forget_network_bottom_sheet.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/network_details_body.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class NetworkDetailScreen extends StatelessWidget {
  final String networkName;

  const NetworkDetailScreen({super.key, required this.networkName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<WirelessBloc, WirelessState, WifiNetwork>(
      selector: (state) {
        return state.savedNetworks.firstWhere(
          (n) => n.name == networkName,
          orElse: () => state.availableNetworks.firstWhere(
            (n) => n.name == networkName,
            orElse: () => WifiNetwork(name: networkName),
          ),
        );
      },
      builder: (context, network) {
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
              networkName,
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w300,
              ),
            ),
            actions: [
              MechanixMenu(
                alignment: MechanixMenuAlignment.end,
                anchorBuilder: (context, controller, child) {
                  return MechanixIconButton.standard(
                    type: IconButtonType.rounded,
                    size: IconButtonSize.small,
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.moreVert),
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    onPressed: () {
                      controller.toggle();
                    },
                  );
                },
                entries: [
                  MechanixMenuItem(
                    value: 'refresh',
                    leading: ImageIcon(
                      const AssetImage(SettingIcons.refresh),
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    label: Text(
                      l10n.refresh,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryFixed,
                        letterSpacing: 1,
                      ),
                    ),
                    onTap: () {
                      context.read<WirelessBloc>().add(
                        const LoadWireless(requestScan: true),
                      );
                    },
                  ),
                  MechanixMenuItem(
                    value: 'forget',
                    leading: ImageIcon(
                      const AssetImage(SettingIcons.delete),
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      l10n.forgetNetwork,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                        letterSpacing: 1,
                      ),
                    ),
                    onTap: () {
                      showForgetNetworkBottomSheet(
                        context: context,
                        network: network,
                        onConfirmed: () => Navigator.pop(context),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          body: NetworkDetailsBody(network: network, networkName: networkName),
        );
      },
    );
  }
}

void connectToNetwork(BuildContext context, WifiNetwork network) {
  final bloc = context.read<WirelessBloc>();

  if (bloc.state.connectedNetworkName == network.name) {
    return;
  }

  bloc.add(ConnectToNetworkEvent(network.name, null));
}
