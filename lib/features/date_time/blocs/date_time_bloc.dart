import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/date_time.dart';
import 'package:mechanix_settings/features/date_time/data/models/enums.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'date_time_event.dart';
import 'date_time_state.dart';

class _DateTimeTickEvent extends DateTimeEvent {
  const _DateTimeTickEvent();
}

class DateTimeBloc extends Bloc<DateTimeEvent, DateTimeState> {
  final DateTimeRepository _repository;
  Timer? _timer;
  StreamSubscription? _propertiesSubscription;
  bool _timezoneInitialized = false;

  DateTimeBloc(this._repository) : super(DateTimeState.initial()) {
    on<InitializeDateTimeEvent>(_onInitialize);
    on<RefreshDateTimeEvent>(_onRefresh);
    on<_DateTimeTickEvent>(_onTick);
    on<ToggleAutoTimeEvent>(_onToggleAutoTime);
    on<UpdateTimezoneEvent>(_onUpdateTimezone);
    on<UpdateTimeEvent>(_onUpdateTime);
    on<UpdateDateEvent>(_onUpdateDate);
    on<UpdateTimeFormatEvent>(_onUpdateTimeFormat);
  }

  /// Returns the corresponding timezone location for the given timezone ID.
  ///
  /// Normalizes common system timezone aliases (e.g. GMT, Etc/UTC) to the
  /// timezone package's supported IDs before resolving the location.
  /// Falls back to UTC if the timezone cannot be resolved.
  tz.Location _getLocation(String id) {
    _ensureTimezoneInitialized();

    // Normalize system timezone aliases to Dart timezone IDs
    switch (id) {
      case 'GMT':
      case 'Etc/GMT':
      case 'Etc/UTC':
        id = 'UTC';
        break;
    }

    try {
      return tz.getLocation(id);
    } catch (e) {
      AppLogger.e("Timezone location not found: $id, falling back to UTC");

      return tz.UTC;
    }
  }

  /// Initializes the timezone database once for the lifetime of this Bloc.
  void _ensureTimezoneInitialized() {
    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
      _timezoneInitialized = true;
    }
  }

  int _hour24to12(int hour) {
    int h = hour % 12;
    return h == 0 ? 12 : h;
  }

  /// Initializes the date/time settings, subscribes to system property changes,
  /// loads the current configuration, and starts the periodic clock update timer.
  Future<void> _onInitialize(
    InitializeDateTimeEvent event,
    Emitter<DateTimeState> emit,
  ) async {
    _ensureTimezoneInitialized();
    try {
      await _repository.init();

      // Listen to property changes on D-Bus (like NTP or Timezone updates)
      await _propertiesSubscription?.cancel();
      _propertiesSubscription = _repository.propertiesChangedStream.listen((
        changed,
      ) {
        if (!isClosed) {
          if (changed.contains('NTP') ||
              changed.contains('Timezone') ||
              changed.contains('TimeUSec')) {
            add(const RefreshDateTimeEvent());
          }
        }
      });

      // Load initial settings
      final autoTime = await _repository.getNtpEnabled();
      final timezone = await _repository.getTimezone();

      final location = _getLocation(timezone);
      final tzDateTime = tz.TZDateTime.now(location);
      final timeFormat = await _repository.getTimeFormat();

      emit(
        state.copyWith(
          status: DateTimeStatus.loaded,
          error: null,
          autoTime: autoTime,
          timezone: timezone,
          hour: _hour24to12(tzDateTime.hour),
          minute: tzDateTime.minute,
          isAm: tzDateTime.hour < 12,
          year: tzDateTime.year,
          month: tzDateTime.month,
          day: tzDateTime.day,
          timeFormat: timeFormat == '12h'
              ? TimeFormats.hour12
              : TimeFormats.hour24,
        ),
      );

      // Start periodic ticker timer
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!isClosed) {
          add(const _DateTimeTickEvent());
        }
      });
    } catch (e, stack) {
      AppLogger.e('Failed to initialize date time: $e', stack: stack);

      emit(
        state.copyWith(
          status: DateTimeStatus.error,
          error: DateTimeError.initializationFailed,
        ),
      );
    }
  }

  /// Reloads the latest system date/time settings from the repository and
  /// updates the current state.
  Future<void> _onRefresh(
    RefreshDateTimeEvent event,
    Emitter<DateTimeState> emit,
  ) async {
    try {
      final autoTime = await _repository.getNtpEnabled();
      final timezone = await _repository.getTimezone();

      final location = _getLocation(timezone);
      final tzDateTime = tz.TZDateTime.now(location);

      final timeFormat = await _repository.getTimeFormat();

      emit(
        state.copyWith(
          status: DateTimeStatus.loaded,
          error: null,
          autoTime: autoTime,
          timezone: timezone,
          hour: _hour24to12(tzDateTime.hour),
          minute: tzDateTime.minute,
          isAm: tzDateTime.hour < 12,
          year: tzDateTime.year,
          month: tzDateTime.month,
          day: tzDateTime.day,
          timeFormat: timeFormat == '12h'
              ? TimeFormats.hour12
              : TimeFormats.hour24,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to refresh date/time: $e', stack: stack);

      emit(
        state.copyWith(
          status: DateTimeStatus.error,
          error: DateTimeError.unknown,
        ),
      );
    }
  }

  void _onTick(_DateTimeTickEvent event, Emitter<DateTimeState> emit) {
    _syncCurrentTime(emit);
  }

  Future<void> _onToggleAutoTime(
    ToggleAutoTimeEvent event,
    Emitter<DateTimeState> emit,
  ) async {
    try {
      await _repository.setNtpEnabled(event.value);

      emit(
        state.copyWith(
          status: DateTimeStatus.loaded,
          error: null,
          autoTime: event.value,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to update automatic time: $e', stack: stack);

      emit(
        state.copyWith(
          status: DateTimeStatus.error,
          error: DateTimeError.ntpUpdateFailed,
        ),
      );
    }
  }

  /// Updates the system timezone and refreshes the displayed date and time
  /// using the newly selected timezone.
  Future<void> _onUpdateTimezone(
    UpdateTimezoneEvent event,
    Emitter<DateTimeState> emit,
  ) async {
    try {
      await _repository.setTimezone(event.timezone);

      final timezone = await _repository.getTimezone();

      final location = _getLocation(timezone);
      final tzDateTime = tz.TZDateTime.now(location);

      emit(
        state.copyWith(
          status: DateTimeStatus.loaded,
          error: null,
          timezone: timezone,
          hour: _hour24to12(tzDateTime.hour),
          minute: tzDateTime.minute,
          isAm: tzDateTime.hour < 12,
          year: tzDateTime.year,
          month: tzDateTime.month,
          day: tzDateTime.day,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to update timezone: $e', stack: stack);

      emit(
        state.copyWith(
          status: DateTimeStatus.error,
          error: DateTimeError.timezoneUpdateFailed,
        ),
      );
    }
  }

  Future<void> _onUpdateTime(
    UpdateTimeEvent event,
    Emitter<DateTimeState> emit,
  ) async {
    try {
      int hour24 = event.hour;

      if (!event.isAm && event.hour < 12) hour24 += 12;
      if (event.isAm && event.hour == 12) hour24 = 0;

      final location = _getLocation(state.timezone);

      final localTime = tz.TZDateTime(
        location,
        state.year,
        state.month,
        state.day,
        hour24,
        event.minute,
        0,
      );

      await _repository.setTime(localTime.microsecondsSinceEpoch);

      emit(
        state.copyWith(
          status: DateTimeStatus.loaded,
          error: null,
          hour: event.hour,
          minute: event.minute,
          isAm: event.isAm,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to update time: $e', stack: stack);

      emit(
        state.copyWith(
          status: DateTimeStatus.error,
          error: DateTimeError.timeUpdateFailed,
        ),
      );
    }
  }

  /// Updates the system date while preserving the currently selected time.
  Future<void> _onUpdateDate(
    UpdateDateEvent event,
    Emitter<DateTimeState> emit,
  ) async {
    try {
      int hour24 = state.hour;
      if (!state.isAm && state.hour < 12) hour24 += 12;
      if (state.isAm && state.hour == 12) hour24 = 0;

      final location = _getLocation(state.timezone);
      final localTime = tz.TZDateTime(
        location,
        event.year,
        event.month,
        event.day,
        hour24,
        state.minute,
        0,
      );

      await _repository.setTime(localTime.microsecondsSinceEpoch);

      emit(
        state.copyWith(
          status: DateTimeStatus.loaded,
          error: null,
          year: event.year,
          month: event.month,
          day: event.day,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to update date: $e', stack: stack);

      emit(
        state.copyWith(
          status: DateTimeStatus.error,
          error: DateTimeError.timeUpdateFailed,
        ),
      );
    }
  }

  Future<void> _onUpdateTimeFormat(
    UpdateTimeFormatEvent event,
    Emitter<DateTimeState> emit,
  ) async {
    try {
      await _repository.setTimeFormat(
        event.timeFormat == TimeFormats.hour12 ? '12h' : '24h',
      );

      emit(
        state.copyWith(
          status: DateTimeStatus.loaded,
          error: null,
          timeFormat: event.timeFormat,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to update time format: $e', stack: stack);

      emit(
        state.copyWith(
          status: DateTimeStatus.error,
          error: DateTimeError.timeFormatUpdateFailed,
        ),
      );
    }
  }

  /// Synchronizes the displayed date and time with the current system time
  /// using the active timezone.
  void _syncCurrentTime(Emitter<DateTimeState> emit) {
    try {
      final location = _getLocation(state.timezone);
      final tzDateTime = tz.TZDateTime.now(location);

      emit(
        state.copyWith(
          hour: _hour24to12(tzDateTime.hour),
          minute: tzDateTime.minute,
          isAm: tzDateTime.hour < 12,
          year: tzDateTime.year,
          month: tzDateTime.month,
          day: tzDateTime.day,
        ),
      );
    } catch (e) {
      AppLogger.e('Error syncing current time: $e');
    }
  }

  /// Releases timers, stream subscriptions, and repository resources before
  /// disposing the Bloc.
  @override
  Future<void> close() async {
    try {
      _timer?.cancel();
      await _propertiesSubscription?.cancel();
      await _repository.close();
    } finally {
      await super.close();
    }
  }
}
