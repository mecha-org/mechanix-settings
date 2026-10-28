import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/manage_network/manage_network_body.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class ManageNetworksScreen extends StatelessWidget {
  const ManageNetworksScreen({super.key});

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
          l10n.manageNetworks,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      body: const ManageNetworksBody(),
    );
  }
}
