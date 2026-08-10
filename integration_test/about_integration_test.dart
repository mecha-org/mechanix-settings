import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/about/presentation/screens/about_screen.dart';
import 'package:mechanix_settings/features/about/presentation/widgets/about_tile.dart';
import 'package:mechanix_settings/features/about/data/repositories/about_repository.dart';
import 'package:mechanix_settings/features/about/blocs/about_bloc.dart';
import 'package:mechanix_settings/features/about/data/models/about_details.dart';

import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/battery/data/repositories/battery_repository.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_bloc.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_event.dart';
import 'package:mechanix_settings/features/battery/data/models/battery_info.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:upower/upower.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class MockDateTimeRepository extends Mock implements DateTimeRepository {}

class MockBatteryRepository extends Mock implements BatteryRepository {}

class FakeAboutRepository implements AboutRepository {
  AboutDetails details = const AboutDetails(
    deviceName: 'My Test Device',
    hostname: 'test-hostname',
    model: 'Test Model',
    manufacturer: 'Test Vendor',
    operatingSystem: 'Test OS',
    supportUntil: '2030-01-01',
    kernel: 'Linux 6.1.0',
    kernelBuild: 'SMP Build #1',
    firmwareVersion: 'v1.2.3',
    firmwareVendor: 'Bios Inc',
    firmwareDate: '2025-01-01',
    serialNumber: 'SN12345',
    machineId: '000102030405060708090a0b0c0d0e0f',
    bootId: '10111213-1415-1617-1819-1a1b1c1d1e1f',
    osWebsite: 'https://os-z.org',
  );

  @override
  Future<AboutDetails> getAboutDetails() async => details;

  @override
  Future<void> updateDeviceName(String name) async {
    details = AboutDetails(
      deviceName: name.trim(),
      hostname: details.hostname,
      model: details.model,
      manufacturer: details.manufacturer,
      operatingSystem: details.operatingSystem,
      supportUntil: details.supportUntil,
      kernel: details.kernel,
      kernelBuild: details.kernelBuild,
      firmwareVersion: details.firmwareVersion,
      firmwareVendor: details.firmwareVendor,
      firmwareDate: details.firmwareDate,
      serialNumber: details.serialNumber,
      machineId: details.machineId,
      bootId: details.bootId,
      osWebsite: details.osWebsite,
    );
  }

  @override
  Future<void> updateHostname(String name) async {
    details = AboutDetails(
      deviceName: details.deviceName,
      hostname: name.trim(),
      model: details.model,
      manufacturer: details.manufacturer,
      operatingSystem: details.operatingSystem,
      supportUntil: details.supportUntil,
      kernel: details.kernel,
      kernelBuild: details.kernelBuild,
      firmwareVersion: details.firmwareVersion,
      firmwareVendor: details.firmwareVendor,
      firmwareDate: details.firmwareDate,
      serialNumber: details.serialNumber,
      machineId: details.machineId,
      bootId: details.bootId,
      osWebsite: details.osWebsite,
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('About Feature Integration Tests', () {
    late MockWirelessRepository mockWirelessRepository;
    late MockBluetoothRepository mockBluetoothRepository;
    late MockDateTimeRepository mockDateTimeRepository;
    late MockBatteryRepository mockBatteryRepository;
    late FakeAboutRepository fakeAboutRepository;

    setUp(() {
      mockWirelessRepository = MockWirelessRepository();
      mockBluetoothRepository = MockBluetoothRepository();
      mockDateTimeRepository = MockDateTimeRepository();
      mockBatteryRepository = MockBatteryRepository();
      fakeAboutRepository = FakeAboutRepository();

      // Wireless Repository Mock defaults
      when(() => mockWirelessRepository.init()).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.isWirelessEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockWirelessRepository.getWifiEventsStream(),
      ).thenAnswer((_) async => const Stream<List<String>>.empty());
      when(
        () => mockWirelessRepository.getDeviceEventsStream(),
      ).thenAnswer((_) async => const Stream<List<String>>.empty());
      when(
        () => mockWirelessRepository.getWirelessDeviceEventsStream(),
      ).thenAnswer((_) async => const Stream<List<String>>.empty());

      // Bluetooth Repository Mock defaults
      when(() => mockBluetoothRepository.init()).thenAnswer((_) async {});
      when(() => mockBluetoothRepository.close()).thenAnswer((_) async {});
      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBluetoothRepository.getLocalDeviceName(),
      ).thenAnswer((_) async => 'comet');
      when(
        () => mockBluetoothRepository.powerStream,
      ).thenAnswer((_) => const Stream<bool>.empty());
      when(
        () => mockBluetoothRepository.scanningStream,
      ).thenAnswer((_) => const Stream<bool>.empty());
      when(
        () => mockBluetoothRepository.discoverableStream,
      ).thenAnswer((_) => const Stream<bool>.empty());
      when(
        () => mockBluetoothRepository.devicesStream,
      ).thenAnswer((_) => const Stream<List<BluetoothDevice>>.empty());

      // DateTime Repository Mock defaults
      when(() => mockDateTimeRepository.init()).thenAnswer((_) async {});
      when(
        () => mockDateTimeRepository.getNtpEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockDateTimeRepository.getTimezone(),
      ).thenAnswer((_) async => 'Asia/Kolkata');
      when(
        () => mockDateTimeRepository.getTimeFormat(),
      ).thenAnswer((_) async => '24h');
      when(
        () => mockDateTimeRepository.getSystemTime(),
      ).thenAnswer((_) async => DateTime.now());
      when(
        () => mockDateTimeRepository.propertiesChangedStream,
      ).thenAnswer((_) => const Stream<List<String>>.empty());
      when(() => mockDateTimeRepository.close()).thenAnswer((_) async {});

      // Battery Repository Mock defaults
      when(() => mockBatteryRepository.init()).thenAnswer((_) async {});
      when(() => mockBatteryRepository.getBatteryInfo()).thenAnswer(
        (_) async => const BatteryInfo(
          batteryPercentage: 75.0,
          status: UPowerDeviceState.discharging,
          mode: PowerProfileMode.balanced,
          batteryChargingTime: 0,
          batteryRemainingTime: 7200,
          availableBatteryModes: ['power-saver', 'balanced', 'performance'],
        ),
      );
      when(
        () => mockBatteryRepository.streamBatteryEvents(),
      ).thenAnswer((_) async => const Stream<List<String>>.empty());
      when(() => mockBatteryRepository.close()).thenAnswer((_) async {});
    });

    Widget createTestApp() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<WirelessRepository>.value(
            value: mockWirelessRepository,
          ),
          RepositoryProvider<BluetoothRepository>.value(
            value: mockBluetoothRepository,
          ),
          RepositoryProvider<DateTimeRepository>.value(
            value: mockDateTimeRepository,
          ),
          RepositoryProvider<BatteryRepository>.value(
            value: mockBatteryRepository,
          ),
          RepositoryProvider<AboutRepository>.value(value: fakeAboutRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<WirelessBloc>(
              create: (context) => WirelessBloc(
                wirelessRepository: context.read<WirelessRepository>(),
              )..add(InitWifi()),
            ),
            BlocProvider<BluetoothBloc>(
              create: (context) =>
                  BluetoothBloc(context.read<BluetoothRepository>())
                    ..add(const LoadBluetooth()),
            ),
            BlocProvider<DateTimeBloc>(
              create: (context) =>
                  DateTimeBloc(context.read<DateTimeRepository>())
                    ..add(const InitializeDateTimeEvent()),
            ),
            BlocProvider<BatteryBloc>(
              create: (context) =>
                  BatteryBloc(
                      batteryRepository: context.read<BatteryRepository>(),
                    )
                    ..add(const BatteryInit())
                    ..add(const BatteryInfoRequested()),
            ),
            BlocProvider<AboutBloc>(
              create: (context) => AboutBloc(context.read<AboutRepository>()),
            ),
          ],
          child: const MechanixSettingsApp(),
        ),
      );
    }

    Finder findBackButton() {
      return find
          .descendant(
            of: find.byType(BottomBar),
            matching: find.byType(CustomIconButton),
          )
          .first;
    }

    testWidgets(
      'Verify About screen load and editable fields (Device name / Hostname)',
      (WidgetTester tester) async {
        // 1. Launch the application
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify we are on SettingsMenuScreen
        expect(find.byType(SettingsMenuScreen), findsOneWidget);

        final BuildContext context = tester.element(
          find.byType(SettingsMenuScreen),
        );
        final l10n = AppLocalizations.of(context)!;

        // 2. Navigate to About screen
        final aboutItem = find.text(l10n.about);
        await tester.ensureVisible(aboutItem);
        await tester.pump();
        await tester.tap(aboutItem);
        await tester.pumpAndSettle();

        // Verify we are on AboutScreen
        expect(find.byType(AboutScreen), findsOneWidget);

        // Verify initial details from FakeAboutRepository are rendered correctly
        expect(find.text('My Test Device'), findsOneWidget);
        expect(find.text('test-hostname'), findsOneWidget);
        expect(find.text('Test Model'), findsOneWidget);
        expect(find.text('Test Vendor'), findsOneWidget);
        expect(find.text('Test OS'), findsOneWidget);
        expect(find.text('Linux 6.1.0'), findsOneWidget);
        expect(find.text('v1.2.3'), findsOneWidget);

        // 3. Edit Device Name
        final deviceNameTile = find.ancestor(
          of: find.text(l10n.deviceName),
          matching: find.byType(AboutTile),
        );
        expect(deviceNameTile, findsOneWidget);

        final editDeviceNameBtn = find.descendant(
          of: deviceNameTile,
          matching: find.byIcon(Icons.edit),
        );
        expect(editDeviceNameBtn, findsOneWidget);
        await tester.tap(editDeviceNameBtn);
        await tester.pumpAndSettle();

        final deviceNameTextField = find.descendant(
          of: deviceNameTile,
          matching: find.byType(TextField),
        );
        expect(deviceNameTextField, findsOneWidget);
        await tester.enterText(deviceNameTextField, 'New Pretty Name');
        await tester.pumpAndSettle();

        final saveDeviceNameBtn = find.descendant(
          of: deviceNameTile,
          matching: find.byIcon(Icons.check),
        );
        expect(saveDeviceNameBtn, findsOneWidget);
        await tester.tap(saveDeviceNameBtn);
        await tester.pumpAndSettle();

        // Verify that device name updated in fake repo and is shown in the UI
        expect(fakeAboutRepository.details.deviceName, 'New Pretty Name');
        expect(find.text('New Pretty Name'), findsOneWidget);

        // 4. Edit Hostname
        final hostnameTile = find.ancestor(
          of: find.text(l10n.hostname),
          matching: find.byType(AboutTile),
        );
        expect(hostnameTile, findsOneWidget);

        final editHostnameBtn = find.descendant(
          of: hostnameTile,
          matching: find.byIcon(Icons.edit),
        );
        expect(editHostnameBtn, findsOneWidget);
        await tester.tap(editHostnameBtn);
        await tester.pumpAndSettle();

        final hostnameTextField = find.descendant(
          of: hostnameTile,
          matching: find.byType(TextField),
        );
        expect(hostnameTextField, findsOneWidget);
        await tester.enterText(hostnameTextField, 'new-test-hostname');
        await tester.pumpAndSettle();

        final saveHostnameBtn = find.descendant(
          of: hostnameTile,
          matching: find.byIcon(Icons.check),
        );
        expect(saveHostnameBtn, findsOneWidget);
        await tester.tap(saveHostnameBtn);
        await tester.pumpAndSettle();

        // Verify that hostname updated in fake repo and is shown in the UI
        expect(fakeAboutRepository.details.hostname, 'new-test-hostname');
        expect(find.text('new-test-hostname'), findsOneWidget);

        // 5. Navigate back using the back button
        final backButton = findBackButton();
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verify we navigated back to SettingsMenuScreen
        expect(find.byType(SettingsMenuScreen), findsOneWidget);
      },
    );
  });
}
