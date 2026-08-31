import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/widgets/custom_slider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/display/presentation/screens/display_screen.dart';
import 'package:mechanix_settings/features/display/presentation/screens/screen_off_time_screen.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository.dart';
import 'package:mechanix_settings/features/display/blocs/display_bloc.dart';
import 'package:mechanix_settings/features/display/blocs/display_event.dart';

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
import 'package:mechanix_settings/features/about/data/repositories/about_repository.dart';
import 'package:mechanix_settings/features/about/blocs/about_bloc.dart';
import 'package:mechanix_settings/features/about/blocs/about_event.dart';
import 'package:mechanix_settings/features/about/data/models/about_details.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class MockDateTimeRepository extends Mock implements DateTimeRepository {}

class MockBatteryRepository extends Mock implements BatteryRepository {}

class MockAboutRepository extends Mock implements AboutRepository {}

class FakeDisplayRepository implements DisplayRepository {
  double brightness = 0.5;
  bool isAutoBrightness = true;
  int screenTimeout = 30;
  bool isInitialized = false;
  bool isClosed = false;

  @override
  Future<void> init() async {
    isInitialized = true;
  }

  @override
  Future<double> getBrightness() async => brightness;

  @override
  Future<void> setBrightness(double val) async {
    brightness = val;
  }

  @override
  Future<bool> getAutoBrightness() async => isAutoBrightness;

  @override
  Future<void> setAutoBrightness(bool val) async {
    isAutoBrightness = val;
  }

  @override
  Future<int> getScreenTimeout() async => screenTimeout;

  @override
  Future<void> setScreenTimeout(int val) async {
    screenTimeout = val;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Display Integration Tests', () {
    late MockWirelessRepository mockWirelessRepository;
    late MockBluetoothRepository mockBluetoothRepository;
    late MockDateTimeRepository mockDateTimeRepository;
    late MockBatteryRepository mockBatteryRepository;
    late MockAboutRepository mockAboutRepository;
    late FakeDisplayRepository fakeDisplayRepository;

    setUp(() {
      mockWirelessRepository = MockWirelessRepository();
      mockBluetoothRepository = MockBluetoothRepository();
      mockDateTimeRepository = MockDateTimeRepository();
      mockBatteryRepository = MockBatteryRepository();
      mockAboutRepository = MockAboutRepository();
      fakeDisplayRepository = FakeDisplayRepository();

      // Wireless Repository Mock defaults
      when(() => mockWirelessRepository.init()).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.isWirelessEnabled(),
      ).thenAnswer((_) => false);
      when(
        () => mockWirelessRepository.getWifiEventsStream(),
      ).thenAnswer((_) => const Stream<List<String>>.empty());
      when(
        () => mockWirelessRepository.getDeviceEventsStream(),
      ).thenAnswer((_) => const Stream<List<String>>.empty());
      when(
        () => mockWirelessRepository.getWirelessDeviceEventsStream(),
      ).thenAnswer((_) => const Stream<List<String>>.empty());

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

      // About Repository Mock defaults
      when(() => mockAboutRepository.getAboutDetails()).thenAnswer(
        (_) async => const AboutDetails(
          deviceName: 'comet',
          hostname: 'comet',
          model: 'Mecha Comet',
          manufacturer: 'Mecha',
          operatingSystem: 'Mecha OS',
          supportUntil: '2030-12-31',
          kernel: 'Linux 6.6.87.1',
          kernelBuild: '#1 SMP',
          firmwareVersion: '1.0.0',
          firmwareVendor: 'Mecha',
          firmwareDate: '2026-08-01',
          serialNumber: '1234 6789',
          machineId: '4d7803045b574ef5a05fbea4b7642d51',
          bootId: '1234567890abcdef1234567890abcdef',
          osWebsite: 'https://example.com',
        ),
      );
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
          RepositoryProvider<AboutRepository>.value(
            value: mockAboutRepository,
          ),
          RepositoryProvider<DisplayRepository>.value(
            value: fakeDisplayRepository,
          ),
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
              create: (context) =>
                  AboutBloc(context.read<AboutRepository>())
                    ..add(const LoadAboutDetails()),
            ),
            BlocProvider<DisplayBloc>(
              create: (context) =>
                  DisplayBloc(context.read<DisplayRepository>())
                    ..add(const DisplayInit()),
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

    testWidgets('Verify complete Display settings flow', (
      WidgetTester tester,
    ) async {
      // 1. Launch the application
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify we are on SettingsMenuScreen
      expect(find.byType(SettingsMenuScreen), findsOneWidget);

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // 2. Navigate to Display settings screen
      final displayItem = find.text(l10n.display);
      await tester.ensureVisible(displayItem);
      await tester.pump();
      await tester.tap(displayItem);
      await tester.pumpAndSettle();

      // Verify we are on DisplayScreen
      expect(find.byType(DisplayScreen), findsOneWidget);

      // 3. Verify initial state values from FakeDisplayRepository
      expect(find.text("50 %"), findsOneWidget);
      expect(find.text(l10n.screenOffThirtySeconds), findsOneWidget);

      // Verify auto brightness is initially enabled (isAutoBrightness = true)
      final autoBrightnessToggle = find.byType(CustomToggle);
      expect(autoBrightnessToggle, findsOneWidget);
      expect(tester.widget<CustomToggle>(autoBrightnessToggle).value, isTrue);

      // 4. Toggle auto brightness OFF
      await tester.tap(autoBrightnessToggle);
      await tester.pumpAndSettle();

      expect(tester.widget<CustomToggle>(autoBrightnessToggle).value, isFalse);
      expect(fakeDisplayRepository.isAutoBrightness, isFalse);

      // Toggle auto brightness ON again
      await tester.tap(autoBrightnessToggle);
      await tester.pumpAndSettle();

      expect(tester.widget<CustomToggle>(autoBrightnessToggle).value, isTrue);
      expect(fakeDisplayRepository.isAutoBrightness, isTrue);

      // 5. Interact with CustomSlider
      final sliderFinder = find.byType(CustomSlider);
      expect(sliderFinder, findsOneWidget);
      await tester.drag(sliderFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Verify that the brightness in the repository is no longer the default 0.5
      expect(fakeDisplayRepository.brightness, isNot(equals(0.5)));

      // 6. Navigate to ScreenOffTimeScreen
      final screenOffItem = find.text(l10n.screenOffTime);
      await tester.ensureVisible(screenOffItem);
      await tester.pump();
      await tester.tap(screenOffItem);
      await tester.pumpAndSettle();

      // Verify we are on ScreenOffTimeScreen
      expect(find.byType(ScreenOffTimeScreen), findsOneWidget);

      // Select "1 minute"
      final oneMinuteOption = find.text(l10n.screenOffOneMinute);
      await tester.tap(oneMinuteOption);
      await tester.pumpAndSettle();

      // Verify that screenTimeout has been updated in the repository
      expect(fakeDisplayRepository.screenTimeout, equals(60));

      // 7. Navigate back to DisplayScreen
      final displayBackButton = findBackButton();
      expect(displayBackButton, findsOneWidget);
      await tester.tap(displayBackButton);
      await tester.pumpAndSettle();

      // Verify we are back on DisplayScreen, and "1 minute" is now visible
      expect(find.byType(DisplayScreen), findsOneWidget);
      expect(find.text(l10n.screenOffOneMinute), findsOneWidget);

      // 8. Navigate back to SettingsMenuScreen
      final mainBackButton = findBackButton();
      expect(mainBackButton, findsOneWidget);
      await tester.tap(mainBackButton);
      await tester.pumpAndSettle();

      // Verify we navigated back to SettingsMenuScreen
      expect(find.byType(SettingsMenuScreen), findsOneWidget);
    });
  });
}
