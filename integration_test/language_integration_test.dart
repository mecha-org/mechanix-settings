import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:upower/upower.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/language/presentation/screens/language_screen.dart';
import 'package:mechanix_settings/features/language/data/repositories/language_repository.dart';
import 'package:mechanix_settings/features/language/blocs/language_bloc.dart';
import 'package:mechanix_settings/features/language/blocs/language_event.dart';

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
import 'package:mechanix_settings/features/about/data/repositories/about_repository.dart';
import 'package:mechanix_settings/features/about/blocs/about_bloc.dart';
import 'package:mechanix_settings/features/about/blocs/about_event.dart';
import 'package:mechanix_settings/features/about/data/models/about_details.dart';
import 'package:mechanix_settings/features/sound/data/repositories/sound_repository.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mechanix_settings/core/constants/icons.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class MockDateTimeRepository extends Mock implements DateTimeRepository {}

class MockBatteryRepository extends Mock implements BatteryRepository {}

class MockAboutRepository extends Mock implements AboutRepository {}

class MockSoundRepository extends Mock implements SoundRepository {}

class FakeLanguageRepository implements LanguageRepository {
  String language = 'en_US.UTF-8';
  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<String> getLanguage() async => language;

  @override
  Future<void> setLanguage(String lang) async {
    language = lang;
    _propertiesChangedController.add(['Language']);
  }

  @override
  Future<void> close() async {
    await _propertiesChangedController.close();
  }

  @override
  Stream<List<String>> get propertiesChangedStream =>
      _propertiesChangedController.stream;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Language Integration Tests', () {
    late MockWirelessRepository mockWirelessRepository;
    late MockBluetoothRepository mockBluetoothRepository;
    late MockDateTimeRepository mockDateTimeRepository;
    late MockBatteryRepository mockBatteryRepository;
    late MockAboutRepository mockAboutRepository;
    late MockSoundRepository mockSoundRepository;
    late FakeLanguageRepository fakeLanguageRepository;

    setUp(() {
      mockWirelessRepository = MockWirelessRepository();
      mockBluetoothRepository = MockBluetoothRepository();
      mockDateTimeRepository = MockDateTimeRepository();
      mockBatteryRepository = MockBatteryRepository();
      mockAboutRepository = MockAboutRepository();
      mockSoundRepository = MockSoundRepository();
      fakeLanguageRepository = FakeLanguageRepository();

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
        ),
      );

      // Sound Repository Mock defaults
      when(() => mockSoundRepository.init()).thenAnswer((_) async {});
      when(
        () => mockSoundRepository.getOutputVolume(),
      ).thenAnswer((_) async => 0.5);
      when(
        () => mockSoundRepository.getInputVolume(),
      ).thenAnswer((_) async => 0.5);
      when(
        () => mockSoundRepository.getOutputDevices(),
      ).thenAnswer((_) async => ['Speakers']);
      when(
        () => mockSoundRepository.getSelectedOutputDevice(),
      ).thenAnswer((_) async => 'Speakers');
      when(
        () => mockSoundRepository.getInputDevices(),
      ).thenAnswer((_) async => ['Mic']);
      when(
        () => mockSoundRepository.getSelectedInputDevice(),
      ).thenAnswer((_) async => 'Mic');
      when(
        () => mockSoundRepository.getLauncherSoundsEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockSoundRepository.getHapticFeedbackEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockSoundRepository.getNotificationSounds(),
      ).thenAnswer((_) async => ['Default']);
      when(
        () => mockSoundRepository.getSelectedNotificationSound(),
      ).thenAnswer((_) async => 'Default');
      when(
        () => mockSoundRepository.onSoundChanged,
      ).thenAnswer((_) => const Stream<SoundChangeType>.empty());
      when(() => mockSoundRepository.close()).thenAnswer((_) async {});
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
          RepositoryProvider<AboutRepository>.value(value: mockAboutRepository),
          RepositoryProvider<SoundRepository>.value(value: mockSoundRepository),
          RepositoryProvider<LanguageRepository>.value(
            value: fakeLanguageRepository,
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
            BlocProvider<SoundBloc>(
              create: (context) =>
                  SoundBloc(soundRepository: context.read<SoundRepository>())
                    ..add(const SoundInit())
                    ..add(const LoadSoundSettings()),
            ),
            BlocProvider<LanguageBloc>(
              create: (context) =>
                  LanguageBloc(context.read<LanguageRepository>())
                    ..add(const InitializeLanguage()),
            ),
          ],
          child: const MechanixSettingsApp(),
        ),
      );
    }

    Finder findBackButton() {
      return find.descendant(
        of: find.byType(BottomBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              (widget.image as AssetImage).assetName == SettingIcons.back,
        ),
      );
    }

    testWidgets('Verify Language settings flow', (WidgetTester tester) async {
      // 1. Launch the application
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify we are on SettingsMenuScreen
      expect(find.byType(SettingsMenuScreen), findsOneWidget);

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // 2. Navigate to Language settings screen
      final languageItem = find.text(l10n.language);
      await tester.ensureVisible(languageItem);
      await tester.pump();
      await tester.tap(languageItem);
      await tester.pumpAndSettle();

      // Verify we are on LanguageScreen
      expect(find.byType(LanguageScreen), findsOneWidget);

      // Verify options are visible
      expect(find.text(l10n.languageEnglishUK), findsOneWidget);
      expect(find.text(l10n.languageEnglishUS), findsOneWidget);

      // Tap 'English- UK' option
      final englishUKTile = find.text(l10n.languageEnglishUK);
      await tester.tap(englishUKTile);
      await tester.pumpAndSettle();

      // Verify that repository updated
      expect(fakeLanguageRepository.language, equals('en_GB.UTF-8'));

      // Go back to Settings Menu
      final backButton = findBackButton();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsMenuScreen), findsOneWidget);
    });
  });
}
