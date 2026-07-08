import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final bool showConnectedIcon;

  const InfoRow({
    super.key,
    required this.title,
    required this.value,
    this.showConnectedIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showConnectedIcon) ...[
            const CustomImage(assetPath: SettingIcons.connected),
            const SizedBox(width: 6),
          ],
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
