import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/add_network_body.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class AddNetworkPage extends StatelessWidget {
  AddNetworkPage({super.key});

  final _formKey = GlobalKey<AddNetworkBodyState>();

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
          l10n.joinNetworkTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          MechanixIconButton.filled(
            backgroundColor: theme.colorScheme.secondaryContainer,
            size: IconButtonSize.small,
            type: IconButtonType.rounded,
            icon: ImageIcon(
              const AssetImage(SettingIcons.check),
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
            onPressed: () async {
              final success = await _formKey.currentState?.connect();

              if (success == true && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AddNetworkBody(key: _formKey),
    );
  }
}
