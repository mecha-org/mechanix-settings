import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/add_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/manage_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless/wireless_body.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_password.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

class MockWirelessBloc extends MockBloc<WirelessEvent, WirelessState>
    implements WirelessBloc {}

Widget createWirelessTestWidget({
  required Widget child,
  required WirelessBloc wirelessBloc,
  NavigatorObserver? navigatorObserver,
  ThemeData? theme,
}) {
  return MechanixTheme(
    builder: (context, mechanixTheme, _) {
      return MaterialApp(
        theme: theme ?? mechanixTheme.dark,
        navigatorObservers: [if (navigatorObserver != null) navigatorObserver],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, navigatorChild) {
          return BlocProvider<WirelessBloc>.value(
            value: wirelessBloc,
            child: navigatorChild!,
          );
        },
        home: child,
      );
    },
  );
}

void main() {
  late MockWirelessBloc mockWirelessBloc;

  const tConnectedNetwork = WifiNetwork(
    name: 'OfficeWifi 1',
    isConnected: true,
    signalLevel: 3,
    security: WirelessSecurity.wpaWpa2Personal,
  );

  const tMyNetwork = WifiNetwork(
    name: 'OfficeWifi 2',
    isConnected: false,
    signalLevel: 2,
    security: WirelessSecurity.wpaWpa2Personal,
  );

  const tAvailableNetwork1 = WifiNetwork(
    name: 'OfficeWifi 3',
    isConnected: false,
    signalLevel: 2,
    security: WirelessSecurity.wpaWpa2Personal,
  );

  const tAvailableNetwork2 = WifiNetwork(
    name: 'OfficeWifi 4',
    isConnected: false,
    signalLevel: 1,
    security: WirelessSecurity.none,
  );

  setUp(() {
    mockWirelessBloc = MockWirelessBloc();
  });

  group('WirelessBody Widget Tests', () {
    testWidgets('renders Wi-Fi switch in OFF state and toggles to ON', (
      WidgetTester tester,
    ) async {
      when(
        () => mockWirelessBloc.state,
      ).thenReturn(const WirelessState(isWirelessOn: false));

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const Scaffold(body: WirelessBody()),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(MechanixSwitch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pump();

      verify(
        () => mockWirelessBloc.add(const ToggleWirelessPower(true)),
      ).called(1);
    });

    testWidgets('renders Wi-Fi switch in ON state and toggles to OFF', (
      WidgetTester tester,
    ) async {
      when(
        () => mockWirelessBloc.state,
      ).thenReturn(const WirelessState(isWirelessOn: true));

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const Scaffold(body: WirelessBody()),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(MechanixSwitch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pump();

      verify(
        () => mockWirelessBloc.add(const ToggleWirelessPower(false)),
      ).called(1);
    });

    testWidgets('hides network sections when Wi-Fi is OFF', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessBloc.state).thenReturn(
        const WirelessState(
          isWirelessOn: false,
          myNetworks: [tConnectedNetwork, tMyNetwork],
          availableNetworks: [tAvailableNetwork1],
          connectedNetworkName: 'OfficeWifi 1',
        ),
      );

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const Scaffold(body: WirelessBody()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('connected_OfficeWifi 1')), findsNothing);
      expect(find.byKey(const ValueKey('my_networks')), findsNothing);
      expect(find.byKey(const ValueKey('available_networks')), findsNothing);
      expect(find.byKey(const ValueKey('join_network_tile')), findsNothing);
      expect(find.byKey(const ValueKey('manage_network_tile')), findsNothing);
    });

    testWidgets('displays connected network and navigates to details on gear tap', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessBloc.state).thenReturn(
        const WirelessState(
          isWirelessOn: true,
          connectedNetworkName: 'OfficeWifi 1',
          myNetworks: [tConnectedNetwork, tMyNetwork],
          savedNetworks: [tConnectedNetwork, tMyNetwork],
        ),
      );

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const Scaffold(body: WirelessBody()),
        ),
      );
      await tester.pumpAndSettle();

      final connectedTileFinder = find.byKey(
        const ValueKey('connected_OfficeWifi 1'),
      );
      expect(connectedTileFinder, findsOneWidget);
      expect(find.text('OfficeWifi 1'), findsOneWidget);

      final settingsButton = find.descendant(
        of: connectedTileFinder,
        matching: find.byType(MechanixIconButton),
      );
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.byType(NetworkDetailScreen), findsOneWidget);
    });

    testWidgets(
      'displays My networks expandable list with count [01], connects on tap and navigates on gear',
      (WidgetTester tester) async {
        when(() => mockWirelessBloc.state).thenReturn(
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            myNetworks: [tConnectedNetwork, tMyNetwork],
            savedNetworks: [tConnectedNetwork, tMyNetwork],
          ),
        );

        await tester.pumpWidget(
          createWirelessTestWidget(
            wirelessBloc: mockWirelessBloc,
            child: const Scaffold(body: WirelessBody()),
          ),
        );
        await tester.pumpAndSettle();

        final myNetworksFinder = find.byKey(const ValueKey('my_networks'));
        expect(myNetworksFinder, findsOneWidget);
        expect(find.text('[01]'), findsOneWidget);
        expect(find.text('OfficeWifi 2'), findsOneWidget);

        // Tap network to connect
        await tester.tap(find.text('OfficeWifi 2'));
        await tester.pump();

        verify(
          () => mockWirelessBloc.add(
            const ConnectToNetworkEvent('OfficeWifi 2', null),
          ),
        ).called(1);

        // Tap settings button on My networks item
        final settingsButton = find.descendant(
          of: myNetworksFinder,
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

        expect(find.byType(NetworkDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      'displays Available networks expandable list with count [02] and no gear icons',
      (WidgetTester tester) async {
        when(() => mockWirelessBloc.state).thenReturn(
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            myNetworks: [tConnectedNetwork],
            availableNetworks: [tAvailableNetwork1, tAvailableNetwork2],
          ),
        );

        await tester.pumpWidget(
          createWirelessTestWidget(
            wirelessBloc: mockWirelessBloc,
            child: const Scaffold(body: WirelessBody()),
          ),
        );
        await tester.pumpAndSettle();

        final availFinder = find.byKey(const ValueKey('available_networks'));
        expect(availFinder, findsOneWidget);
        expect(find.text('[02]'), findsOneWidget);
        expect(find.text('OfficeWifi 3'), findsOneWidget);
        expect(find.text('OfficeWifi 4'), findsOneWidget);

        // Verify available networks do NOT have gear icon
        final gearInAvailable = find.descendant(
          of: availFinder,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is MechanixIconButton &&
                widget.icon is ImageIcon &&
                ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                    SettingIcons.setting,
          ),
        );
        expect(gearInAvailable, findsNothing);

        // Tap open network to connect directly
        await tester.tap(find.text('OfficeWifi 4'));
        await tester.pump();

        verify(
          () => mockWirelessBloc.add(
            const ConnectToNetworkEvent('OfficeWifi 4', null),
          ),
        ).called(1);
      },
    );

    testWidgets('shows CircularProgressIndicator when isScanning is true', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessBloc.state).thenReturn(
        const WirelessState(
          isWirelessOn: true,
          isScanning: true,
          availableNetworks: [tAvailableNetwork1],
        ),
      );

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const Scaffold(body: WirelessBody()),
        ),
      );
      await tester.pump();

      final availFinder = find.byKey(const ValueKey('available_networks'));
      expect(availFinder, findsOneWidget);

      final progressFinder = find.descendant(
        of: availFinder,
        matching: find.byType(CircularProgressIndicator),
      );
      expect(progressFinder, findsOneWidget);
    });

    testWidgets('taps Join Network tile to navigate to AddNetworkPage', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessBloc.state).thenReturn(
        const WirelessState(isWirelessOn: true),
      );

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const Scaffold(body: WirelessBody()),
        ),
      );
      await tester.pumpAndSettle();

      final joinTileFinder = find.byKey(const ValueKey('join_network_tile'));
      expect(joinTileFinder, findsOneWidget);
      expect(find.text('Join Network'), findsOneWidget);

      await tester.tap(joinTileFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AddNetworkPage), findsOneWidget);
    });

    testWidgets('taps Manage networks tile to navigate to ManageNetworksScreen', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessBloc.state).thenReturn(
        const WirelessState(isWirelessOn: true),
      );

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const Scaffold(body: WirelessBody()),
        ),
      );
      await tester.pumpAndSettle();

      final manageTileFinder = find.byKey(
        const ValueKey('manage_network_tile'),
      );
      expect(manageTileFinder, findsOneWidget);
      expect(find.text('Manage Networks'), findsOneWidget);

      await tester.tap(manageTileFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ManageNetworksScreen), findsOneWidget);
    });

    testWidgets(
      'tapping secured available network opens password bottom sheet and connects with entered password',
      (WidgetTester tester) async {
        when(() => mockWirelessBloc.state).thenReturn(
          const WirelessState(
            isWirelessOn: true,
            availableNetworks: [tAvailableNetwork1],
          ),
        );

        await tester.pumpWidget(
          createWirelessTestWidget(
            wirelessBloc: mockWirelessBloc,
            child: const Scaffold(body: WirelessBody()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap secured network (OfficeWifi 3)
        await tester.tap(find.text('OfficeWifi 3'));
        await tester.pumpAndSettle();

        // Verify password bottom sheet is open
        expect(find.byType(WirelessPasswordBottomSheet), findsOneWidget);

        // Enter password
        final textField = find.byType(MechanixTextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'secretpass123');
        await tester.pump();

        // Tap check icon button to connect
        final checkButton = find.descendant(
          of: find.byType(WirelessPasswordBottomSheet),
          matching: find.byWidgetPredicate(
            (w) =>
                w is MechanixIconButton &&
                w.icon is ImageIcon &&
                ((w.icon as ImageIcon).image as AssetImage).assetName ==
                    SettingIcons.check,
          ),
        );
        expect(checkButton, findsOneWidget);
        await tester.tap(checkButton);
        await tester.pumpAndSettle();

        // Verify connect event was added with the entered password
        verify(
          () => mockWirelessBloc.add(
            const ConnectToNetworkEvent('OfficeWifi 3', 'secretpass123'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping secured available network and canceling password sheet does not connect',
      (WidgetTester tester) async {
        when(() => mockWirelessBloc.state).thenReturn(
          const WirelessState(
            isWirelessOn: true,
            availableNetworks: [tAvailableNetwork1],
          ),
        );

        await tester.pumpWidget(
          createWirelessTestWidget(
            wirelessBloc: mockWirelessBloc,
            child: const Scaffold(body: WirelessBody()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap secured network (OfficeWifi 3)
        await tester.tap(find.text('OfficeWifi 3'));
        await tester.pumpAndSettle();

        expect(find.byType(WirelessPasswordBottomSheet), findsOneWidget);

        // Tap back button in bottom sheet
        final backButton = find.descendant(
          of: find.byType(WirelessPasswordBottomSheet),
          matching: find.byWidgetPredicate(
            (w) =>
                w is MechanixIconButton &&
                w.icon is ImageIcon &&
                ((w.icon as ImageIcon).image as AssetImage).assetName ==
                    SettingIcons.back,
          ),
        );
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Bottom sheet dismissed
        expect(find.byType(WirelessPasswordBottomSheet), findsNothing);

        // Verify no connect event was sent
        verifyNever(
          () => mockWirelessBloc.add(any(that: isA<ConnectToNetworkEvent>())),
        );
      },
    );

    testWidgets(
      'navigating to NetworkDetailScreen and tapping refresh dispatches LoadWireless(requestScan: true)',
      (WidgetTester tester) async {
        when(() => mockWirelessBloc.state).thenReturn(
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            savedNetworks: [tConnectedNetwork],
            myNetworks: [tConnectedNetwork],
          ),
        );

        await tester.pumpWidget(
          createWirelessTestWidget(
            wirelessBloc: mockWirelessBloc,
            child: const Scaffold(body: WirelessBody()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap settings on connected network
        final settingsButton = find.descendant(
          of: find.byKey(const ValueKey('connected_OfficeWifi 1')),
          matching: find.byType(MechanixIconButton),
        );
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        expect(find.byType(NetworkDetailScreen), findsOneWidget);

        // Open menu via moreVert icon
        final moreVertButton = find.byWidgetPredicate(
          (w) =>
              w is MechanixIconButton &&
              w.icon is ImageIcon &&
              ((w.icon as ImageIcon).image as AssetImage).assetName ==
                  SettingIcons.moreVert,
        );
        expect(moreVertButton, findsOneWidget);
        await tester.tap(moreVertButton);
        await tester.pumpAndSettle();

        // Tap refresh menu item
        final refreshItem = find.text('Refresh');
        expect(refreshItem, findsOneWidget);
        await tester.tap(refreshItem);
        await tester.pump();

        // Verify LoadWireless(requestScan: true) is dispatched
        verify(
          () => mockWirelessBloc.add(const LoadWireless(requestScan: true)),
        ).called(1);
      },
    );
  });
}
