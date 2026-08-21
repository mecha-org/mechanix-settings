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
import 'package:mechanix_settings/features/sound/presentation/screens/sound_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/output_device_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/input_device_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/notification_sound_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/widgets/volume_slider.dart';
import 'package:mechanix_settings/features/sound/data/repositories/sound_repository.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/data/models/enums.dart';

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
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mechanix_settings/core/constants/icons.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class MockDateTimeRepository extends Mock implements DateTimeRepository {}

class MockBatteryRepository extends Mock implements BatteryRepository {}

class MockAboutRepository extends Mock implements AboutRepository {}

class FakeSoundRepository implements SoundRepository {
  double outputVolume = 0.5;
  double inputVolume = 0.4;

  List<String> outputDevices = [
    'Internal Speakers',
    'HDMI Audio',
    'Bluetooth Headphones',
  ];
  String selectedOutputDevice = 'Internal Speakers';

  List<String> inputDevices = ['Internal Microphone', 'USB Microphone'];
  String selectedInputDevice = 'Internal Microphone';

  bool launcherSoundsEnabled = true;
  bool hapticFeedbackEnabled = false;

  List<String> notificationSounds = ['Default', 'Chime', 'Beep', 'None'];
  String selectedNotificationSound = 'Default';

  final _changeController = StreamController<SoundChangeType>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Stream<SoundChangeType> get onSoundChanged => _changeController.stream;

  @override
  Future<double> getOutputVolume() async => outputVolume;

  @override
  Future<void> setOutputVolume(double volume) async {
    outputVolume = volume;
    _changeController.add(SoundChangeType.outputVolume);
  }

  @override
  Future<List<String>> getOutputDevices() async => outputDevices;

  @override
  Future<String> getSelectedOutputDevice() async => selectedOutputDevice;

  @override
  Future<void> setSelectedOutputDevice(String device) async {
    selectedOutputDevice = device;
    _changeController.add(SoundChangeType.outputDevice);
  }

  @override
  Future<double> getInputVolume() async => inputVolume;

  @override
  Future<void> setInputVolume(double volume) async {
    inputVolume = volume;
    _changeController.add(SoundChangeType.inputVolume);
  }

  @override
  Future<List<String>> getInputDevices() async => inputDevices;

  @override
  Future<String> getSelectedInputDevice() async => selectedInputDevice;

  @override
  Future<void> setSelectedInputDevice(String device) async {
    selectedInputDevice = device;
    _changeController.add(SoundChangeType.inputDevice);
  }

  @override
  Future<bool> getLauncherSoundsEnabled() async => launcherSoundsEnabled;

  @override
  Future<void> setLauncherSoundsEnabled(bool enabled) async {
    launcherSoundsEnabled = enabled;
  }

  @override
  Future<bool> getHapticFeedbackEnabled() async => hapticFeedbackEnabled;

  @override
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    hapticFeedbackEnabled = enabled;
  }

  @override
  Future<List<String>> getNotificationSounds() async => notificationSounds;

  @override
  Future<String> getSelectedNotificationSound() async =>
      selectedNotificationSound;

  @override
  Future<void> setSelectedNotificationSound(String sound) async {
    selectedNotificationSound = sound;
  }

  @override
  Future<void> close() async {
    await _changeController.close();
  }

  void triggerEvent(SoundChangeType type) {
    _changeController.add(type);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Sound Integration Tests', () {
    late MockWirelessRepository mockWirelessRepository;
    late MockBluetoothRepository mockBluetoothRepository;
    late MockDateTimeRepository mockDateTimeRepository;
    late MockBatteryRepository mockBatteryRepository;
    late MockAboutRepository mockAboutRepository;
    late FakeSoundRepository fakeSoundRepository;

    setUp(() {
      mockWirelessRepository = MockWirelessRepository();
      mockBluetoothRepository = MockBluetoothRepository();
      mockDateTimeRepository = MockDateTimeRepository();
      mockBatteryRepository = MockBatteryRepository();
      mockAboutRepository = MockAboutRepository();
      fakeSoundRepository = FakeSoundRepository();

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
          RepositoryProvider<SoundRepository>.value(
            value: fakeSoundRepository,
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
              create: (context) => BatteryBloc(
                batteryRepository: context.read<BatteryRepository>(),
              )
                ..add(const BatteryInit())
                ..add(const BatteryInfoRequested()),
            ),
            BlocProvider<AboutBloc>(
              create: (context) => AboutBloc(context.read<AboutRepository>())
                ..add(const LoadAboutDetails()),
            ),
            BlocProvider<SoundBloc>(
              create: (context) =>
                  SoundBloc(soundRepository: context.read<SoundRepository>())
                    ..add(const SoundInit())
                    ..add(const LoadSoundSettings()),
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

    Finder findRefreshButton() {
      return find.descendant(
        of: find.byType(BottomBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              (widget.image as AssetImage).assetName == SettingIcons.refresh,
        ),
      );
    }

    testWidgets('Verify complete Sound settings flow', (
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

      // 2. Navigate to Sound settings screen
      final soundItem = find.text(l10n.sound);
      await tester.ensureVisible(soundItem);
      await tester.pump();
      await tester.tap(soundItem);
      await tester.pumpAndSettle();

      // Verify we are on SoundScreen
      expect(find.byType(SoundScreen), findsOneWidget);

      // Verify initial state values from FakeSoundRepository
      expect(
        find.text(l10n.volumePercentage((0.5 * 100).round())),
        findsOneWidget,
      );
      expect(
        find.text(l10n.volumePercentage((0.4 * 100).round())),
        findsOneWidget,
      );
      expect(find.text('Internal Speakers'), findsOneWidget);
      expect(find.text('Internal Microphone'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);

      // 3. Test volume slider muting / unmuting via the mute button
      final outputVolumeSlider = find.byType(VolumeSlider).first;
      final muteButton = find.descendant(
        of: outputVolumeSlider,
        matching: find.byType(CustomIconButton),
      );
      expect(muteButton, findsOneWidget);

      // Tap mute
      await tester.tap(muteButton);
      await tester.pumpAndSettle();
      expect(fakeSoundRepository.outputVolume, 0.0);

      // Tap unmute
      await tester.tap(muteButton);
      await tester.pumpAndSettle();
      expect(fakeSoundRepository.outputVolume, 0.5);

      // 4. Toggle Launcher Sounds
      final launcherRow = find.ancestor(
        of: find.text(l10n.launcher),
        matching: find.byWidgetPredicate((widget) => widget is Row),
      );
      final launcherToggle = find.descendant(
        of: launcherRow,
        matching: find.byType(CustomToggle),
      );
      expect(launcherToggle, findsOneWidget);

      // Verify it's on initially
      expect(tester.widget<CustomToggle>(launcherToggle).value, isTrue);

      // Scroll launcher toggle into view and tap to toggle OFF
      await tester.ensureVisible(launcherToggle);
      await tester.pump();
      await tester.tap(launcherToggle);
      await tester.pumpAndSettle();
      expect(fakeSoundRepository.launcherSoundsEnabled, isFalse);

      // 5. Toggle Haptic Feedback
      final hapticRow = find.ancestor(
        of: find.text(l10n.hapticFeedback),
        matching: find.byWidgetPredicate((widget) => widget is Row),
      );
      final hapticToggle = find.descendant(
        of: hapticRow,
        matching: find.byType(CustomToggle),
      );
      expect(hapticToggle, findsOneWidget);

      // Verify it's off initially
      expect(tester.widget<CustomToggle>(hapticToggle).value, isFalse);

      // Scroll haptic toggle into view and tap to toggle ON
      await tester.ensureVisible(hapticToggle);
      await tester.pump();
      await tester.tap(hapticToggle);
      await tester.pumpAndSettle();
      expect(fakeSoundRepository.hapticFeedbackEnabled, isTrue);

      // 6. Navigate to Output Device Screen and change device
      final outputDeviceRow = find.text('Internal Speakers');
      await tester.ensureVisible(outputDeviceRow);
      await tester.pump();
      await tester.tap(outputDeviceRow);
      await tester.pumpAndSettle();

      expect(find.byType(OutputDeviceScreen), findsOneWidget);
      expect(find.text('Internal Speakers'), findsOneWidget);
      expect(find.text('HDMI Audio'), findsOneWidget);
      expect(find.text('Bluetooth Headphones'), findsOneWidget);

      // Tap 'HDMI Audio' to select it
      await tester.tap(find.text('HDMI Audio'));
      await tester.pumpAndSettle();
      expect(fakeSoundRepository.selectedOutputDevice, 'HDMI Audio');

      // Tap refresh button on OutputDeviceScreen
      final outputRefreshBtn = findRefreshButton();
      expect(outputRefreshBtn, findsOneWidget);
      await tester.tap(outputRefreshBtn);
      await tester.pumpAndSettle();

      // Go back to SoundScreen
      final outputBackBtn = findBackButton();
      await tester.tap(outputBackBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SoundScreen), findsOneWidget);
      expect(find.text('HDMI Audio'), findsOneWidget);

      // 7. Navigate to Input Device Screen and change device
      final inputDeviceRow = find.text('Internal Microphone');
      await tester.ensureVisible(inputDeviceRow);
      await tester.pump();
      await tester.tap(inputDeviceRow);
      await tester.pumpAndSettle();

      expect(find.byType(InputDeviceScreen), findsOneWidget);
      expect(find.text('Internal Microphone'), findsOneWidget);
      expect(find.text('USB Microphone'), findsOneWidget);

      // Tap 'USB Microphone' to select it
      await tester.tap(find.text('USB Microphone'));
      await tester.pumpAndSettle();
      expect(fakeSoundRepository.selectedInputDevice, 'USB Microphone');

      // Tap refresh button on InputDeviceScreen
      final inputRefreshBtn = findRefreshButton();
      expect(inputRefreshBtn, findsOneWidget);
      await tester.tap(inputRefreshBtn);
      await tester.pumpAndSettle();

      // Go back to SoundScreen
      final inputBackBtn = findBackButton();
      await tester.tap(inputBackBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SoundScreen), findsOneWidget);
      expect(find.text('USB Microphone'), findsOneWidget);

      // 8. Navigate to Notification Sound Screen and change sound
      final notificationSoundRow = find.text('Default');
      await tester.ensureVisible(notificationSoundRow);
      await tester.pump();
      await tester.tap(notificationSoundRow);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSoundScreen), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Chime'), findsOneWidget);
      expect(find.text('Beep'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);

      // Tap 'Chime' to select it
      await tester.tap(find.text('Chime'));
      await tester.pumpAndSettle();
      expect(fakeSoundRepository.selectedNotificationSound, 'Chime');

      // Go back to SoundScreen
      final notificationBackBtn = findBackButton();
      await tester.tap(notificationBackBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SoundScreen), findsOneWidget);
      expect(find.text('Chime'), findsOneWidget);

      // 9. Go back to Settings Menu
      final soundBackBtn = findBackButton();
      await tester.tap(soundBackBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsMenuScreen), findsOneWidget);
    });
  });
}
