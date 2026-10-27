import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth_device_detail.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import '../helpers/bluetooth_test_helpers.dart';

Finder findIconButton(String assetPath) => find.byWidgetPredicate(
  (widget) =>
      widget is MechanixIconButton &&
      widget.icon is ImageIcon &&
      (widget.icon as ImageIcon).image is AssetImage &&
      ((widget.icon as ImageIcon).image as AssetImage).assetName == assetPath,
);

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
          child: BluetoothDeviceDetailScreen(
            macAddress: tConnectedDevice.macAddress,
            title: tConnectedDevice.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BluetoothDeviceDetailScreen));
      final l10n = AppLocalizations.of(context)!;

      // Title shows the device name as-is
      expect(find.text(tConnectedDevice.name), findsOneWidget);

      // Device Type and localized text
      expect(find.text(l10n.deviceType), findsOneWidget);
      expect(find.text(l10n.headphones.toUpperCase()), findsOneWidget);

      // Device Status and localized connected text
      expect(find.text(l10n.deviceStatus), findsOneWidget);
      expect(find.text(l10n.connected), findsOneWidget);

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
          child: BluetoothDeviceDetailScreen(
            macAddress: tPairedDevice.macAddress,
            title: tPairedDevice.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(BluetoothDeviceDetailScreen));
      final l10n = AppLocalizations.of(context)!;

      expect(find.text(tPairedDevice.name), findsOneWidget);
      expect(find.text(l10n.mobileType.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.disonnected), findsOneWidget);

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
          child: BluetoothDeviceDetailScreen(
            macAddress: tConnectedDevice.macAddress,
            title: tConnectedDevice.name,
          ),
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

    testWidgets('connected device shows Disconnect and Delete actions only', (
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
          child: BluetoothDeviceDetailScreen(
            macAddress: tConnectedDevice.macAddress,
            title: tConnectedDevice.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findIconButton(SettingIcons.disconnect), findsOneWidget);
      expect(findIconButton(SettingIcons.delete), findsOneWidget);
      expect(findIconButton(SettingIcons.bluetooth), findsNothing);
      expect(findIconButton(SettingIcons.moreVert), findsNothing);
    });

    testWidgets('disconnected device shows Connect and Delete actions only', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(isBluetoothOn: true, pairedDevices: [tPairedDevice]),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: BluetoothDeviceDetailScreen(
            macAddress: tPairedDevice.macAddress,
            title: tPairedDevice.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findIconButton(SettingIcons.bluetooth), findsOneWidget);
      expect(findIconButton(SettingIcons.delete), findsOneWidget);
      expect(findIconButton(SettingIcons.disconnect), findsNothing);
      expect(findIconButton(SettingIcons.moreVert), findsNothing);
    });

    testWidgets(
      'disconnect action dispatches DisconnectFromDeviceEvent and pops',
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
              macAddress: tConnectedDevice.macAddress,
              title: tConnectedDevice.name,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(findIconButton(SettingIcons.disconnect));
        await tester.pumpAndSettle();

        verify(
          () => mockBluetoothBloc.add(
            const DisconnectFromDeviceEvent(tConnectedDevice),
          ),
        ).called(1);
        verify(() => navigatorObserver.didPop(any(), any())).called(1);
      },
    );

    testWidgets('connect action dispatches ConnectToDeviceEvent and pops', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(isBluetoothOn: true, pairedDevices: [tPairedDevice]),
      );

      final navigatorObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          navigatorObserver: navigatorObserver,
          child: BluetoothDeviceDetailScreen(
            macAddress: tPairedDevice.macAddress,
            title: tPairedDevice.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(findIconButton(SettingIcons.bluetooth));
      await tester.pumpAndSettle();

      verify(
        () => mockBluetoothBloc.add(const ConnectToDeviceEvent(tPairedDevice)),
      ).called(1);
      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });

    testWidgets('delete action dispatches ForgetDeviceEvent and pops', (
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
          child: BluetoothDeviceDetailScreen(
            macAddress: tConnectedDevice.macAddress,
            title: tConnectedDevice.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(findIconButton(SettingIcons.delete));
      await tester.pumpAndSettle();

      verify(
        () => mockBluetoothBloc.add(const ForgetDeviceEvent(tConnectedDevice)),
      ).called(1);
      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });
  });
}
