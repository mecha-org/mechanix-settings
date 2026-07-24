import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/constants/date_time.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_state.dart';
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository.dart';

class MockDateTimeRepository extends Mock implements DateTimeRepository {}

void main() {
  late DateTimeBloc dateTimeBloc;
  late MockDateTimeRepository mockDateTimeRepository;

  setUpAll(() {
    tz.initializeTimeZones();
  });

  setUp(() {
    mockDateTimeRepository = MockDateTimeRepository();

    // Default mocks to prevent crashes
    when(() => mockDateTimeRepository.init()).thenAnswer((_) async {});
    when(
      () => mockDateTimeRepository.propertiesChangedStream,
    ).thenAnswer((_) => const Stream<List<String>>.empty());
    when(
      () => mockDateTimeRepository.getNtpEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => mockDateTimeRepository.getTimezone(),
    ).thenAnswer((_) async => 'Asia/Kolkata');
    when(
      () => mockDateTimeRepository.getSystemTime(),
    ).thenAnswer((_) async => DateTime.now());
    when(
      () => mockDateTimeRepository.getTimeFormat(),
    ).thenAnswer((_) async => '24h');
    when(() => mockDateTimeRepository.close()).thenAnswer((_) async {});

    dateTimeBloc = DateTimeBloc(mockDateTimeRepository);
  });

  tearDown(() {
    dateTimeBloc.close();
  });

  group('DateTimeBloc Initial State', () {
    test('initial state has correct default values', () {
      expect(dateTimeBloc.state.autoTime, true);
      expect(dateTimeBloc.state.timezone, '');
    });
  });

  group('InitializeDateTimeEvent', () {
    blocTest<DateTimeBloc, DateTimeState>(
      'loads initial settings and initializes repository',
      build: () {
        when(
          () => mockDateTimeRepository.getNtpEnabled(),
        ).thenAnswer((_) async => false);
        when(
          () => mockDateTimeRepository.getTimezone(),
        ).thenAnswer((_) async => 'America/New_York');
        return dateTimeBloc;
      },
      act: (bloc) => bloc.add(const InitializeDateTimeEvent()),
      expect: () => [
        isA<DateTimeState>()
            .having((s) => s.autoTime, 'autoTime', false)
            .having((s) => s.timezone, 'timezone', 'America/New_York'),
      ],
      verify: (_) {
        verify(() => mockDateTimeRepository.init()).called(1);
        verify(() => mockDateTimeRepository.getNtpEnabled()).called(1);
        verify(() => mockDateTimeRepository.getTimezone()).called(1);
      },
    );
  });

  group('ToggleAutoTimeEvent', () {
    blocTest<DateTimeBloc, DateTimeState>(
      'updates state and calls setNtpEnabled in repository',
      build: () {
        when(
          () => mockDateTimeRepository.setNtpEnabled(false),
        ).thenAnswer((_) async {});
        return dateTimeBloc;
      },
      act: (bloc) => bloc.add(const ToggleAutoTimeEvent(false)),
      expect: () => [
        isA<DateTimeState>().having((s) => s.autoTime, 'autoTime', false),
      ],
      verify: (_) {
        verify(() => mockDateTimeRepository.setNtpEnabled(false)).called(1);
      },
    );
  });

  group('UpdateTimezoneEvent', () {
    blocTest<DateTimeBloc, DateTimeState>(
      'updates state and calls setTimezone in repository',
      build: () {
        when(
          () => mockDateTimeRepository.setTimezone('Europe/Paris'),
        ).thenAnswer((_) async {});
        when(
          () => mockDateTimeRepository.getTimezone(),
        ).thenAnswer((_) async => 'Europe/Paris');
        return dateTimeBloc;
      },
      act: (bloc) => bloc.add(const UpdateTimezoneEvent('Europe/Paris')),
      expect: () => [
        isA<DateTimeState>().having(
          (s) => s.timezone,
          'timezone',
          'Europe/Paris',
        ),
      ],
      verify: (_) {
        verify(
          () => mockDateTimeRepository.setTimezone('Europe/Paris'),
        ).called(1);
      },
    );
  });

  group('UpdateTimeEvent', () {
    blocTest<DateTimeBloc, DateTimeState>(
      'updates state time and calls setTime in repository',
      build: () {
        when(
          () => mockDateTimeRepository.setTime(any()),
        ).thenAnswer((_) async {});
        return dateTimeBloc;
      },
      act: (bloc) => bloc.add(const UpdateTimeEvent(10, 30, true)), // 10:30 AM
      expect: () => [
        isA<DateTimeState>()
            .having((s) => s.hour, 'hour', 10)
            .having((s) => s.minute, 'minute', 30)
            .having((s) => s.isAm, 'isAm', true),
      ],
      verify: (_) {
        verify(() => mockDateTimeRepository.setTime(any())).called(1);
      },
    );
  });

  group('UpdateDateEvent', () {
    blocTest<DateTimeBloc, DateTimeState>(
      'updates state date and calls setTime in repository',
      build: () {
        when(
          () => mockDateTimeRepository.setTime(any()),
        ).thenAnswer((_) async {});
        return dateTimeBloc;
      },
      act: (bloc) => bloc.add(const UpdateDateEvent(2025, 12, 25)),
      expect: () => [
        isA<DateTimeState>()
            .having((s) => s.year, 'year', 2025)
            .having((s) => s.month, 'month', 12)
            .having((s) => s.day, 'day', 25),
      ],
      verify: (_) {
        verify(() => mockDateTimeRepository.setTime(any())).called(1);
      },
    );
  });

  group('RefreshDateTimeEvent', () {
    blocTest<DateTimeBloc, DateTimeState>(
      'refreshes date/time settings and updates state',
      build: () {
        when(
          () => mockDateTimeRepository.getNtpEnabled(),
        ).thenAnswer((_) async => true);

        when(
          () => mockDateTimeRepository.getTimezone(),
        ).thenAnswer((_) async => 'Asia/Kolkata');

        when(
          () => mockDateTimeRepository.getTimeFormat(),
        ).thenAnswer((_) async => '12h');

        return dateTimeBloc;
      },
      act: (bloc) => bloc.add(const RefreshDateTimeEvent()),
      expect: () => [
        isA<DateTimeState>()
            .having((s) => s.autoTime, 'autoTime', true)
            .having((s) => s.timezone, 'timezone', 'Asia/Kolkata')
            .having((s) => s.timeFormat, 'timeFormat', TimeFormats.hour12)
            .having(
              (s) => s.hour,
              'hour',
              anyOf(greaterThanOrEqualTo(1), lessThanOrEqualTo(12)),
            ),
      ],
      verify: (_) {
        verify(() => mockDateTimeRepository.getNtpEnabled()).called(1);

        verify(() => mockDateTimeRepository.getTimezone()).called(1);

        verify(() => mockDateTimeRepository.getTimeFormat()).called(1);
      },
    );
  });
}
