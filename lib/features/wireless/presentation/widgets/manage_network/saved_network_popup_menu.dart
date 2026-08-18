import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

enum SavedNetworkAction { about, forget }

class SavedNetworkPopupMenu extends StatelessWidget {
  final VoidCallback onAbout;
  final VoidCallback onForget;

  const SavedNetworkPopupMenu({
    super.key,
    required this.onAbout,
    required this.onForget,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SavedNetworkAction>(
      tooltip: '',
      icon: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: const Icon(Icons.more_vert, size: 20),
      ),
      position: PopupMenuPosition.under,
      onSelected: (value) {
        switch (value) {
          case SavedNetworkAction.about:
            onAbout();
            break;

          case SavedNetworkAction.forget:
            onForget();
            break;
        }
      },

      itemBuilder: (_) => [
        PopupMenuItem(
          value: SavedNetworkAction.about,
          child: Row(
            children: [
              const CustomImage(
                assetPath: SettingIcons.setting,
                size: 20,
                color: AppColors.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.about,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: SavedNetworkAction.forget,
          child: Row(
            children: [
              const CustomImage(
                assetPath: SettingIcons.forget,
                size: 20,
                color: AppColors.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.forget,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
