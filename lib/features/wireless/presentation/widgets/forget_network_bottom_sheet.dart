import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

Future<void> showForgetNetworkBottomSheet({
  required BuildContext context,
  required WifiNetwork network,
  VoidCallback? onConfirmed,
}) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;
  final colorScheme = theme.colorScheme;

  return MechanixBottomSheet.showModal(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.forgetWifiPrompt(network.name),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: MechanixButton.outline(
                    key: const Key('delete_network_cancel_button'),
                    size: ButtonSize.large,
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.cancel),
                      size: 32,
                      color: colorScheme.onSurface,
                    ),
                    label: l10n.close.toUpperCase(),
                    onPressed: () => Navigator.pop(sheetContext, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MechanixButton(
                    key: const Key('delete_network_delete_button'),
                    size: ButtonSize.large,
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.delete),
                      color: colorScheme.error,
                      size: 32,
                    ),
                    label: l10n.forget.toUpperCase(),
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    foregroundColor: colorScheme.error,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      context.read<WirelessBloc>().add(
                        ForgetNetworkEvent(network),
                      );
                      onConfirmed?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
