import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_body.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/about_device_screen.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_connected_device_tile.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_device_list_item.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';

import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bluetooth Integration Tests', () {
    late MockBluetoothRepository mockBluetoothRepository;

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
      // mockWirelessRepository = MockWirelessRepository();

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
      when(
        () => mockBluetoothRepository.updateLocalDeviceName(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockBluetoothRepository.pairDevice(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockBluetoothRepository.connectToDevice(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockBluetoothRepository.disconnectFromDevice(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockBluetoothRepository.forgetDevice(any()),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      bluetoothPowerController.close();
      bluetoothDiscoverableController.close();
      bluetoothScanningController.close();
      bluetoothDevicesController.close();
    });

    Widget createTestApp(MockBluetoothRepository mockBluetoothRepository) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BluetoothRepository>.value(
            value: mockBluetoothRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<BluetoothBloc>(
              create: (_) =>
                  BluetoothBloc(mockBluetoothRepository)
                    ..add(const LoadBluetooth()),
            ),
          ],
          child: const MechanixSettingsApp(),
        ),
      );
    }

    Finder findMechanixIconButtonByAsset(String assetPath) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            ((widget.icon is ImageIcon &&
                    (widget.icon as ImageIcon).image is AssetImage &&
                    ((widget.icon as ImageIcon).image as AssetImage)
                            .assetName ==
                        assetPath) ||
                (widget.icon is Image &&
                    (widget.icon as Image).image is AssetImage &&
                    ((widget.icon as Image).image as AssetImage).assetName ==
                        assetPath)),
      );
    }

    testWidgets('Bluetooth navigation and initial screen state (Bluetooth OFF)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(mockBluetoothRepository));
      await tester.pumpAndSettle();

      // We should be on SettingsMenuScreen first.
      expect(find.byType(SettingsMenuScreen), findsOneWidget);

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      final bluetoothMenuTile = find.text(l10n.bluetooth);
      expect(bluetoothMenuTile, findsOneWidget);

      // Tap on Bluetooth and wait for transition to complete
      await tester.tap(bluetoothMenuTile);
      await tester.pumpAndSettle();

      // Verify we are now on BluetoothScreen
      expect(find.byType(BluetoothScreen), findsOneWidget);

      // App bar title is uppercase, toggle row label keeps original casing
      expect(find.text(l10n.bluetooth.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.bluetooth), findsOneWidget);

      // Verify Bluetooth power switch is OFF
      final powerSwitch = find.byType(MechanixSwitch);
      expect(powerSwitch, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(powerSwitch).value, isFalse);

      // Verify About Device tile and device sections are hidden when Bluetooth is OFF
      expect(find.byKey(const ValueKey('about_device_tile')), findsNothing);
      expect(find.byKey(const ValueKey('my_devices')), findsNothing);
      expect(find.byKey(const ValueKey('other_devices')), findsNothing);
      expect(find.byType(BluetoothConnectedDeviceTile), findsNothing);

      // Go back using the back button
      final backButton = findMechanixIconButtonByAsset(SettingIcons.back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we are back on SettingsMenuScreen
      expect(find.byType(SettingsMenuScreen), findsOneWidget);
    });

    testWidgets('Toggling Bluetooth ON and displaying device sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(mockBluetoothRepository));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Go to Bluetooth Screen
      await tester.tap(find.text(l10n.bluetooth));
      await tester.pumpAndSettle();

      // Find the toggle for Bluetooth power
      final powerSwitch = find.byType(MechanixSwitch);
      expect(powerSwitch, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(powerSwitch).value, isFalse);

      // Tap to toggle ON
      await tester.tap(powerSwitch);
      await tester.pump();

      // Verify togglePower(true) is called
      verify(() => mockBluetoothRepository.togglePower(true)).called(1);

      // Simulate repository streams emitting Bluetooth ON
      bluetoothPowerController.add(true);
      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => true);

      // Emit connected device, paired device, and discovered device
      const connectedDevice = BluetoothDevice(
        name: 'Connected Audio',
        deviceName: 'Connected Audio',
        type: BluetoothDeviceType.headphones,
        macAddress: '11:11:11:11:11:11',
        isSaved: true,
        isConnected: true,
      );
      const pairedDevice = BluetoothDevice(
        name: 'Paired Phone',
        deviceName: 'Paired Phone',
        type: BluetoothDeviceType.mobile,
        macAddress: '22:22:22:22:22:22',
        isSaved: true,
        isConnected: false,
      );
      const discoveredDevice = BluetoothDevice(
        name: 'Nearby Speaker',
        deviceName: 'Nearby Speaker',
        type: BluetoothDeviceType.speaker,
        macAddress: '33:33:33:33:33:33',
        isSaved: false,
        isConnected: false,
      );

      bluetoothDevicesController.add([
        connectedDevice,
        pairedDevice,
        discoveredDevice,
      ]);

      await tester.pumpAndSettle();

      // Verify power switch is now ON
      expect(tester.widget<MechanixSwitch>(powerSwitch).value, isTrue);

      // Verify connected device is displayed as BluetoothConnectedDeviceTile
      expect(find.byType(BluetoothConnectedDeviceTile), findsOneWidget);
      expect(find.text('Connected Audio'), findsOneWidget);

      // Connected device tile exposes a settings button
      expect(
        find.descendant(
          of: find.byType(BluetoothConnectedDeviceTile),
          matching: findMechanixIconButtonByAsset(SettingIcons.setting),
        ),
        findsOneWidget,
      );

      // Verify About Device tile is shown with the local device name
      expect(find.byKey(const ValueKey('about_device_tile')), findsOneWidget);
      expect(find.text(l10n.aboutDevice), findsOneWidget);
      expect(find.text('comet'), findsOneWidget);

      // Verify My devices section is displayed with its count badge
      final myDevicesSection = find.byKey(const ValueKey('my_devices'));
      expect(myDevicesSection, findsOneWidget);
      expect(
        find.descendant(
          of: myDevicesSection,
          matching: find.text(l10n.myDevices),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: myDevicesSection, matching: find.text('[01]')),
        findsOneWidget,
      );
      expect(find.text('Paired Phone'), findsOneWidget);

      // Saved (paired) device in My devices has a settings button
      expect(
        find.descendant(
          of: find.widgetWithText(BluetoothDeviceListItem, 'Paired Phone'),
          matching: findMechanixIconButtonByAsset(SettingIcons.setting),
        ),
        findsOneWidget,
      );

      // Verify Other devices section is displayed with its count badge
      final otherDevicesSection = find.byKey(const ValueKey('other_devices'));
      expect(otherDevicesSection, findsOneWidget);
      expect(
        find.descendant(
          of: otherDevicesSection,
          matching: find.text(l10n.otherDevices),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: otherDevicesSection, matching: find.text('[01]')),
        findsOneWidget,
      );
      expect(find.text('Nearby Speaker'), findsOneWidget);

      // Discovered (unsaved) device has no settings button
      expect(
        find.descendant(
          of: find.widgetWithText(BluetoothDeviceListItem, 'Nearby Speaker'),
          matching: findMechanixIconButtonByAsset(SettingIcons.setting),
        ),
        findsNothing,
      );
    });

    testWidgets('Toggling Bluetooth ON and tapping Refresh/Scan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(mockBluetoothRepository));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Go to Bluetooth Screen
      await tester.tap(find.text(l10n.bluetooth));
      await tester.pumpAndSettle();

      // Turn on Bluetooth
      await tester.tap(find.byType(MechanixSwitch));
      await tester.pump();

      bluetoothPowerController.add(true);
      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => true);
      await tester.pumpAndSettle();

      // Refresh button is located in the Other devices expandable tile header
      final refreshBtn = find.descendant(
        of: find.byKey(const ValueKey('other_devices')),
        matching: findMechanixIconButtonByAsset(SettingIcons.refresh),
      );
      expect(refreshBtn, findsOneWidget);

      // Tap refresh
      await tester.tap(refreshBtn);
      await tester.pump();

      // Verify startDiscovery was called
      verify(
        () => mockBluetoothRepository.startDiscovery(),
      ).called(greaterThanOrEqualTo(1));

      // Emit scanning = true
      bluetoothScanningController.add(true);
      await tester.pump();

      // Verify CircularProgressIndicator is shown and refresh button is absent
      final scanningIndicator = find.descendant(
        of: find.byKey(const ValueKey('other_devices')),
        matching: find.byType(CircularProgressIndicator),
      );
      expect(scanningIndicator, findsOneWidget);
      expect(refreshBtn, findsNothing);

      // Emit scanning = false
      bluetoothScanningController.add(false);
      await tester.pump();

      // Verify refresh button reappears
      expect(refreshBtn, findsOneWidget);
      expect(scanningIndicator, findsNothing);
    });

    testWidgets(
      'About device flow (navigation, discoverability toggle, and device rename)',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(mockBluetoothRepository));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(SettingsMenuScreen),
        );
        final l10n = AppLocalizations.of(context)!;

        // Go to Bluetooth Screen
        await tester.tap(find.text(l10n.bluetooth));
        await tester.pumpAndSettle();

        bluetoothPowerController.add(true);
        when(
          () => mockBluetoothRepository.isBluetoothEnabled(),
        ).thenAnswer((_) async => true);
        await tester.pumpAndSettle();

        // Verify About Device tile and button are present
        final aboutDeviceTile = find.text(l10n.aboutDevice);
        expect(aboutDeviceTile, findsOneWidget);

        final aboutDeviceBtn = find.descendant(
          of: find.byType(BluetoothBody),
          matching: find.byKey(const ValueKey("about_device_button")),
        );
        expect(aboutDeviceBtn, findsOneWidget);

        // Tap About Device button to navigate
        await tester.tap(aboutDeviceBtn);
        await tester.pumpAndSettle();

        // Verify we are now on AboutDeviceScreen
        expect(find.byType(AboutDeviceScreen), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AboutDeviceScreen),
            matching: find.text(l10n.aboutDevice),
          ),
          findsOneWidget,
        );

        // Verify Device name, Device type, and Discoverable rows are present
        expect(find.text(l10n.deviceName), findsOneWidget);
        expect(find.text('comet'), findsOneWidget);
        expect(find.text(l10n.deviceType), findsOneWidget);
        expect(find.text(l10n.cometType.toUpperCase()), findsOneWidget);
        expect(find.text(l10n.deviceDiscoverable), findsOneWidget);

        // Verify Discoverable switch state (initially false)
        final discoverableSwitch = find.descendant(
          of: find.byType(AboutDeviceScreen),
          matching: find.byType(MechanixSwitch),
        );
        expect(discoverableSwitch, findsOneWidget);
        expect(
          tester.widget<MechanixSwitch>(discoverableSwitch).value,
          isFalse,
        );

        // Toggle discoverable switch
        await tester.tap(discoverableSwitch);
        await tester.pump();

        verify(() => mockBluetoothRepository.setDiscoverable(true)).called(1);

        bluetoothDiscoverableController.add(true);
        await tester.pumpAndSettle();
        expect(tester.widget<MechanixSwitch>(discoverableSwitch).value, isTrue);

        // Tap the edit (pencil) button on the Device name row to open the
        // edit bottom sheet
        final editButton = find.descendant(
          of: find.byType(AboutDeviceScreen),
          matching: findMechanixIconButtonByAsset(SettingIcons.edit),
        );
        expect(editButton, findsOneWidget);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Verify the bottom sheet is open with title and the current name
        expect(find.text(l10n.editDeviceName), findsOneWidget);
        final textFormFieldFinder = find.byType(TextField);
        expect(textFormFieldFinder, findsOneWidget);
        expect(
          tester.widget<TextField>(textFormFieldFinder).controller?.text,
          'comet',
        );

        // Enter new device name
        await tester.enterText(textFormFieldFinder, 'new-comet');
        await tester.pumpAndSettle();

        // Tap confirm button (SettingIcons.check)
        final checkButton = findMechanixIconButtonByAsset(SettingIcons.check);
        expect(checkButton, findsOneWidget);
        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        // Verify updateLocalDeviceName was called on repo
        verify(
          () => mockBluetoothRepository.updateLocalDeviceName('new-comet'),
        ).called(1);

        // Verify bottom sheet is dismissed and new name is displayed on AboutDeviceScreen
        expect(find.byType(TextField), findsNothing);
        expect(find.text(l10n.editDeviceName), findsNothing);
        expect(find.text('new-comet'), findsOneWidget);

        // Tap back button to return to BluetoothScreen
        final backButton = findMechanixIconButtonByAsset(SettingIcons.back);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verify we are back on BluetoothScreen and new device name is visible
        expect(find.byType(BluetoothScreen), findsOneWidget);
        expect(find.text('new-comet'), findsOneWidget);
      },
    );

    testWidgets(
      'Connect to device interactions from My Devices and Other Devices',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(mockBluetoothRepository));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(SettingsMenuScreen),
        );
        final l10n = AppLocalizations.of(context)!;

        // Go to Bluetooth Screen
        await tester.tap(find.text(l10n.bluetooth));
        await tester.pumpAndSettle();

        // Turn on Bluetooth
        await tester.tap(find.byType(MechanixSwitch));
        await tester.pump();

        bluetoothPowerController.add(true);
        when(
          () => mockBluetoothRepository.isBluetoothEnabled(),
        ).thenAnswer((_) async => true);

        const pairedDevice = BluetoothDevice(
          name: 'Paired Phone',
          deviceName: 'Paired Phone',
          type: BluetoothDeviceType.mobile,
          macAddress: '22:22:22:22:22:22',
          isSaved: true,
          isConnected: false,
        );
        const discoveredDevice = BluetoothDevice(
          name: 'Nearby Speaker',
          deviceName: 'Nearby Speaker',
          type: BluetoothDeviceType.speaker,
          macAddress: '33:33:33:33:33:33',
          isSaved: false,
          isConnected: false,
        );

        const connectedDevice = BluetoothDevice(
          name: 'Connected Audio',
          deviceName: 'Connected Audio',
          type: BluetoothDeviceType.headphones,
          macAddress: '11:11:11:11:11:11',
          isSaved: true,
          isConnected: true,
        );

        bluetoothDevicesController.add([
          connectedDevice,
          pairedDevice,
          discoveredDevice,
        ]);
        await tester.pumpAndSettle();

        // Tapping the connected device tile itself does nothing
        await tester.tap(find.text('Connected Audio'));
        await tester.pump();
        verifyNever(
          () => mockBluetoothRepository.connectToDevice('11:11:11:11:11:11'),
        );
        verifyNever(
          () =>
              mockBluetoothRepository.disconnectFromDevice('11:11:11:11:11:11'),
        );

        // Connect to saved device in My Devices: calls connectToDevice directly
        await tester.tap(find.text('Paired Phone'));
        await tester.pump();

        verify(
          () => mockBluetoothRepository.connectToDevice('22:22:22:22:22:22'),
        ).called(1);
        verifyNever(
          () => mockBluetoothRepository.pairDevice('22:22:22:22:22:22'),
        );

        // Connect to unsaved device in Other Devices: calls pairDevice then connectToDevice
        await tester.tap(find.text('Nearby Speaker'));
        await tester.pump();

        verify(
          () => mockBluetoothRepository.pairDevice('33:33:33:33:33:33'),
        ).called(1);
        verify(
          () => mockBluetoothRepository.connectToDevice('33:33:33:33:33:33'),
        ).called(1);
      },
    );

    testWidgets(
      'Device Detail interactions (Disconnect, Connect, and Forget via app bar actions)',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(mockBluetoothRepository));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(SettingsMenuScreen),
        );
        final l10n = AppLocalizations.of(context)!;

        // Go to Bluetooth Screen
        await tester.tap(find.text(l10n.bluetooth));
        await tester.pumpAndSettle();

        // Enable Bluetooth
        await tester.tap(find.byType(MechanixSwitch));
        await tester.pump();

        bluetoothPowerController.add(true);
        when(
          () => mockBluetoothRepository.isBluetoothEnabled(),
        ).thenAnswer((_) async => true);

        // Emit connected device and paired disconnected device
        const connectedDevice = BluetoothDevice(
          name: 'Connected Audio',
          deviceName: 'Connected Audio',
          type: BluetoothDeviceType.headphones,
          macAddress: '11:11:11:11:11:11',
          isSaved: true,
          isConnected: true,
        );
        const pairedDevice = BluetoothDevice(
          name: 'Paired Phone',
          deviceName: 'Paired Phone',
          type: BluetoothDeviceType.mobile,
          macAddress: '22:22:22:22:22:22',
          isSaved: true,
          isConnected: false,
        );

        bluetoothDevicesController.add([connectedDevice, pairedDevice]);
        await tester.pumpAndSettle();

        Finder inDetailScreen(Finder matching) => find.descendant(
          of: find.byType(BluetoothDeviceDetailScreen),
          matching: matching,
        );

        Future<void> openDetailsForPairedPhone() async {
          final pairedSettingsBtn = find.descendant(
            of: find.widgetWithText(BluetoothDeviceListItem, 'Paired Phone'),
            matching: findMechanixIconButtonByAsset(SettingIcons.setting),
          );
          expect(pairedSettingsBtn, findsOneWidget);
          await tester.tap(pairedSettingsBtn);
          await tester.pumpAndSettle();
          expect(find.byType(BluetoothDeviceDetailScreen), findsOneWidget);
        }

        // ---- Connected device details -> Disconnect ----

        // Tap settings button on Connected Audio
        final connectedSettingsBtn = find.descendant(
          of: find.byType(BluetoothConnectedDeviceTile),
          matching: findMechanixIconButtonByAsset(SettingIcons.setting),
        );
        expect(connectedSettingsBtn, findsOneWidget);
        await tester.tap(connectedSettingsBtn);
        await tester.pumpAndSettle();

        // Verify on BluetoothDeviceDetailScreen
        expect(find.byType(BluetoothDeviceDetailScreen), findsOneWidget);

        // Title shows the device name as-is (not uppercased)
        expect(inDetailScreen(find.text('Connected Audio')), findsOneWidget);

        // Device type row
        expect(inDetailScreen(find.text(l10n.deviceType)), findsOneWidget);
        expect(
          inDetailScreen(find.text(l10n.headphones.toUpperCase())),
          findsOneWidget,
        );

        // Status row shows "Connected" with the green ellipse indicator
        expect(inDetailScreen(find.text(l10n.deviceStatus)), findsOneWidget);
        expect(inDetailScreen(find.text(l10n.connected)), findsOneWidget);
        expect(
          inDetailScreen(
            find.byWidgetPredicate(
              (widget) =>
                  widget is ImageIcon &&
                  widget.image is AssetImage &&
                  (widget.image as AssetImage).assetName ==
                      SettingIcons.ellipse,
            ),
          ),
          findsOneWidget,
        );

        // App bar actions: Disconnect + Delete (no 3-dots popup menu anymore)
        expect(
          inDetailScreen(findMechanixIconButtonByAsset(SettingIcons.moreVert)),
          findsNothing,
        );
        expect(
          inDetailScreen(findMechanixIconButtonByAsset(SettingIcons.bluetooth)),
          findsNothing,
        );
        expect(
          inDetailScreen(findMechanixIconButtonByAsset(SettingIcons.delete)),
          findsOneWidget,
        );
        final disconnectBtn = inDetailScreen(
          findMechanixIconButtonByAsset(SettingIcons.disconnect),
        );
        expect(disconnectBtn, findsOneWidget);

        // Tap Disconnect
        await tester.tap(disconnectBtn);
        await tester.pumpAndSettle();

        // Verify disconnect was called and navigated back
        verify(
          () =>
              mockBluetoothRepository.disconnectFromDevice('11:11:11:11:11:11'),
        ).called(1);
        expect(find.byType(BluetoothDeviceDetailScreen), findsNothing);
        expect(find.byType(BluetoothScreen), findsOneWidget);

        // ---- Paired (disconnected) device details -> Connect ----

        await openDetailsForPairedPhone();

        expect(inDetailScreen(find.text('Paired Phone')), findsOneWidget);
        expect(
          inDetailScreen(find.text(l10n.mobileType.toUpperCase())),
          findsOneWidget,
        );
        expect(inDetailScreen(find.text(l10n.disonnected)), findsOneWidget);

        // Disconnected device shows Connect (bluetooth icon) instead of Disconnect
        expect(
          inDetailScreen(
            findMechanixIconButtonByAsset(SettingIcons.disconnect),
          ),
          findsNothing,
        );
        final connectBtn = inDetailScreen(
          findMechanixIconButtonByAsset(SettingIcons.bluetooth),
        );
        expect(connectBtn, findsOneWidget);
        expect(
          inDetailScreen(findMechanixIconButtonByAsset(SettingIcons.delete)),
          findsOneWidget,
        );

        // Tap Connect
        await tester.tap(connectBtn);
        // The device stays in "connecting" state (spinner) until BlueZ
        // reports it as connected, so pumpAndSettle would never settle here.
        // Pump just long enough for the pop transition to finish.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Saved device: connects directly without pairing, then navigates back
        verify(
          () => mockBluetoothRepository.connectToDevice('22:22:22:22:22:22'),
        ).called(1);
        verifyNever(
          () => mockBluetoothRepository.pairDevice('22:22:22:22:22:22'),
        );
        expect(find.byType(BluetoothDeviceDetailScreen), findsNothing);
        expect(find.byType(BluetoothScreen), findsOneWidget);

        // Loader is shown on Paired Phone while connecting
        expect(
          find.descendant(
            of: find.widgetWithText(BluetoothDeviceListItem, 'Paired Phone'),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );

        // Simulate BlueZ reporting Paired Phone as connected
        bluetoothDevicesController.add([
          connectedDevice,
          pairedDevice.copyWith(isConnected: true),
        ]);
        await tester.pumpAndSettle();

        // Paired Phone moves to the connected tiles and loader is gone
        expect(find.byType(BluetoothConnectedDeviceTile), findsNWidgets(2));
        expect(
          find.widgetWithText(BluetoothConnectedDeviceTile, 'Paired Phone'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(BluetoothDeviceListItem, 'Paired Phone'),
          findsNothing,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        final phoneSettingsBtn = find.descendant(
          of: find.widgetWithText(BluetoothConnectedDeviceTile, 'Paired Phone'),
          matching: findMechanixIconButtonByAsset(SettingIcons.setting),
        );
        expect(phoneSettingsBtn, findsOneWidget);
        await tester.tap(phoneSettingsBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BluetoothDeviceDetailScreen), findsOneWidget);
        expect(inDetailScreen(find.text('Paired Phone')), findsOneWidget);
        expect(inDetailScreen(find.text(l10n.connected)), findsOneWidget);

        final deleteBtn = inDetailScreen(
          findMechanixIconButtonByAsset(SettingIcons.delete),
        );
        expect(deleteBtn, findsOneWidget);
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();

        // Verify forgetDevice was called and navigated back
        verify(
          () => mockBluetoothRepository.forgetDevice('22:22:22:22:22:22'),
        ).called(1);
        expect(find.byType(BluetoothDeviceDetailScreen), findsNothing);
        expect(find.byType(BluetoothScreen), findsOneWidget);
      },
    );

    testWidgets('Error notification display on connection or pairing failure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(mockBluetoothRepository));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Go to Bluetooth Screen
      await tester.tap(find.text(l10n.bluetooth));
      await tester.pumpAndSettle();

      // Turn on Bluetooth
      await tester.tap(find.byType(MechanixSwitch));
      await tester.pump();

      bluetoothPowerController.add(true);
      when(
        () => mockBluetoothRepository.isBluetoothEnabled(),
      ).thenAnswer((_) async => true);

      const discoveredDevice = BluetoothDevice(
        name: 'Failing Device',
        deviceName: 'Failing Device',
        type: BluetoothDeviceType.unknown,
        macAddress: '44:44:44:44:44:44',
        isSaved: false,
        isConnected: false,
      );

      bluetoothDevicesController.add([discoveredDevice]);
      await tester.pumpAndSettle();

      // Make pairDevice throw an exception
      when(
        () => mockBluetoothRepository.pairDevice('44:44:44:44:44:44'),
      ).thenThrow(Exception('Pairing timed out'));

      // Tap to connect
      await tester.tap(find.text('Failing Device'));
      await tester.pumpAndSettle();

      // Verify MechanixSnackbar error message is displayed
      expect(
        find.text(l10n.bluetoothPairingFailedWithName('Failing Device')),
        findsOneWidget,
      );
    });
  });
}
