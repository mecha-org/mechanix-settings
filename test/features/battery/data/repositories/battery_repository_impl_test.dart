import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/exceptions/battery_exceptions.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:mechanix_settings/features/battery/data/repositories/battery_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:upower/upower.dart';

class MockUPowerClient extends Mock implements UPowerClient {}

class MockUPowerDevice extends Mock implements UPowerDevice {}

class MockDBusClient extends Mock implements DBusClient {}

void main() {
  late BatteryRepositoryImpl repository;

  late MockUPowerClient mockClient;
  late MockUPowerDevice mockDevice;
  late MockDBusClient mockDbusClient;

  late StreamController<List<String>> controller;

  setUpAll(() {
    registerFallbackValue(const DBusString(''));
  });

  setUp(() {
    mockClient = MockUPowerClient();
    mockDevice = MockUPowerDevice();
    mockDbusClient = MockDBusClient();

    controller = StreamController<List<String>>.broadcast();

    when(() => mockClient.connect()).thenAnswer((_) async {});
    when(() => mockClient.close()).thenAnswer((_) async {});

    when(() => mockClient.displayDevice).thenReturn(mockDevice);

    when(
      () => mockDevice.propertiesChanged,
    ).thenAnswer((_) => controller.stream);

    when(() => mockDbusClient.close()).thenAnswer((_) async {});

    repository = BatteryRepositoryImpl(
      client: mockClient,
      dbusClientFactory: () => mockDbusClient,
    );
  });

  tearDown(() async {
    try {
      await repository.close();
    } catch (_) {}
    await controller.close();
  });

  group('Initialization', () {
    test('init connects to UPower', () async {
      await repository.init();

      verify(() => mockClient.connect()).called(1);
    });

    test('init throws BatteryInitializationException on failure', () {
      when(() => mockClient.connect()).thenThrow(Exception());

      expect(repository.init, throwsA(isA<BatteryInitializationException>()));
    });
  });

  group('Battery Info', () {
    test('returns battery information', () async {
      when(() => mockDevice.percentage).thenReturn(82.0);
      when(() => mockDevice.state).thenReturn(UPowerDeviceState.charging);
      when(() => mockDevice.timeToFull).thenReturn(1400);
      when(() => mockDevice.timeToEmpty).thenReturn(0);

      final info = await repository.getBatteryInfo();

      expect(info.batteryPercentage, 82.0);
      expect(info.status, UPowerDeviceState.charging);
      expect(info.batteryChargingTime, 1400);
      expect(info.batteryRemainingTime, 0);

      verify(() => mockClient.displayDevice).called(greaterThan(0));
    });

    test('throws GetBatteryInfoException when connection fails', () {
      when(() => mockClient.connect()).thenThrow(Exception());

      expect(
        repository.getBatteryInfo,
        throwsA(isA<GetBatteryInfoException>()),
      );
    });
  });

  group('Battery Stream', () {
    test('returns battery properties stream', () async {
      final stream = await repository.streamBatteryEvents();

      expect(stream, isNotNull);

      final events = <List<String>>[];

      final sub = stream!.listen(events.add);

      controller.add(["Percentage"]);

      await Future.delayed(Duration.zero);

      expect(events.first, contains("Percentage"));

      await sub.cancel();
    });
  });

  group('Close', () {
    test('closes UPower client', () async {
      await repository.close();

      verify(() => mockClient.close()).called(1);
    });

    test('throws BatteryCloseException when close fails', () {
      when(() => mockClient.close()).thenThrow(Exception());

      expect(repository.close, throwsA(isA<BatteryCloseException>()));
    });
  });

  group('Power Profile', () {
    test('setBatteryMode throws SetBatteryModeException when DBus fails', () {
      expect(
        () => repository.setBatteryMode(PowerProfileMode.performance),
        throwsA(isA<SetBatteryModeException>()),
      );
    });

    test('getBatteryModeViaDBus returns balanced when DBus fails', () async {
      final mode = await repository.getBatteryModeViaDBus();

      expect(mode, PowerProfileMode.balanced);
    });

    test(
      'getAvailableBatteryModes returns empty list when DBus fails',
      () async {
        final modes = await repository.getAvailableBatteryModes();

        expect(modes, isEmpty);
      },
    );
  });
}
