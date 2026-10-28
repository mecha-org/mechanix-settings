import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';
import 'package:mechanix_settings/features/display/blocs/display_state.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class ScreenOffTimeScreen extends StatefulWidget {
  const ScreenOffTimeScreen({super.key});

  @override
  State<ScreenOffTimeScreen> createState() => _ScreenOffTimeScreenState();
}

class _ScreenOffTimeScreenState extends State<ScreenOffTimeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> options = [
      {'label': l10n.screenOffTenSeconds, 'value': 10},
      {'label': l10n.screenOffThirtySeconds, 'value': 30},
      {'label': l10n.screenOffOneMinute, 'value': 60},
      {'label': l10n.screenOffTwoMinutes, 'value': 120},
      {'label': l10n.screenOffFiveMinutes, 'value': 300},
      {'label': l10n.screenOffNever, 'value': 0},
    ];

    return BlocBuilder<DisplayBloc, DisplayState>(
      builder: (context, state) {
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
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final int value = option['value'] as int;
                final String label = option['label'] as String;
                final bool isSelected = state.screenTimeout == value;

                void select() {
                  context.read<DisplayBloc>().add(SetScreenTimeout(value));
                }

                return MechanixListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  gap: 12,
                  height: 68,
                  onTap: select,
                  leadingWidgets: [
                    MechanixRadio<int>(
                      value: value,
                      groupValue: state.screenTimeout,
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
            ),
          ),
        );
      },
    );
  }
}
