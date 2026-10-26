import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:widgets/widgets.dart';

import 'wifi_signal_icon.dart';

class NetworkListItem extends StatelessWidget {
  final String name;
  final String? subtitle;
  final bool isConnected;
  final bool isConnecting;
  final bool isSelected;
  final WifiSignalType signalType;
  final VoidCallback onTap;
  final VoidCallback? onSettingsTap;

  const NetworkListItem({
    super.key,
    required this.name,
    this.subtitle,
    this.isConnected = false,
    this.isConnecting = false,
    this.isSelected = false,
    required this.signalType,
    required this.onTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MechanixListTile(
      onTap: isConnecting ? null : onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: onSettingsTap != null ? 8 : 18,
      ),
      leadingWidgets: [
        if (isConnected)
          ImageIcon(
            const AssetImage(SettingIcons.ellipse),
            color: theme.colorScheme.primary,
            size: 8,
          ),
        // Leading status icon
        if (isConnecting)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          )
        else
          WifiSignalIcon(type: signalType),
      ],
      // Network name and status subtitle
      label: Text(name, style: Theme.of(context).textTheme.titleLarge),
      supportingText: (subtitle?.isNotEmpty ?? false) ? subtitle : null,
      // Trailing action or gear
      trailingWidgets: [
        if (onSettingsTap != null)
          MechanixIconButton.standard(
            size: IconButtonSize.small,
            icon: ImageIcon(
              const AssetImage(SettingIcons.setting),
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
            type: IconButtonType.rounded,
            onPressed: onSettingsTap,
          ),
      ],
    );
  }
}
