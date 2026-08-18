import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_rename.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_device_list_item.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';

import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

class MockWirelessRepository extends Mock implements WirelessRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bluetooth Integration Tests', () {
    late MockBluetoothRepository mockBluetoothRepository;
    late MockWirelessRepository mockWirelessRepository;

    late StreamController<bool> bluetoothPowerController;
    late StreamController<bool> bluetoothDiscoverableController;
    late StreamController<bool> bluetoothScanningController;
    late StreamController<List<BluetoothDevice>> bluetoothDevicesController;

    setUpAll(() {
      registerFallbackValue(
        const BluetoothDevice(
          name: 'Fallback Device',
          deviceName: 'Fallback Device',
          type: BluetoothDeviceType.unknown,
        ),
      );
    });

    setUp(() {
      bluetoothPowerController = StreamController<bool>.broadcast();
      bluetoothDiscoverableController = StreamController<bool>.broadcast();
      bluetoothScanningController = StreamController<bool>.broadcast();
      bluetoothDevicesController =
          StreamController<List<BluetoothDevice>>.broadcast();

      mockBluetoothRepository = MockBluetoothRepository();
      mockWirelessRepository = MockWirelessRepository();

      // Setup Bluetooth stubs
      when(() => mockBluetoothRepository.init()).thenAnswer((_) async {});
      when(
        () => mockBluetoothRepository.powerStream,
      ).thenAnswer((_) => bluetoothPowerController.stream);
      when(
        () => mockBluetoothRepository.discoverableStream,
      ).thenAnswer((_) => bluetoothDiscoverableController.stream);
      when(
        () => mockBluetoothRepository.scanningStream,
      ).thenAnswer((_) => bluetoothScanningController.stream);
      when(
        () => mockBluetoothRepository.devicesStream,
      ).thenAnswer((_) => bluetoothDevicesController.stream);
      when(() => mockBluetoothRepository.close()).thenAnswer((_) async {});

      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBluetoothRepository.getLocalDeviceName(),
      ).thenAnswer((_) async => 'comet');
      when(
        () => mockBluetoothRepository.isDiscoverable(),
      ).thenAnswer((_) async => false);
      when(
        () => mockBluetoothRepository.getPairedDevices(),
      ).thenAnswer((_) async => []);

      // Setup Wireless stubs
      when(() => mockWirelessRepository.init()).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.getWifiEventsStream(),
      ).thenAnswer((_) => const Stream<List<String>>.empty());
      when(
        () => mockWirelessRepository.getDeviceEventsStream(),
      ).thenAnswer((_) => const Stream<List<String>>.empty());
      when(
        () => mockWirelessRepository.getWirelessDeviceEventsStream(),
      ).thenAnswer((_) => const Stream<List<String>>.empty());
      when(
        () => mockWirelessRepository.isWirelessEnabled(),
      ).thenAnswer((_) => false);

      when(
        () => mockBluetoothRepository.startDiscovery(),
      ).thenAnswer((_) async {});

      when(
        () => mockBluetoothRepository.stopDiscovery(),
      ).thenAnswer((_) async {});

      when(
        () => mockBluetoothRepository.togglePower(any()),
      ).thenAnswer((_) async => true);

      when(
        () => mockBluetoothRepository.setDiscoverable(any()),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      bluetoothPowerController.close();
      bluetoothDiscoverableController.close();
      bluetoothScanningController.close();
      bluetoothDevicesController.close();
    });

    Widget createTestApp(
      MockWirelessRepository mockWirelessRepository,
      MockBluetoothRepository mockBluetoothRepository,
    ) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<WirelessRepository>.value(
            value: mockWirelessRepository,
          ),
          RepositoryProvider<BluetoothRepository>.value(
            value: mockBluetoothRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<WirelessBloc>(
              lazy: false,
              create: (context) => WirelessBloc(
                wirelessRepository: context.read<WirelessRepository>(),
              )..add(InitWifi()),
            ),
            BlocProvider<BluetoothBloc>(
              lazy: false,
              create: (context) =>
                  BluetoothBloc(context.read<BluetoothRepository>())
                    ..add(const LoadBluetooth()),
            ),
          ],
          child: const MechanixSettingsApp(),
        ),
      );
    }

    Finder findButtonByAsset(String assetPath) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is CustomIconButton &&
            widget.icon is Image &&
            (widget.icon as Image).image is AssetImage &&
            ((widget.icon as Image).image as AssetImage).assetName == assetPath,
      );
    }

    testWidgets(
      'Bluetooth navigation and initial screen state (Bluetooth OFF)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(mockWirelessRepository, mockBluetoothRepository),
        );
        await tester.pumpAndSettle();

        // We should be on SettingsMenuScreen first.
        expect(find.byType(SettingsMenuScreen), findsOneWidget);

        final bluetoothMenuTile = find.text('Bluetooth');
        expect(bluetoothMenuTile, findsOneWidget);

        // Tap on it and wait for transition to complete
        await tester.tap(bluetoothMenuTile);
        await tester.pumpAndSettle();

        // Verify we are now on BluetoothScreen
        expect(find.byType(BluetoothScreen), findsOneWidget);

        // Verify initial state: other components are hidden.
        expect(find.text('Discoverable'), findsNothing);
        expect(find.text('My devices'), findsNothing);
        expect(find.text('Other devices'), findsNothing);

        // Go back using the back button
        final backButton = findButtonByAsset(SettingIcons.back);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verify we are back on SettingsMenuScreen
        expect(find.byType(SettingsMenuScreen), findsOneWidget);
      },
    );

    testWidgets('Toggling Bluetooth ON and discoverability', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(mockWirelessRepository, mockBluetoothRepository),
      );
      await tester.pumpAndSettle();

      // Go to Bluetooth Screen
      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();

      // Find the toggle for Bluetooth power.
      final powerToggle = find.descendant(
        of: find
            .ancestor(of: find.text('Bluetooth'), matching: find.byType(Row))
            .first,
        matching: find.byType(CustomToggle),
      );
      expect(powerToggle, findsOneWidget);

      // Tap to toggle ON.
      await tester.tap(powerToggle);
      await tester.pump();

      // Verify togglePower(true) is called.
      verify(() => mockBluetoothRepository.togglePower(true)).called(1);

      // Simulate repository streams emitting Bluetooth ON
      bluetoothPowerController.add(true);
      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => true);

      // Let's also emit list of devices
      const testDevice = BluetoothDevice(
        name: 'Paired Phone',
        deviceName: 'Paired Phone',
        type: BluetoothDeviceType.mobile,
        macAddress: '11:22:33:44:55:66',
        isSaved: true,
        isConnected: false,
      );
      const testDiscoveredDevice = BluetoothDevice(
        name: 'Headphones',
        deviceName: 'Headphones',
        type: BluetoothDeviceType.headphones,
        macAddress: 'AA:BB:CC:DD:EE:FF',
        isSaved: false,
        isConnected: false,
      );

      bluetoothDevicesController.add([testDevice, testDiscoveredDevice]);

      // Pump to reflect state
      await tester.pumpAndSettle();

      // Verify that discoverable option appears and My/Other devices headers appear.
      expect(find.text('Discoverable'), findsOneWidget);
      expect(find.text('My devices'), findsOneWidget);
      expect(find.text('Other devices'), findsOneWidget);

      // Verify devices are listed
      expect(find.text('Paired Phone'), findsOneWidget);
      expect(find.text('Headphones'), findsOneWidget);

      // Toggle Discoverable ON
      final discoverableToggle = find.descendant(
        of: find
            .ancestor(of: find.text('Discoverable'), matching: find.byType(Row))
            .first,
        matching: find.byType(CustomToggle),
      );
      expect(discoverableToggle, findsOneWidget);

      await tester.tap(discoverableToggle);
      await tester.pump();

      // Verify setDiscoverable(true) is called
      verify(() => mockBluetoothRepository.setDiscoverable(true)).called(1);
    });

    testWidgets('Toggling Bluetooth ON and tapping Refresh/Scan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(mockWirelessRepository, mockBluetoothRepository),
      );
      await tester.pumpAndSettle();

      // Go to Bluetooth Screen
      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();

      // Enable Bluetooth
      final powerToggle = find.descendant(
        of: find
            .ancestor(of: find.text('Bluetooth'), matching: find.byType(Row))
            .first,
        matching: find.byType(CustomToggle),
      );
      await tester.tap(powerToggle);
      await tester.pump();

      bluetoothPowerController.add(true);
      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => true);
      await tester.pumpAndSettle();

      // The refresh button only displays in the bottom bar when Bluetooth is ON.
      final refreshBtn = findButtonByAsset(SettingIcons.refresh);
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pump();
    });

    testWidgets('Rename local device flow', (WidgetTester tester) async {
      when(
        () => mockBluetoothRepository.togglePower(true),
      ).thenAnswer((_) async => true);
      when(
        () => mockBluetoothRepository.updateLocalDeviceName(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestApp(mockWirelessRepository, mockBluetoothRepository),
      );
      await tester.pumpAndSettle();

      // Go to Bluetooth Screen
      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();

      // Tap on Device name config row
      final deviceNameRow = find.text('Device name');
      expect(deviceNameRow, findsOneWidget);
      await tester.tap(deviceNameRow);
      await tester.pumpAndSettle();

      // Now we should be on BluetoothRenameScreen
      expect(find.byType(BluetoothRenameScreen), findsOneWidget);

      // Verify text field contains initial name 'comet'
      final textFormFieldFinder = find.byType(TextField);
      expect(textFormFieldFinder, findsOneWidget);

      // Enter new name
      await tester.enterText(textFormFieldFinder, 'new-comet');
      await tester.pumpAndSettle();

      // Tap confirm button (SettingIcons.check)
      final checkButton = findButtonByAsset(SettingIcons.check);
      expect(checkButton, findsOneWidget);
      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      // Verify updateLocalDeviceName was called on repo
      verify(
        () => mockBluetoothRepository.updateLocalDeviceName('new-comet'),
      ).called(1);

      // Verify we are back on BluetoothScreen
      expect(find.byType(BluetoothScreen), findsOneWidget);
    });

    testWidgets('Device Detail interactions (Disconnect & Forget)', (
      WidgetTester tester,
    ) async {
      when(
        () => mockBluetoothRepository.togglePower(true),
      ).thenAnswer((_) async => true);
      when(
        () => mockBluetoothRepository.disconnectFromDevice(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockBluetoothRepository.forgetDevice(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestApp(mockWirelessRepository, mockBluetoothRepository),
      );
      await tester.pumpAndSettle();

      // Go to Bluetooth Screen
      await tester.tap(find.text('Bluetooth'));
      await tester.pumpAndSettle();

      // Enable Bluetooth
      final powerToggle = find.descendant(
        of: find
            .ancestor(of: find.text('Bluetooth'), matching: find.byType(Row))
            .first,
        matching: find.byType(CustomToggle),
      );
      await tester.tap(powerToggle);
      await tester.pump();

      bluetoothPowerController.add(true);
      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => true);

      // Emit connected device
      const testDevice = BluetoothDevice(
        name: 'Paired Phone',
        deviceName: 'Paired Phone',
        type: BluetoothDeviceType.mobile,
        macAddress: '11:22:33:44:55:66',
        isSaved: true,
        isConnected: true,
      );
      bluetoothDevicesController.add([testDevice]);
      await tester.pumpAndSettle();

      // Tap on settings button of Paired Phone
      final settingsButton = find.descendant(
        of: find.widgetWithText(BluetoothDeviceListItem, 'Paired Phone'),
        matching: findButtonByAsset(SettingIcons.setting),
      );
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Verify we are on BluetoothDeviceDetailScreen
      expect(find.byType(BluetoothDeviceDetailScreen), findsOneWidget);

      // Verify details are correct
      expect(find.text('Paired Phone'), findsNWidgets(2));
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);

      // Verify that "Disconnect" button is present and click it
      final disconnectBtn = findButtonByAsset(SettingIcons.disconnect);
      expect(disconnectBtn, findsOneWidget);
      await tester.tap(disconnectBtn);
      await tester.pumpAndSettle();

      // Verify disconnectFromDevice is called
      verify(
        () =>
            mockBluetoothRepository.disconnectFromDevice(testDevice.macAddress),
      ).called(1);

      // Verify we navigated back to BluetoothScreen
      expect(find.byType(BluetoothScreen), findsOneWidget);

      // Go to details page again (this time device is disconnected)
      const testDisconnectedDevice = BluetoothDevice(
        name: 'Paired Phone',
        deviceName: 'Paired Phone',
        type: BluetoothDeviceType.mobile,
        macAddress: '11:22:33:44:55:66',
        isSaved: true,
        isConnected: false,
      );
      bluetoothDevicesController.add([testDisconnectedDevice]);
      await tester.pumpAndSettle();

      final settingsButton2 = find.descendant(
        of: find.widgetWithText(BluetoothDeviceListItem, 'Paired Phone'),
        matching: findButtonByAsset(SettingIcons.setting),
      );
      await tester.tap(settingsButton2);
      await tester.pumpAndSettle();

      // Now verify we are on details screen and device status is Not connected
      expect(find.byType(BluetoothDeviceDetailScreen), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);

      // Verify that "Connect" button is present (because device.isConnected is false)
      final connectBtn = findButtonByAsset(SettingIcons.connect);
      expect(connectBtn, findsOneWidget);

      // Tap forget device button (delete icon)
      final forgetBtn = findButtonByAsset(SettingIcons.delete);
      expect(forgetBtn, findsOneWidget);
      await tester.tap(forgetBtn);
      await tester.pumpAndSettle();

      // Verify forgetDevice is called on repo
      verify(
        () => mockBluetoothRepository.forgetDevice(
          testDisconnectedDevice.macAddress,
        ),
      ).called(1);

      // Verify we navigated back to BluetoothScreen
      expect(find.byType(BluetoothScreen), findsOneWidget);
    });
  });
}
