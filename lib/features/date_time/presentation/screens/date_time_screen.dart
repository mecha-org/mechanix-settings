import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mechanix_settings/core/constants/date_time.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/section_list/section_item.dart';
import 'package:mechanix_settings/core/widgets/section_list/section_list.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_state.dart';
import 'package:mechanix_settings/features/date_time/data/models/enums.dart';
import 'package:mechanix_settings/features/date_time/data/models/time_zones.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/timezone_screen.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/time_picker_screen.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/date_picker_screen.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/time_format_screen.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class DateTimeScreen extends StatefulWidget {
  const DateTimeScreen({super.key});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  String _formatTimezone(String id) {
    return timezones
        .firstWhere((tz) => tz.id == id, orElse: () => TimezoneItem(id: id))
        .getLocalizedLabel(context);
  }

  String _formatTime(DateTimeState state, AppLocalizations l10n) {
    // Format hour/minute as two digits using locale-aware numerals.
    final twoDigit = NumberFormat("00");

    if (state.timeFormat == TimeFormats.hour12) {
      return "${twoDigit.format(state.hour)}:${twoDigit.format(state.minute)} "
          "${state.isAm ? l10n.am : l10n.pm}";
    } else {
      int h24 = state.hour;
      if (!state.isAm && state.hour < 12) h24 += 12;
      if (state.isAm && state.hour == 12) h24 = 0;

      return "${twoDigit.format(h24)}:${twoDigit.format(state.minute)}";
    }
  }

  String _formatDate(DateTimeState state) {
    final date = DateTime(state.year, state.month, state.day);

    return DateFormat("dd MMMM yyyy").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocListener<DateTimeBloc, DateTimeState>(
      listener: (context, state) {
        if (state.status == DateTimeStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getDateTimeErrorMessage(l10n, state.error!)),
            ),
          );
        }
      },
      child: BlocBuilder<DateTimeBloc, DateTimeState>(
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
                  BreadcrumbItem(label: l10n.timeAndDate),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto Time toggle row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.autoTime, style: theme.textTheme.bodyLarge),
                          CustomToggle(
                            value: state.autoTime,
                            onChanged: (val) {
                              context.read<DateTimeBloc>().add(
                                ToggleAutoTimeEvent(val),
                              );
                            },
                            l10n: l10n,
                          ),
                        ],
                      ),
                    ),
                    const CustomDivider(verticalPadding: 0),

                    SectionList(
                      items: [
                        SectionItem(
                          title: l10n.timezone,
                          titleStyle: theme.textTheme.bodyLarge!.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTimezone(state.timezone),
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 24),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimezoneScreen(),
                              ),
                            );
                          },
                        ),
                        if (!state.autoTime) ...[
                          SectionItem(
                            title: l10n.setTime,
                            titleStyle: theme.textTheme.bodyLarge!.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(state, l10n),
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, size: 24),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TimePickerScreen(),
                                ),
                              );
                            },
                          ),
                          SectionItem(
                            title: l10n.setDate,
                            titleStyle: theme.textTheme.bodyLarge!.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatDate(state),
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, size: 24),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DatePickerScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        SectionItem(
                          title: l10n.timeFormat,
                          titleStyle: theme.textTheme.bodyLarge!.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.timeFormat == TimeFormats.hour12
                                    ? l10n.format12Hour
                                    : l10n.format24Hour,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, size: 24),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TimeFormatScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
      ),
    );
  }
}
