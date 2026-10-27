import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';
import 'package:widgets/widgets.dart';

class BluetoothConnectedDeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;
  final VoidCallback? onSettingsTap;

  const BluetoothConnectedDeviceTile({
    super.key,
    required this.device,
    required this.onTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MechanixListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onTap: device.isConnecting ? null : onTap,
      leadingWidgets: [
        ImageIcon(
          const AssetImage(SettingIcons.ellipse),
          color: colorScheme.primary,
          size: 8,
        ),
        ImageIcon(
          AssetImage(device.type.icon),
          color: colorScheme.onSurface,
          size: 20,
        ),
      ],
      label: Text(
        device.name,
        style: Theme.of(
          context,
        ).textTheme.titleLarge!.copyWith(color: colorScheme.onSurface),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailingWidgets: [
        if (device.isConnecting)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onSurface),
            ),
          ),

        if (device.isSaved && onSettingsTap != null)
          MechanixIconButton.standard(
            icon: ImageIcon(
              const AssetImage(SettingIcons.setting),
              color: colorScheme.onSurface,
              size: 20,
            ),
            type: IconButtonType.rounded,
            onPressed: onSettingsTap,
          ),
      ],
    );
  }
}
