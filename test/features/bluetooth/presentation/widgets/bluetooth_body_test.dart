import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/about_device_screen.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth/bluetooth_body.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_connected_device_tile.dart';
import '../helpers/bluetooth_test_helpers.dart';

void main() {
  late MockBluetoothBloc mockBluetoothBloc;

  setUpAll(() {
    registerBluetoothFallbackValues();
  });

  setUp(() {
    mockBluetoothBloc = MockBluetoothBloc();
  });

  group('BluetoothBody Widget Tests', () {
    testWidgets('renders bluetooth switch in OFF state and toggles to ON', (
      WidgetTester tester,
    ) async {
      when(
        () => mockBluetoothBloc.state,
      ).thenReturn(const BluetoothState(isBluetoothOn: false));

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const Scaffold(body: BluetoothBody()),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(MechanixSwitch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pump();

      verify(
        () => mockBluetoothBloc.add(const ToggleBluetoothPower(true)),
      ).called(1);
    });

    testWidgets('renders bluetooth switch in ON state and toggles to OFF', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(isBluetoothOn: true, localDeviceName: 'My Comet'),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const Scaffold(body: BluetoothBody()),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(MechanixSwitch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pump();

      verify(
        () => mockBluetoothBloc.add(const ToggleBluetoothPower(false)),
      ).called(1);
    });

    testWidgets('hides all device sections when Bluetooth is OFF', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: false,
          pairedDevices: [tConnectedDevice, tPairedDevice],
          discoveredDevices: [tDiscoveredDevice],
        ),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const Scaffold(body: BluetoothBody()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('about_device_tile')), findsNothing);
      expect(find.byType(BluetoothConnectedDeviceTile), findsNothing);
      expect(find.byKey(const ValueKey('my_devices')), findsNothing);
      expect(find.byKey(const ValueKey('other_devices')), findsNothing);
    });

    testWidgets(
      'shows About Device tile when Bluetooth is ON and navigates on tap',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            localDeviceName: 'Comet Device',
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const Scaffold(body: BluetoothBody()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('about_device_tile')), findsOneWidget);
        expect(find.text('Comet Device'), findsOneWidget);

        // Tap About Device tile to navigate
        await tester.tap(find.byKey(const ValueKey('about_device_tile')));
        await tester.pumpAndSettle();

        expect(find.byType(AboutDeviceScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping about device arrow button navigates to AboutDeviceScreen',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            localDeviceName: 'Comet Device',
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const Scaffold(body: BluetoothBody()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('about_device_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AboutDeviceScreen), findsOneWidget);
      },
    );

    testWidgets('displays connected devices list and navigates to details', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          localDeviceName: 'Comet Device',
          pairedDevices: [tConnectedDevice],
        ),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const Scaffold(body: BluetoothBody()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BluetoothConnectedDeviceTile), findsOneWidget);
      expect(find.text(tConnectedDevice.name), findsOneWidget);

      // Tap settings button on the connected device tile
      final settingsButton = find.descendant(
        of: find.byType(BluetoothConnectedDeviceTile),
        matching: find.byType(MechanixIconButton),
      );
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.byType(BluetoothDeviceDetailScreen), findsOneWidget);
    });

    testWidgets(
      'displays My Devices section, taps device to connect and settings to navigate',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            localDeviceName: 'Comet Device',
            pairedDevices: [tPairedDevice],
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const Scaffold(body: BluetoothBody()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('my_devices')), findsOneWidget);
        expect(find.text('[01]'), findsOneWidget);
        expect(find.text(tPairedDevice.name), findsOneWidget);

        // Tap device to connect
        await tester.tap(find.text(tPairedDevice.name));
        await tester.pump();

        verify(
          () =>
              mockBluetoothBloc.add(const ConnectToDeviceEvent(tPairedDevice)),
        ).called(1);

        // Tap settings button to navigate to detail screen
        final myDevicesFinder = find.byKey(const ValueKey('my_devices'));
        final settingsButton = find.descendant(
          of: myDevicesFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is MechanixIconButton &&
                widget.icon is ImageIcon &&
                ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                    SettingIcons.setting,
          ),
        );
        expect(settingsButton, findsOneWidget);

        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        expect(find.byType(BluetoothDeviceDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      'displays Other Devices with scanning indicator when isScanning is true',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            localDeviceName: 'Comet Device',
            isScanning: true,
            discoveredDevices: [tDiscoveredDevice],
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const Scaffold(body: BluetoothBody()),
          ),
        );
        await tester.pump();

        final otherDevicesFinder = find.byKey(const ValueKey('other_devices'));
        expect(otherDevicesFinder, findsOneWidget);

        // Should show progress indicator when scanning
        final progressFinder = find.descendant(
          of: otherDevicesFinder,
          matching: find.byType(CircularProgressIndicator),
        );
        expect(progressFinder, findsOneWidget);

        // Refresh icon button should not be present
        final refreshButton = find.descendant(
          of: otherDevicesFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is MechanixIconButton &&
                widget.icon is ImageIcon &&
                ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                    SettingIcons.refresh,
          ),
        );
        expect(refreshButton, findsNothing);
      },
    );

    testWidgets(
      'displays Other Devices with refresh button when isScanning is false, dispatches scan',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            localDeviceName: 'Comet Device',
            isScanning: false,
            discoveredDevices: [tDiscoveredDevice],
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const Scaffold(body: BluetoothBody()),
          ),
        );
        await tester.pumpAndSettle();

        final otherDevicesFinder = find.byKey(const ValueKey('other_devices'));
        expect(otherDevicesFinder, findsOneWidget);

        // Progress indicator should not be present
        final progressFinder = find.descendant(
          of: otherDevicesFinder,
          matching: find.byType(CircularProgressIndicator),
        );
        expect(progressFinder, findsNothing);

        // Refresh icon button should be present
        final refreshButton = find.descendant(
          of: otherDevicesFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is MechanixIconButton &&
                widget.icon is ImageIcon &&
                ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                    SettingIcons.refresh,
          ),
        );
        expect(refreshButton, findsOneWidget);

        await tester.tap(refreshButton);
        await tester.pump();

        verify(
          () => mockBluetoothBloc.add(const ScanBluetoothDevices()),
        ).called(1);
      },
    );

    testWidgets('tapping discovered device dispatches ConnectToDeviceEvent', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          localDeviceName: 'Comet Device',
          discoveredDevices: [tDiscoveredDevice],
        ),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const Scaffold(body: BluetoothBody()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tDiscoveredDevice.name), findsOneWidget);

      await tester.tap(find.text(tDiscoveredDevice.name));
      await tester.pump();

      verify(
        () => mockBluetoothBloc.add(
          const ConnectToDeviceEvent(tDiscoveredDevice),
        ),
      ).called(1);
    });
  });
}
