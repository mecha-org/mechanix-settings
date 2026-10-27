import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/forget_network_bottom_sheet.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/network_details_body.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

/// Details page of a single Wi-Fi network.
///
/// The page itself does not listen to [WirelessBloc]: the app bar only needs
/// [networkName], and every section of [NetworkDetailsBody] selects just the
/// fields it renders. Scan/signal updates therefore rebuild only the rows
/// whose values actually changed.
class NetworkDetailScreen extends StatelessWidget {
  final String networkName;

  const NetworkDetailScreen({super.key, required this.networkName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
            style: const MenuThemeDataConfig(borderRadius: BorderRadius.zero),
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
                  // Reload this network's profile/IP details only;
                  context.read<WirelessBloc>().add(
                    RefreshNetworkDetails(networkName),
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
                  final network = context
                      .read<WirelessBloc>()
                      .state
                      .findNetwork(networkName);

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
      body: NetworkDetailsBody(networkName: networkName),
    );
  }
}
