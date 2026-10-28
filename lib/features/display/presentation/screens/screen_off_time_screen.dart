import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';
import 'package:mechanix_settings/features/display/blocs/display_state.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class ScreenOffTimeScreen extends StatelessWidget {
  const ScreenOffTimeScreen({super.key});

  static const List<int> _timeoutOptions = [10, 30, 60, 120, 300, 0];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
        leading: MechanixIconButton.standard(
          size: IconButtonSize.small,
          icon: ImageIcon(
            const AssetImage(SettingIcons.back),
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        leadingWidth: 48,
        title: Text(
          l10n.screenOffTime,
          style: theme.textTheme.headlineSmall!.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: BlocSelector<DisplayBloc, DisplayState, int>(
          selector: (state) => state.screenTimeout,
          builder: (context, currentScreenTimeout) {
            return ListView.separated(
              itemCount: _timeoutOptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final int value = _timeoutOptions[index];
                final String label = getScreenTimeoutLabel(l10n, value);
                final bool isSelected = currentScreenTimeout == value;

                void select() {
                  context.read<DisplayBloc>().add(SetScreenTimeout(value));
                }

                return MechanixListTile(
                  key: ValueKey<int>(value),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  gap: 12,
                  height: 68,
                  onTap: select,
                  leadingWidgets: [
                    MechanixRadio<int>(
                      value: value,
                      groupValue: currentScreenTimeout,
                      onChanged: (_) => select(),
                    ),
                  ],
                  label: Text(
                    label,
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onSecondaryFixed
                          : theme.colorScheme.onPrimaryFixed,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
