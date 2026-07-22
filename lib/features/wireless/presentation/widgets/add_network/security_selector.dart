import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/enterprise_row.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return EnterpriseRow(
      label: l10n.security,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<WirelessSecurity>(
            value: security,
            isExpanded: true,

            items: WirelessSecurity.values
                .map(
                  (e) => DropdownMenuItem(value: e, child: Text(e.label(l10n))),
                )
                .toList(),

            onChanged: (value) {
              if (value == null) return;

              onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}
