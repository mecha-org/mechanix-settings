import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:upower/upower.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/battery/presentation/screens/battery_screen.dart';
import 'package:mechanix_settings/features/battery/presentation/widgets/battery_progress_bar.dart';
import 'package:mechanix_settings/features/battery/data/repositories/battery_repository.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_bloc.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_event.dart';
import 'package:mechanix_settings/features/battery/data/models/battery_info.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';

import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class MockDateTimeRepository extends Mock implements DateTimeRepository {}

class FakeBatteryRepository implements BatteryRepository {
  double percentage = 75.0;
  UPowerDeviceState status = UPowerDeviceState.discharging;
  PowerProfileMode mode = PowerProfileMode.balanced;
  int chargingTime = 0;
  int remainingTime = 7200; // 2 hours
  List<String> availableModes = const [
    'power-saver',
    'balanced',
    'performance',
  ];

  final _eventsController = StreamController<List<String>>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<BatteryInfo> getBatteryInfo() async {
    return BatteryInfo(
      batteryPercentage: percentage,
      status: status,
      mode: mode,
      batteryChargingTime: chargingTime,
      batteryRemainingTime: remainingTime,
      availableBatteryModes: availableModes,
    );
  }

  @override
  Future<PowerProfileMode> setBatteryMode(PowerProfileMode targetMode) async {
    mode = targetMode;
    _eventsController.add(['PowerProfileMode']);
    return mode;
  }

  @override
  Future<Stream<List<String>>?> streamBatteryEvents() async {
    return _eventsController.stream;
  }

  @override
  Future<void> close() async {
    await _eventsController.close();
  }

  void triggerEvent(List<String> properties) {
    _eventsController.add(properties);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Battery Integration Tests', () {
    late MockWirelessRepository mockWirelessRepository;
    late MockBluetoothRepository mockBluetoothRepository;
    late MockDateTimeRepository mockDateTimeRepository;
    late FakeBatteryRepository fakeBatteryRepository;

    setUp(() {
      mockWirelessRepository = MockWirelessRepository();
      mockBluetoothRepository = MockBluetoothRepository();
      mockDateTimeRepository = MockDateTimeRepository();
      fakeBatteryRepository = FakeBatteryRepository();

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
            value: fakeBatteryRepository,
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
              create: (context) {
                final bloc = BatteryBloc(
                  batteryRepository: context.read<BatteryRepository>(),
                );

                bloc
                  ..add(const BatteryInit())
                  ..add(const BatteryInfoRequested());

                return bloc;
              },
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

    testWidgets('Verify complete Battery settings flow', (
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

      // 2. Navigate to Battery settings screen
      final batteryItem = find.text(l10n.battery);
      await tester.ensureVisible(batteryItem);
      await tester.pump();
      await tester.tap(batteryItem);
      await tester.pumpAndSettle();

      // Verify we are on BatteryScreen
      expect(find.byType(BatteryScreen), findsOneWidget);

      // 3. Verify initial state values from FakeBatteryRepository
      // percentage: 75% -> l10n.batteryPercentage(75)
      expect(find.text(l10n.batteryPercentage(75)), findsOneWidget);
      // status: discharging -> l10n.discharging
      expect(find.text(l10n.discharging), findsOneWidget);
      // remainingTime: 7200 sec (2h) -> timeText: l10n.batteryTimeRemaining("2h")
      expect(
        find.text(l10n.batteryTimeRemaining(l10n.batteryHours(2))),
        findsOneWidget,
      );
      // battery progress bar is present
      expect(find.byType(BatteryProgressBar), findsOneWidget);

      // 4. Toggle Battery Saver ON
      final batterySaverToggle = find.byType(CustomToggle);
      expect(batterySaverToggle, findsOneWidget);

      // Verify it's off initially
      expect(tester.widget<CustomToggle>(batterySaverToggle).value, isFalse);

      // Tap to toggle ON
      await tester.tap(batterySaverToggle);
      await tester.pumpAndSettle();

      // Verify it toggled to ON in the UI and state updated
      expect(tester.widget<CustomToggle>(batterySaverToggle).value, isTrue);
      expect(fakeBatteryRepository.mode, PowerProfileMode.powerSaver);

      // Tap to toggle OFF
      await tester.tap(batterySaverToggle);
      await tester.pumpAndSettle();

      // Verify it toggled back to OFF in the UI
      expect(tester.widget<CustomToggle>(batterySaverToggle).value, isFalse);
      expect(fakeBatteryRepository.mode, PowerProfileMode.balanced);

      // 5. Simulate property change from D-Bus event stream
      // Change repo values to charging at 100%, 30 minutes (1800 seconds) remaining until full
      fakeBatteryRepository.percentage = 100.0;
      fakeBatteryRepository.status = UPowerDeviceState.charging;
      fakeBatteryRepository.chargingTime = 1800; // 30 minutes
      fakeBatteryRepository.remainingTime = 0;

      // Trigger the stream event
      fakeBatteryRepository.triggerEvent(['Percentage', 'State', 'TimeToFull']);
      await tester.pumpAndSettle();

      // Verify UI has updated dynamically
      expect(find.text(l10n.batteryPercentage(100)), findsOneWidget);
      expect(find.text(l10n.charging), findsOneWidget);
      expect(
        find.text(l10n.batteryTimeUntilFull(l10n.batteryMinutes(30))),
        findsOneWidget,
      );

      // 6. Navigate back using the back button
      final backButton = findBackButton();
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we are back on SettingsMenuScreen
      expect(find.byType(SettingsMenuScreen), findsOneWidget);
    });
  });
}
