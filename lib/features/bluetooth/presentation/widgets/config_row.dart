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
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
