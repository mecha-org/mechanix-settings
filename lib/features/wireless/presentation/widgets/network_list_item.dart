import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

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
    return Material(
      color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: isConnecting ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Leading status icon
              if (isConnecting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.onSurface,
                    ),
                  ),
                )
              else
                WifiSignalIcon(type: signalType),
              const SizedBox(width: 16),

              // Network name and status subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.bodyLarge),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (isConnected)
                const CustomImage(assetPath: SettingIcons.connected),

              const SizedBox(width: 16),

              // Trailing action or gear
              if (onSettingsTap != null)
                CustomIconButton.asset(
                  assetPath: SettingIcons.setting,
                  onPressed: onSettingsTap,
                  padding: EdgeInsets.zero,
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
