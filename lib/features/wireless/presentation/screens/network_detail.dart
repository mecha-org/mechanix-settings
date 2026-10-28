import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/forget_network_bottom_sheet.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/network_details_body.dart';
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
          MechanixIconButton.filled(
            key: const Key('network_detail_forget_button'),
            backgroundColor: theme.colorScheme.secondaryContainer,
            size: IconButtonSize.small,
            type: IconButtonType.rounded,
            icon: ImageIcon(
              const AssetImage(SettingIcons.delete),
              color: theme.colorScheme.error,
              size: 24,
            ),
            onPressed: () {
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
      body: NetworkDetailsBody(networkName: networkName),
    );
  }
}
