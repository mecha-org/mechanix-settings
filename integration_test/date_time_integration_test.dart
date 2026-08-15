import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/cupertino.dart';

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/date_time_screen.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/timezone_screen.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/time_picker_screen.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/date_picker_screen.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/time_format_screen.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class FakeDateTimeRepository implements DateTimeRepository {
  bool ntpEnabled = true;
  String timezone = 'Asia/Kolkata';
  String timeFormat = '24h';
  int? lastSetTimeMicroseconds;

  final _propertiesChangedController =
      StreamController<List<String>>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<bool> getNtpEnabled() async => ntpEnabled;

  @override
  Future<void> setNtpEnabled(bool enabled) async {
    ntpEnabled = enabled;
    _propertiesChangedController.add(['NTP']);
  }

  @override
  Future<String> getTimezone() async => timezone;

  @override
  Future<void> setTimezone(String tz) async {
    timezone = tz;
    _propertiesChangedController.add(['Timezone']);
  }

  @override
  Future<void> setTime(int microsecondsSinceEpoch) async {
    lastSetTimeMicroseconds = microsecondsSinceEpoch;
    _propertiesChangedController.add(['TimeUSec']);
  }

  @override
  Future<DateTime> getSystemTime() async => DateTime.now();

  @override
  Stream<List<String>> get propertiesChangedStream =>
      _propertiesChangedController.stream;

  @override
  Future<void> close() async {
    await _propertiesChangedController.close();
  }

  @override
  Future<String> getTimeFormat() async => timeFormat;

  @override
  Future<void> setTimeFormat(String format) async {
    timeFormat = format;
    _propertiesChangedController.add(['TimeFormat']);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Date & Time Integration Tests', () {
    late MockWirelessRepository mockWirelessRepository;
    late MockBluetoothRepository mockBluetoothRepository;
    late FakeDateTimeRepository fakeDateTimeRepository;

    setUp(() {
      mockWirelessRepository = MockWirelessRepository();
      mockBluetoothRepository = MockBluetoothRepository();
      fakeDateTimeRepository = FakeDateTimeRepository();

      // Wireless Repository Mock defaults
      when(() => mockWirelessRepository.init()).thenAnswer((_) async {});
      // when(() => mockWirelessRepository.).thenAnswer((_) async {});
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
            value: fakeDateTimeRepository,
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

    Finder findCheckButton() {
      return find
          .descendant(
            of: find.byType(BottomBar),
            matching: find.byType(CustomIconButton),
          )
          .last;
    }

    testWidgets('Full Date & Time configuration flow', (
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

      // 2. Navigate to Date & Time settings screen
      final timeAndDateItem = find.text(l10n.timeAndDate);

      await tester.ensureVisible(timeAndDateItem);
      await tester.pump();

      await tester.tap(timeAndDateItem);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.byType(DateTimeScreen), findsOneWidget);

      // 3. Verify initial state: Auto Time is ON, Set Time and Set Date are hidden
      expect(find.text(l10n.setTime), findsNothing);
      expect(find.text(l10n.setDate), findsNothing);

      // Verify default Timezone (Kolkata) and Time Format (24-hour)
      expect(find.text(l10n.timezoneIst), findsOneWidget);
      expect(find.text(l10n.format24Hour), findsOneWidget);

      // 4. Toggle Auto Time to OFF, verify Set Time and Set Date appear
      final autoTimeToggle = find.byType(CustomToggle);
      expect(autoTimeToggle, findsOneWidget);
      await tester.tap(autoTimeToggle);
      await tester.pumpAndSettle();

      expect(find.text(l10n.setTime), findsOneWidget);
      expect(find.text(l10n.setDate), findsOneWidget);

      // 5. Navigate to Timezone screen and select Paris timezone
      final timezoneRow = find.text(l10n.timezone);
      expect(timezoneRow, findsOneWidget);
      await tester.tap(timezoneRow);
      await tester.pumpAndSettle();

      expect(find.byType(TimezoneScreen), findsOneWidget);

      final pdtTz = find.text(l10n.timezonePdt);
      // expect(parisTz, findsOneWidget);
      await tester.ensureVisible(pdtTz);
      await tester.pump();

      await tester.tap(pdtTz);
      await tester.pumpAndSettle();

      // Go back to Date & Time screen
      await tester.tap(findBackButton());
      await tester.pumpAndSettle();

      expect(find.byType(DateTimeScreen), findsOneWidget);
      expect(find.text(l10n.timezonePdt), findsOneWidget);

      // 6. Navigate to Time Format screen and select 12-hour format
      final formatRow = find.text(l10n.timeFormat);
      expect(formatRow, findsOneWidget);
      await tester.tap(formatRow);
      await tester.pumpAndSettle();

      expect(find.byType(TimeFormatScreen), findsOneWidget);

      final format12 = find.text(l10n.format12Hour);
      expect(format12, findsOneWidget);
      await tester.tap(format12);
      await tester.pumpAndSettle();

      // Go back to Date & Time screen
      await tester.tap(findBackButton());
      await tester.pumpAndSettle();

      expect(find.byType(DateTimeScreen), findsOneWidget);
      expect(find.text(l10n.format12Hour), findsOneWidget);

      // 7. Navigate to Set Time screen and select a custom time (e.g. 10:45 AM)
      final setTimeRow = find.text(l10n.setTime);
      expect(setTimeRow, findsOneWidget);
      await tester.tap(setTimeRow);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerScreen), findsOneWidget);

      final timePickers = find.byType(CupertinoPicker);
      expect(timePickers, findsNWidgets(3));

      final hourPicker = find.byType(CupertinoPicker).at(0);
      await tester.drag(hourPicker, const Offset(0, -300));

      await tester.pumpAndSettle();
      final minutePicker = find.byType(CupertinoPicker).at(1);
      await tester.drag(minutePicker, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap Check/Save button
      await tester.tap(findCheckButton());
      await tester.pumpAndSettle();

      expect(find.byType(DateTimeScreen), findsOneWidget);

      // 8. Navigate to Set Date screen and select a custom date
      final setDateRow = find.text(l10n.setDate);
      expect(setDateRow, findsOneWidget);
      await tester.tap(setDateRow);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerScreen), findsOneWidget);

      final datePickers = find.byType(CupertinoPicker);
      expect(datePickers, findsNWidgets(3)); // Day, Month, Year

      final dayPicker = find.byType(CupertinoPicker).at(0);
      await tester.drag(dayPicker, const Offset(0, -300));
      await tester.pumpAndSettle();

      final monthPicker = find.byType(CupertinoPicker).at(1);
      await tester.drag(monthPicker, const Offset(0, -300));
      await tester.pumpAndSettle();

      final yearPicker = find.byType(CupertinoPicker).at(2);
      await tester.drag(yearPicker, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap Check/Save button
      await tester.tap(findCheckButton());
      await tester.pumpAndSettle();

      expect(find.byType(DateTimeScreen), findsOneWidget);
    });
  });
}
