import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class SecurityBottomSheet extends StatefulWidget {
  final WirelessSecurity currentSecurity;

  const SecurityBottomSheet({
    super.key,
    required this.currentSecurity,
  });

  static Future<WirelessSecurity?> show({
    required BuildContext context,
    required WirelessSecurity currentSecurity,
  }) {
    return MechanixBottomSheet.showModal<WirelessSecurity>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SecurityBottomSheet(
          currentSecurity: currentSecurity,
        );
      },
    );
  }

  @override
  State<SecurityBottomSheet> createState() => _SecurityBottomSheetState();
}

class _SecurityBottomSheetState extends State<SecurityBottomSheet> {
  late WirelessSecurity _selectedSecurity;

  static const List<WirelessSecurity> _securityOptions = [
    WirelessSecurity.none,
    WirelessSecurity.wep,
    WirelessSecurity.wpaWpa2Personal,
    WirelessSecurity.wpa3Personal,
  ];

  @override
  void initState() {
    super.initState();
    _selectedSecurity = widget.currentSecurity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              MechanixIconButton.standard(
                icon: ImageIcon(
                  const AssetImage(SettingIcons.back),
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 8),
              Text(
                l10n.security,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              MechanixIconButton.standard(
                icon: ImageIcon(
                  const AssetImage(SettingIcons.check),
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  Navigator.of(context).pop(_selectedSecurity);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Radio options
          ..._securityOptions.map((option) {
            return MechanixListTile(
              key: ValueKey('option_security_${option.name}'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leadingWidgets: [
                MechanixRadio<WirelessSecurity>(
                  value: option,
                  groupValue: _selectedSecurity,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSecurity = val);
                    }
                  },
                ),
              ],
              labelText: option.label(l10n),
              onTap: () {
                setState(() => _selectedSecurity = option);
              },
            );
          }),
        ],
      ),
    );
  }
}
