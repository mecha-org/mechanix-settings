import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'date_time_event.dart';
import 'date_time_state.dart';

class _DateTimeTickEvent extends DateTimeEvent {
  const _DateTimeTickEvent();
}

class DateTimeBloc extends Bloc<DateTimeEvent, DateTimeState> {
  Timer? _timer;

  DateTimeBloc() : super(DateTimeState.initial()) {
    on<InitializeDateTimeEvent>((event, emit) {
      // Initialize date/time state from the current time source.
      // Future implementation will fetch this data through the DateTime D-Bus service.
      _syncCurrentTime(emit);
      _timer?.cancel();

      // Periodically refresh date/time state while automatic synchronization is enabled.
      // Future implementation will trigger a D-Bus time query.
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (state.autoTime) {
          add(const _DateTimeTickEvent());
        }
      });
    });

    on<_DateTimeTickEvent>((event, emit) {
      if (state.autoTime) {
        _syncCurrentTime(emit);
      }
    });

    on<ToggleAutoTimeEvent>((event, emit) {
      emit(state.copyWith(autoTime: event.value));
      if (event.value) {
        _syncCurrentTime(emit);
      }
    });

    on<UpdateTimezoneEvent>((event, emit) {
      emit(state.copyWith(timezone: event.timezone));
    });

    on<UpdateTimeEvent>((event, emit) {
      emit(
        state.copyWith(
          hour: event.hour,
          minute: event.minute,
          isAm: event.isAm,
        ),
      );
    });

    on<UpdateDateEvent>((event, emit) {
      emit(
        state.copyWith(year: event.year, month: event.month, day: event.day),
      );
    });

    on<UpdateTimeFormatEvent>((event, emit) {
      emit(state.copyWith(timeFormat: event.timeFormat));
    });

    on<UpdateDateFormatEvent>((event, emit) {
      emit(state.copyWith(dateFormat: event.dateFormat));
    });
  }

  /// Synchronizes the Bloc state with the current time source.
  ///
  /// Currently reads time from the local system clock.
  /// This will later be replaced by the DateTime D-Bus service.
  void _syncCurrentTime(Emitter<DateTimeState> emit) {
    final now = DateTime.now();

    int hour = now.hour % 12;
    if (hour == 0) {
      hour = 12;
    }

    emit(
      state.copyWith(
        hour: hour,
        minute: now.minute,
        isAm: now.hour < 12,
        year: now.year,
        month: now.month,
        day: now.day,
      ),
    );
  }
}
