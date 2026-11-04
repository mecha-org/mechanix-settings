import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/security_bottom_sheet.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class SecuritySelector extends StatelessWidget {
  final WirelessSecurity security;
  final ValueChanged<WirelessSecurity> onChanged;

  const SecuritySelector({
    super.key,
    required this.security,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return MechanixListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      label: Text(
        l10n.security,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSecondaryFixed,
        ),
      ),
      trailingWidgets: [
        Text(
          security.label(l10n),
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        MechanixIconButton.standard(
          type: IconButtonType.rounded,
          onPressed: () async {
            final selected = await SecurityBottomSheet.show(
              context: context,
              currentSecurity: security,
            );

            if (selected != null) {
              onChanged(selected);
            }
          },
          icon: ImageIcon(
            const AssetImage(SettingIcons.caretRight),
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
      ],
      onTap: () async {
        final selected = await SecurityBottomSheet.show(
          context: context,
          currentSecurity: security,
        );

        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}
