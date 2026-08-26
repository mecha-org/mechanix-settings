import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/check_box/circular_checkbox.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';
import 'package:mechanix_settings/features/display/blocs/display_state.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class ScreenOffTimeScreen extends StatefulWidget {
  const ScreenOffTimeScreen({super.key});

  @override
  State<ScreenOffTimeScreen> createState() => _ScreenOffTimeScreenState();
}

class _ScreenOffTimeScreenState extends State<ScreenOffTimeScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

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
          appBar: AppBar(
            scrolledUnderElevation: 0,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: AppBreadcrumbs(
              scrollController: _breadcrumbController,
              items: [
                BreadcrumbItem(
                  label: l10n.settings,
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                BreadcrumbItem(
                  label: l10n.display,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                BreadcrumbItem(label: l10n.screenOffTime),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: CustomDivider(verticalPadding: 0),
            ),
          ),
          body: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final int value = option['value'] as int;
                final String label = option['label'] as String;
                final bool isSelected = state.screenTimeout == value;

                return InkWell(
                  onTap: () {
                    context.read<DisplayBloc>().add(SetScreenTimeout(value));
                    // Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: isSelected
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                          ),
                        ),

                        CustomCircleCheckbox(
                          isChecked: isSelected,
                          onTap: () {
                            context.read<DisplayBloc>().add(
                              SetScreenTimeout(value),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: BottomBar(
            leading: CustomIconButton.asset(
              assetPath: SettingIcons.back,
              enabled: true,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }
}
