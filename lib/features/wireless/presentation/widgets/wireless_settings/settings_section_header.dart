import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SettingsSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 18,
              color: AppColors.onSurfaceVariantDark,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
