import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/exceptions/date_time_exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository_impl.dart';

class MockDBusClient extends Mock implements DBusClient {}

class MockDBusRemoteObject extends Mock implements DBusRemoteObject {}

class MockDBusPropertiesChangedSignal extends Mock
    implements DBusPropertiesChangedSignal {}

class MockDBusValue extends Mock implements DBusValue {}

class MockDBusMethodSuccessResponse extends Mock
    implements DBusMethodSuccessResponse {}

void main() {
  late DateTimeRepositoryImpl repository;
  late MockDBusClient mockClient;
  late MockDBusRemoteObject mockObject;
  late StreamController<DBusPropertiesChangedSignal> signalController;
  late List<Map<String, dynamic>> processCalls;

  setUpAll(() {
    registerFallbackValue(DBusBoolean(true));
    registerFallbackValue(DBusString(''));
    registerFallbackValue(DBusInt64(0));
  });

  setUp(() {
    mockClient = MockDBusClient();
    mockObject = MockDBusRemoteObject();
    signalController = StreamController<DBusPropertiesChangedSignal>();
    processCalls = [];

    // Stub propertiesChanged on mock remote object
    when(
      () => mockObject.propertiesChanged,
    ).thenAnswer((_) => signalController.stream);

    // Stub client close
    when(() => mockClient.close()).thenAnswer((_) async {});

    // Create repository instance with injected dependencies
    repository = DateTimeRepositoryImpl(
      client: mockClient,
      object: mockObject,
      processRun:
          (
            executable,
            arguments, {
            workingDirectory,
            environment,
            includeParentEnvironment = true,
            runInShell = false,
            stdoutEncoding,
            stderrEncoding,
          }) async {
            processCalls.add({
              'executable': executable,
              'arguments': arguments,
            });

            if (arguments.contains('get')) {
              return ProcessResult(0, 0, "'12h'\n", "");
            } else {
              return ProcessResult(0, 0, "", "");
            }
          },
    );
  });

  tearDown(() async {
    await repository.close();
    await signalController.close();
  });

  group('DateTimeRepositoryImpl - Initialization & Streams', () {
    test(
      'init subscribes to propertiesChanged and forwards event names',
      () async {
        await repository.init();

        final events = [];
        final subscription = repository.propertiesChangedStream.listen((event) {
          events.add(event);
        });

        // Fire a simulated propertiesChanged signal
        final signal = MockDBusPropertiesChangedSignal();
        when(
          () => signal.changedProperties,
        ).thenReturn({'NTP': DBusBoolean(true), 'Timezone': DBusString('UTC')});

        signalController.add(signal);

        // Wait a microtask for stream delivery
        await Future.delayed(Duration.zero);

        expect(events, isNotEmpty);
        expect(events.first, contains('NTP'));
        expect(events.first, contains('Timezone'));

        await subscription.cancel();
      },
    );

    test('init executes only once on multiple calls', () async {
      await repository.init();
      await repository.init();

      // If already initialized, it should not subscribe again.
      // So propertiesChanged should be accessed exactly once.
      verify(() => mockObject.propertiesChanged).called(1);
    });
  });

  group('DateTimeRepositoryImpl - NTP Settings', () {
    test('getNtpEnabled returns true when D-Bus property is true', () async {
      final dbusBool = DBusBoolean(true);
      when(
        () => mockObject.getProperty(any(), 'NTP'),
      ).thenAnswer((_) async => dbusBool);

      final ntpEnabled = await repository.getNtpEnabled();
      expect(ntpEnabled, isTrue);
      verify(
        () => mockObject.getProperty('org.freedesktop.timedate1', 'NTP'),
      ).called(1);
    });

    test('getNtpEnabled throws GetNtpException on D-Bus error', () async {
      when(
        () => mockObject.getProperty(any(), 'NTP'),
      ).thenThrow(Exception('D-Bus failed'));

      expect(repository.getNtpEnabled(), throwsA(isA<GetNtpException>()));
    });

    test(
      'setNtpEnabled calls D-Bus SetNTP method with correct parameters',
      () async {
        final mockResponse = MockDBusMethodSuccessResponse();
        when(
          () => mockObject.callMethod(any(), 'SetNTP', any()),
        ).thenAnswer((_) async => mockResponse);

        await repository.setNtpEnabled(true);

        verify(
          () => mockObject.callMethod('org.freedesktop.timedate1', 'SetNTP', [
            const DBusBoolean(true),
            const DBusBoolean(true),
          ]),
        ).called(1);
      },
    );

    test('setNtpEnabled throws SetNtpException on D-Bus failure', () async {
      when(
        () => mockObject.callMethod(any(), 'SetNTP', any()),
      ).thenThrow(Exception('D-Bus failure'));

      await expectLater(
        repository.setNtpEnabled(true),
        throwsA(isA<SetNtpException>()),
      );
    });
  });

  group('DateTimeRepositoryImpl - Timezone Settings', () {
    test('getTimezone returns value from D-Bus property', () async {
      final dbusString = DBusString('Europe/London');
      when(
        () => mockObject.getProperty(any(), 'Timezone'),
      ).thenAnswer((_) async => dbusString);

      final timezone = await repository.getTimezone();
      expect(timezone, equals('Europe/London'));
      verify(
        () => mockObject.getProperty('org.freedesktop.timedate1', 'Timezone'),
      ).called(1);
    });

    test('getTimezone throws GetTimezoneException on failure', () async {
      when(
        () => mockObject.getProperty(any(), 'Timezone'),
      ).thenThrow(Exception('D-Bus error'));

      expect(repository.getTimezone(), throwsA(isA<GetTimezoneException>()));
    });

    test(
      'setTimezone calls D-Bus SetTimezone method with correct parameters',
      () async {
        final mockResponse = MockDBusMethodSuccessResponse();
        when(
          () => mockObject.callMethod(any(), 'SetTimezone', any()),
        ).thenAnswer((_) async => mockResponse);

        await repository.setTimezone('America/New_York');

        verify(
          () => mockObject.callMethod(
            'org.freedesktop.timedate1',
            'SetTimezone',
            [const DBusString('America/New_York'), const DBusBoolean(true)],
          ),
        ).called(1);
      },
    );
  });

  group('DateTimeRepositoryImpl - Set Time & Get System Time', () {
    test(
      'setTime calls D-Bus SetTime method with correct parameters',
      () async {
        final mockResponse = MockDBusMethodSuccessResponse();
        when(
          () => mockObject.callMethod(any(), 'SetTime', any()),
        ).thenAnswer((_) async => mockResponse);

        await repository.setTime(1620000000000000);

        verify(
          () => mockObject.callMethod('org.freedesktop.timedate1', 'SetTime', [
            const DBusInt64(1620000000000000),
            const DBusBoolean(false),
            const DBusBoolean(true),
          ]),
        ).called(1);
      },
    );

    test(
      'getSystemTime returns DateTime calculated from D-Bus TimeUSec',
      () async {
        final timeUsecVal = MockDBusValue();
        // 1620000000000000 microseconds = 1620000000000 milliseconds = 2021-05-03T00:00:00.000Z
        when(() => timeUsecVal.asUint64()).thenReturn(1620000000000000);
        when(
          () => mockObject.getProperty(any(), 'TimeUSec'),
        ).thenAnswer((_) async => timeUsecVal);

        final systemTime = await repository.getSystemTime();
        expect(systemTime.millisecondsSinceEpoch, equals(1620000000000));
      },
    );

    test('getSystemTime throws GetTimeException on error', () async {
      when(
        () => mockObject.getProperty(any(), 'TimeUSec'),
      ).thenThrow(Exception('D-Bus failure'));

      expect(repository.getSystemTime(), throwsA(isA<GetTimeException>()));
    });
  });

  group('DateTimeRepositoryImpl - close', () {
    test('close cancels subscriptions and closes client', () async {
      await repository.init();
      await repository.close();

      verify(() => mockClient.close()).called(1);
    });
  });
}
