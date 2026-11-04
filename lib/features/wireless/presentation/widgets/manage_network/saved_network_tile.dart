import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/forget_network_bottom_sheet.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wifi_signal_icon.dart';
import 'package:widgets/widgets.dart';

class SavedNetworkTile extends StatelessWidget {
  final WifiNetwork network;

  const SavedNetworkTile({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MechanixListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NetworkDetailScreen(networkName: network.name),
          ),
        );
      },
      leadingWidgets: [WifiSignalIcon(type: network.signalType)],
      label: Text(
        network.name,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onPrimaryFixed,
        ),
      ),
      trailingWidgets: [
        MechanixIconButton.standard(
          size: IconButtonSize.small,
          type: IconButtonType.rounded,
          icon: ImageIcon(
            const AssetImage(SettingIcons.setting),
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NetworkDetailScreen(networkName: network.name),
              ),
            );
          },
        ),
        MechanixIconButton.filled(
          backgroundColor: theme.colorScheme.secondaryContainer,
          size: IconButtonSize.small,
          type: IconButtonType.rounded,
          icon: ImageIcon(
            const AssetImage(SettingIcons.delete),
            color: colorScheme.error,
            size: 24,
          ),
          onPressed: () {
            showForgetNetworkBottomSheet(context: context, network: network);
          },
        ),
      ],
    );
  }
}
