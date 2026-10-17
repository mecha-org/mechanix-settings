import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import '../helpers/bluetooth_test_helpers.dart';

void main() {
  late MockBluetoothBloc mockBluetoothBloc;

  setUpAll(() {
    registerBluetoothFallbackValues();
  });

  setUp(() {
    mockBluetoothBloc = MockBluetoothBloc();
  });

  group('BluetoothDeviceDetailScreen Widget Tests', () {
    testWidgets('renders device details for connected headphones', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          pairedDevices: [tConnectedDevice],
        ),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: BluetoothDeviceDetailScreen(deviceName: tConnectedDevice.name),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BluetoothDeviceDetailScreen));
      final l10n = AppLocalizations.of(context)!;

      // Title in uppercase
      expect(find.text(tConnectedDevice.name.toUpperCase()), findsOneWidget);

      // Device Type and localized text
      expect(find.text(l10n.deviceType), findsOneWidget);
      expect(find.text(l10n.headphones.toUpperCase()), findsOneWidget);

      // Device Status and localized connected text
      expect(find.text(l10n.deviceStatus), findsOneWidget);
      expect(find.text(l10n.connected.toUpperCase()), findsOneWidget);

      // Connected green ellipse indicator
      final ellipseFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ImageIcon &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == SettingIcons.ellipse,
      );
      expect(ellipseFinder, findsOneWidget);
    });

    testWidgets('renders device details for disconnected phone', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          pairedDevices: [tPairedDevice],
        ),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: BluetoothDeviceDetailScreen(deviceName: tPairedDevice.name),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BluetoothDeviceDetailScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(tPairedDevice.name.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.mobileType.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.notConnected.toUpperCase()), findsOneWidget);

      // No connected ellipse indicator
      final ellipseFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ImageIcon &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == SettingIcons.ellipse,
      );
      expect(ellipseFinder, findsNothing);
    });

    testWidgets('tapping back button pops the screen', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          pairedDevices: [tConnectedDevice],
        ),
      );

      final navigatorObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          navigatorObserver: navigatorObserver,
          child: BluetoothDeviceDetailScreen(deviceName: tConnectedDevice.name),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is ImageIcon &&
            ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                SettingIcons.back,
      );

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });

    testWidgets(
      'menu disconnect action dispatches DisconnectFromDeviceEvent and pops',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            pairedDevices: [tConnectedDevice],
          ),
        );

        final navigatorObserver = MockNavigatorObserver();

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            navigatorObserver: navigatorObserver,
            child: BluetoothDeviceDetailScreen(
              deviceName: tConnectedDevice.name,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(
          find.byType(BluetoothDeviceDetailScreen),
        );
        final l10n = AppLocalizations.of(context)!;

        // Open menu
        final menuButton = find.byWidgetPredicate(
          (widget) =>
              widget is MechanixIconButton &&
              widget.icon is ImageIcon &&
              ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                  SettingIcons.moreVert,
        );
        expect(menuButton, findsOneWidget);

        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Find and tap Disconnect
        final disconnectFinder = find.text(l10n.disconnect);
        expect(disconnectFinder, findsOneWidget);

        await tester.tap(disconnectFinder);
        await tester.pumpAndSettle();

        verify(
          () => mockBluetoothBloc.add(
            const DisconnectFromDeviceEvent(tConnectedDevice),
          ),
        ).called(1);
        verify(() => navigatorObserver.didPop(any(), any())).called(1);
      },
    );

    testWidgets(
      'menu connect action dispatches ConnectToDeviceEvent and pops',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            pairedDevices: [tPairedDevice],
          ),
        );

        final navigatorObserver = MockNavigatorObserver();

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            navigatorObserver: navigatorObserver,
            child: BluetoothDeviceDetailScreen(deviceName: tPairedDevice.name),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(
          find.byType(BluetoothDeviceDetailScreen),
        );
        final l10n = AppLocalizations.of(context)!;

        // Open menu
        final menuButton = find.byWidgetPredicate(
          (widget) =>
              widget is MechanixIconButton &&
              widget.icon is ImageIcon &&
              ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                  SettingIcons.moreVert,
        );

        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Find and tap Connect
        final connectFinder = find.text(l10n.connect);
        expect(connectFinder, findsOneWidget);

        await tester.tap(connectFinder);
        await tester.pumpAndSettle();

        verify(
          () =>
              mockBluetoothBloc.add(const ConnectToDeviceEvent(tPairedDevice)),
        ).called(1);
        verify(() => navigatorObserver.didPop(any(), any())).called(1);
      },
    );

    testWidgets('menu forget action dispatches ForgetDeviceEvent and pops', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          pairedDevices: [tConnectedDevice],
        ),
      );

      final navigatorObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          navigatorObserver: navigatorObserver,
          child: BluetoothDeviceDetailScreen(deviceName: tConnectedDevice.name),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BluetoothDeviceDetailScreen));
      final l10n = AppLocalizations.of(context)!;

      // Open menu
      final menuButton = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is ImageIcon &&
            ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                SettingIcons.moreVert,
      );

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap Forget Device
      final forgetFinder = find.text(l10n.forgetDevice);
      expect(forgetFinder, findsOneWidget);

      await tester.tap(forgetFinder);
      await tester.pumpAndSettle();

      verify(
        () => mockBluetoothBloc.add(const ForgetDeviceEvent(tConnectedDevice)),
      ).called(1);
      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });

    testWidgets(
      'falls back to default unknown device if device is not in list',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            pairedDevices: [],
            discoveredDevices: [],
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const BluetoothDeviceDetailScreen(
              deviceName: 'Unknown Device',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(
          find.byType(BluetoothDeviceDetailScreen),
        );
        final l10n = AppLocalizations.of(context)!;

        expect(find.text('UNKNOWN DEVICE'), findsOneWidget);
        expect(find.text(l10n.unknownType.toUpperCase()), findsOneWidget);
        expect(find.text(l10n.notConnected.toUpperCase()), findsOneWidget);
      },
    );
  });
}
