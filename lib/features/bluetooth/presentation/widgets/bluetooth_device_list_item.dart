import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';

class BluetoothDeviceListItem extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;
  final VoidCallback? onSettingsTap;

  const BluetoothDeviceListItem({
    super.key,
    required this.device,
    required this.onTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: device.isConnecting ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  device.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

              if (device.isConnecting)
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
              else if (device.isConnected)
                const CustomImage(assetPath: SettingIcons.connected),

              if ((device.isConnecting || device.isConnected) &&
                  device.isSaved &&
                  onSettingsTap != null)
                const SizedBox(width: 16),

              if (device.isSaved && onSettingsTap != null)
                CustomIconButton.asset(
                  assetPath: SettingIcons.setting,
                  onPressed: onSettingsTap,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
