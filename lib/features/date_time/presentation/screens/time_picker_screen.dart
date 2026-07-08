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
import 'package:mechanix_settings/features/date_time/presentation/widgets/time_picker/time_picker.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class TimePickerScreen extends StatefulWidget {
  const TimePickerScreen({super.key});

  @override
  State<TimePickerScreen> createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  late int _selectedHour;
  late int _selectedMinute;
  late bool _selectedIsAm;
  late bool _is12Hour;

  bool _initialized = false;

  void _initializeValues(DateTimeState state, AppLocalizations l10n) {
    if (_initialized) return;
    _is12Hour = state.timeFormat == l10n.format12Hour;
    _selectedHour = state.hour;
    _selectedMinute = state.minute;
    _selectedIsAm = state.isAm;

    if (_is12Hour) {
      _selectedHour = state.hour;
    } else {
      if (state.isAm == false && state.hour < 12) {
        _selectedHour = state.hour + 12;
      } else if (state.isAm == true && state.hour == 12) {
        _selectedHour = 0;
      } else {
        _selectedHour = state.hour;
      }
    }

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
        _initializeValues(state, l10n);

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
                BreadcrumbItem(label: l10n.setTime),
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
                  CustomTimePicker(
                    selectedHour: _selectedHour,
                    selectedMinute: _selectedMinute,
                    isAm: _selectedIsAm,
                    is12Hour: _is12Hour,
                    onHourChanged: (v) => setState(() => _selectedHour = v),
                    onMinuteChanged: (v) => setState(() => _selectedMinute = v),
                    onAmPmChanged: (v) => setState(() {
                      _selectedIsAm = v;
                    }),
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
                  int finalHour = _selectedHour;
                  bool finalIsAm = _selectedIsAm;

                  if (!_is12Hour) {
                    if (_selectedHour >= 12) {
                      finalIsAm = false;
                      finalHour = _selectedHour > 12 ? _selectedHour - 12 : 12;
                    } else {
                      finalIsAm = true;
                      finalHour = _selectedHour == 0 ? 12 : _selectedHour;
                    }
                  }

                  context.read<DateTimeBloc>().add(
                    UpdateTimeEvent(finalHour, _selectedMinute, finalIsAm),
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
