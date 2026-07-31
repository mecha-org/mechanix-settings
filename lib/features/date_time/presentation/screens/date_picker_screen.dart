import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_state.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/date_picker/date_picker.dart';
import 'package:mechanix_settings/features/date_time/presentation/widgets/date_picker/date_picker_utils.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class DatePickerScreen extends StatefulWidget {
  const DatePickerScreen({super.key});

  @override
  State<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;
  bool _initialized = false;

  void _initializeValues(DateTimeState state) {
    if (_initialized) return;
    _selectedDay = state.day;
    _selectedMonth = state.month;
    _selectedYear = state.year;
    _initialized = true;
  }

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DateTimeBloc, DateTimeState>(
      builder: (context, state) {
        _initializeValues(state);

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
                BreadcrumbItem(label: l10n.setDate),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: CustomDivider(verticalPadding: 0),
            ),
          ),
          body: Center(
            child: Container(
              height: 240,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomDatePicker(
                    selectedDay: _selectedDay,
                    selectedMonth: _selectedMonth,
                    selectedYear: _selectedYear,

                    onDayChanged: (v) {
                      setState(() {
                        _selectedDay = v;
                      });
                    },

                    onMonthChanged: (v) {
                      setState(() {
                        _selectedMonth = v;

                        final max = getDaysInMonth(_selectedYear, v);

                        if (_selectedDay > max) {
                          _selectedDay = max;
                        }
                      });
                    },

                    onYearChanged: (v) {
                      setState(() {
                        _selectedYear = v;

                        final max = getDaysInMonth(v, _selectedMonth);

                        if (_selectedDay > max) {
                          _selectedDay = max;
                        }
                      });
                    },
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
            trailing: [
              CustomIconButton.asset(
                assetPath: SettingIcons.check,
                enabled: true,
                onPressed: () {
                  context.read<DateTimeBloc>().add(
                    UpdateDateEvent(
                      _selectedYear,
                      _selectedMonth,
                      _selectedDay,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
