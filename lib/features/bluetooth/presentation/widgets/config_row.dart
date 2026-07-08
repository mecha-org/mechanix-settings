import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

class ConfigRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const ConfigRow({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
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
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: AppColors.onSurfaceVariant,
            size: 28,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
