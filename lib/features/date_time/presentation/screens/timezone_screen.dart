import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/check_box/circular_checkbox.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_state.dart';
import 'package:mechanix_settings/features/date_time/data/models/time_zones.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class TimezoneScreen extends StatefulWidget {
  const TimezoneScreen({super.key});

  @override
  State<TimezoneScreen> createState() => _TimezoneScreenState();
}

class _TimezoneScreenState extends State<TimezoneScreen> {
  final ScrollController _breadcrumbController = ScrollController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocSelector<DateTimeBloc, DateTimeState, String>(
      selector: (state) => state.timezone,
      builder: (context, selectedTimezone) {
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
                  label: l10n.timeAndDate,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                BreadcrumbItem(label: l10n.timezone, onTap: () {}),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: CustomDivider(verticalPadding: 0),
            ),
          ),
          body: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: true,
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: timezones.length,
              itemBuilder: (context, index) {
                final timezone = timezones[index];
                final isSelected = selectedTimezone == timezone.id;

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        context.read<DateTimeBloc>().add(
                          UpdateTimezoneEvent(timezone.id),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Row(
                          children: [
                            CustomCircleCheckbox(
                              isChecked: isSelected,
                              onTap: () {
                                context.read<DateTimeBloc>().add(
                                  UpdateTimezoneEvent(timezone.id),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                timezone.getLocalizedLabel(context),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isSelected
                                      ? AppColors.onSurface
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
