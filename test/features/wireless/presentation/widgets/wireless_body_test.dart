import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm/nm.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/add_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/manage_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless/wireless_body.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_password.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  late MockWirelessBloc mockWirelessBloc;

  setUpAll(() {
    registerWirelessFallbackValues();
  });

  setUp(() {
    mockWirelessBloc = MockWirelessBloc();
  });

  Future<void> pumpBody(
    WidgetTester tester,
    WirelessState state, {
    bool settle = true,
  }) async {
    when(() => mockWirelessBloc.state).thenReturn(state);

    await tester.pumpWidget(
      createWirelessTestWidget(
        wirelessBloc: mockWirelessBloc,
        child: const Scaffold(body: WirelessBody()),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('WirelessBody Widget Tests', () {
    group('Wi-Fi toggle', () {
      testWidgets('renders switch OFF and toggles to ON', (
        WidgetTester tester,
      ) async {
        await pumpBody(tester, const WirelessState(isWirelessOn: false));
        final l10n = l10nOf(tester, find.byType(WirelessBody));

        expect(find.text(l10n.wifi.toUpperCase()), findsOneWidget);

        final switchFinder = find.byType(MechanixSwitch);
        expect(switchFinder, findsOneWidget);
        expect(tester.widget<MechanixSwitch>(switchFinder).value, isFalse);

        await tester.tap(switchFinder);
        await tester.pump();

        verify(
          () => mockWirelessBloc.add(const ToggleWirelessPower(true)),
        ).called(1);
      });

      testWidgets('renders switch ON and toggles to OFF', (
        WidgetTester tester,
      ) async {
        await pumpBody(tester, const WirelessState(isWirelessOn: true));

        final switchFinder = find.byType(MechanixSwitch);
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
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: false,
            myNetworks: [tConnectedNetwork, tSavedNetwork],
            availableNetworks: [tSecuredAvailableNetwork],
            connectedNetworkName: 'OfficeWifi 1',
          ),
        );

        expect(
          find.byKey(const ValueKey('connected_OfficeWifi 1')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('my_networks')), findsNothing);
        expect(find.byKey(const ValueKey('available_networks')), findsNothing);
        expect(find.byKey(const ValueKey('join_network_tile')), findsNothing);
        expect(find.byKey(const ValueKey('manage_network_tile')), findsNothing);
      });
    });

    group('Connected network', () {
      testWidgets('displays connected network and opens details on gear', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            myNetworks: [tConnectedNetwork, tSavedNetwork],
            savedNetworks: [tConnectedNetwork, tSavedNetwork],
          ),
        );

        final connectedTile = find.byKey(
          const ValueKey('connected_OfficeWifi 1'),
        );
        expect(connectedTile, findsOneWidget);
        expect(find.text('OfficeWifi 1'), findsOneWidget);
        expect(
          find.descendant(
            of: connectedTile,
            matching: findImageIconWithAsset(SettingIcons.ellipse),
          ),
          findsOneWidget,
        );

        final settingsButton = find.descendant(
          of: connectedTile,
          matching: find.byType(MechanixIconButton),
        );
        expect(settingsButton, findsOneWidget);

        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        expect(find.byType(NetworkDetailScreen), findsOneWidget);
      });

      testWidgets('connected network is not repeated in My networks', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            myNetworks: [tConnectedNetwork, tSavedNetwork],
          ),
        );

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('my_networks')),
            matching: find.text('OfficeWifi 1'),
          ),
          findsNothing,
        );
      });

      testWidgets('tapping the connected network does not reconnect', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            myNetworks: [tConnectedNetwork],
          ),
        );

        await tester.tap(find.text('OfficeWifi 1'));
        await tester.pump();

        verifyNever(
          () => mockWirelessBloc.add(any(that: isA<ConnectToNetworkEvent>())),
        );
      });

      testWidgets('shows No Internet subtitle when connectivity is none', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            connectivityState: NetworkManagerConnectivityState.none,
            myNetworks: [tConnectedNetwork],
          ),
        );
        final l10n = l10nOf(tester, find.byType(WirelessBody));

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('connected_OfficeWifi 1')),
            matching: find.text(l10n.noInternetConnection),
          ),
          findsOneWidget,
        );
      });

      testWidgets('hides No Internet subtitle when connectivity is full', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            connectivityState: NetworkManagerConnectivityState.full,
            myNetworks: [tConnectedNetwork],
          ),
        );
        final l10n = l10nOf(tester, find.byType(WirelessBody));

        expect(find.text(l10n.noInternetConnection), findsNothing);
      });
    });

    group('Connecting network', () {
      testWidgets('shows a separate connecting tile for a hidden network', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectingNetworkName: 'HiddenWifi',
          ),
          settle: false,
        );

        final connectingTile = find.byKey(
          const ValueKey('connecting_HiddenWifi'),
        );
        expect(connectingTile, findsOneWidget);
        expect(
          find.descendant(
            of: connectingTile,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
      });

      testWidgets(
        'does not add a connecting tile for a network already listed',
        (WidgetTester tester) async {
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              connectingNetworkName: 'OfficeWifi 3',
              availableNetworks: [tSecuredAvailableNetwork],
            ),
            settle: false,
          );

          expect(
            find.byKey(const ValueKey('connecting_OfficeWifi 3')),
            findsNothing,
          );
          // The list item itself shows the progress instead.
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('OfficeWifi 3')),
              matching: find.byType(CircularProgressIndicator),
            ),
            findsOneWidget,
          );
        },
      );
    });

    group('My networks', () {
      testWidgets(
        'shows count [01], connects saved network without password and opens details on gear',
        (WidgetTester tester) async {
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              connectedNetworkName: 'OfficeWifi 1',
              myNetworks: [tConnectedNetwork, tSavedNetwork],
              savedNetworks: [tConnectedNetwork, tSavedNetwork],
            ),
          );
          final l10n = l10nOf(tester, find.byType(WirelessBody));

          final myNetworks = find.byKey(const ValueKey('my_networks'));
          expect(myNetworks, findsOneWidget);
          expect(find.text(l10n.myNetworks), findsOneWidget);
          expect(find.text('[01]'), findsOneWidget);
          expect(find.text('OfficeWifi 2'), findsOneWidget);

          await tester.tap(find.text('OfficeWifi 2'));
          await tester.pump();

          verify(
            () => mockWirelessBloc.add(
              const ConnectToNetworkEvent('OfficeWifi 2', null),
            ),
          ).called(1);
          expect(find.byType(WirelessPasswordBottomSheet), findsNothing);

          final settingsButton = find.descendant(
            of: myNetworks,
            matching: findIconButtonWithAsset(SettingIcons.setting),
          );
          expect(settingsButton, findsOneWidget);

          await tester.tap(settingsButton);
          await tester.pumpAndSettle();

          expect(find.byType(NetworkDetailScreen), findsOneWidget);
        },
      );

      testWidgets(
        'saved network whose security changed asks for a new password',
        (WidgetTester tester) async {
          const changed = WifiNetwork(
            name: 'Cafe',
            isSecured: true,
            signalLevel: 2,
            security: WirelessSecurity.wpaWpa2Personal,
            savedSecurity: WirelessSecurity.none,
            scannedSecurity: WirelessSecurity.wpaWpa2Personal,
          );
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              myNetworks: [changed],
              savedNetworks: [changed],
            ),
          );

          await tester.tap(find.text('Cafe'));
          await tester.pumpAndSettle();

          // No silent reconnect with the stale (open) profile.
          verifyNever(
            () => mockWirelessBloc.add(const ConnectToNetworkEvent('Cafe', null)),
          );

          final sheet = find.byType(WirelessPasswordBottomSheet);
          expect(sheet, findsOneWidget);
          expect(
            tester.widget<WirelessPasswordBottomSheet>(sheet).securityType,
            WirelessSecurity.wpaWpa2Personal,
          );

          await tester.enterText(find.byType(MechanixTextField), 'newpass123');
          await tester.pump();
          await tester.tap(find.descendant(of: sheet, matching: findCheckButton));
          await tester.pumpAndSettle();

          verify(
            () => mockWirelessBloc.add(
              const ConnectToNetworkEvent('Cafe', 'newpass123'),
            ),
          ).called(1);
        },
      );

      testWidgets(
        'saved network moved from WPA2 to WPA3 asks for a WPA3 password',
        (WidgetTester tester) async {
          const upgraded = WifiNetwork(
            name: 'Home',
            isSecured: true,
            signalLevel: 3,
            security: WirelessSecurity.wpaWpa2Personal,
            savedSecurity: WirelessSecurity.wpaWpa2Personal,
            scannedSecurity: WirelessSecurity.wpa3Personal,
          );
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              myNetworks: [upgraded],
              savedNetworks: [upgraded],
            ),
          );

          await tester.tap(find.text('Home'));
          await tester.pumpAndSettle();

          final sheet = find.byType(WirelessPasswordBottomSheet);
          expect(sheet, findsOneWidget);
          expect(
            tester.widget<WirelessPasswordBottomSheet>(sheet).securityType,
            WirelessSecurity.wpa3Personal,
          );
        },
      );

      testWidgets(
        'cancelling the password sheet for a changed network does not connect',
        (WidgetTester tester) async {
          const changed = WifiNetwork(
            name: 'Cafe',
            isSecured: true,
            signalLevel: 2,
            security: WirelessSecurity.wpaWpa2Personal,
            savedSecurity: WirelessSecurity.none,
            scannedSecurity: WirelessSecurity.wpaWpa2Personal,
          );
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              myNetworks: [changed],
              savedNetworks: [changed],
            ),
          );

          await tester.tap(find.text('Cafe'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.descendant(
              of: find.byType(WirelessPasswordBottomSheet),
              matching: findBackButton,
            ),
          );
          await tester.pumpAndSettle();

          verifyNever(
            () => mockWirelessBloc.add(any(that: isA<ConnectToNetworkEvent>())),
          );
        },
      );

      testWidgets(
        'saved network with unchanged security connects without a password',
        (WidgetTester tester) async {
          const unchanged = WifiNetwork(
            name: 'Home',
            isSecured: true,
            signalLevel: 3,
            security: WirelessSecurity.wpaWpa2Personal,
            savedSecurity: WirelessSecurity.wpaWpa2Personal,
            scannedSecurity: WirelessSecurity.wpaWpa2Personal,
          );
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              myNetworks: [unchanged],
              savedNetworks: [unchanged],
            ),
          );

          await tester.tap(find.text('Home'));
          await tester.pumpAndSettle();

          expect(find.byType(WirelessPasswordBottomSheet), findsNothing);
          verify(
            () => mockWirelessBloc.add(const ConnectToNetworkEvent('Home', null)),
          ).called(1);
        },
      );

      testWidgets('shows count [00] when there are no other saved networks', (
        WidgetTester tester,
      ) async {
        await pumpBody(tester, const WirelessState(isWirelessOn: true));

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('my_networks')),
            matching: find.text('[00]'),
          ),
          findsOneWidget,
        );
      });
    });

    group('Available networks', () {
      testWidgets('shows count [02] and no gear icons', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            myNetworks: [tConnectedNetwork],
            availableNetworks: [
              tSecuredAvailableNetwork,
              tOpenAvailableNetwork,
            ],
          ),
        );
        final l10n = l10nOf(tester, find.byType(WirelessBody));

        final available = find.byKey(const ValueKey('available_networks'));
        expect(available, findsOneWidget);
        expect(find.text(l10n.avaialableNetworks), findsOneWidget);
        expect(find.text('[02]'), findsOneWidget);
        expect(find.text('OfficeWifi 3'), findsOneWidget);
        expect(find.text('OfficeWifi 4'), findsOneWidget);

        expect(
          find.descendant(
            of: available,
            matching: findIconButtonWithAsset(SettingIcons.setting),
          ),
          findsNothing,
        );
      });

      testWidgets('tapping an open network connects directly', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            availableNetworks: [tOpenAvailableNetwork],
          ),
        );

        await tester.tap(find.text('OfficeWifi 4'));
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            const ConnectToNetworkEvent('OfficeWifi 4', null),
          ),
        ).called(1);
        expect(find.byType(WirelessPasswordBottomSheet), findsNothing);
      });

      testWidgets(
        'shows progress indicator instead of refresh while scanning',
        (WidgetTester tester) async {
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              isScanning: true,
              availableNetworks: [tSecuredAvailableNetwork],
            ),
            settle: false,
          );

          final available = find.byKey(const ValueKey('available_networks'));
          expect(
            find.descendant(
              of: available,
              matching: find.byType(CircularProgressIndicator),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: available,
              matching: findIconButtonWithAsset(SettingIcons.refresh),
            ),
            findsNothing,
          );
        },
      );

      testWidgets('tapping refresh restarts Wi-Fi scanning', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            availableNetworks: [tSecuredAvailableNetwork],
          ),
        );

        final refresh = find.descendant(
          of: find.byKey(const ValueKey('available_networks')),
          matching: findIconButtonWithAsset(SettingIcons.refresh),
        );
        expect(refresh, findsOneWidget);

        await tester.tap(refresh);
        await tester.pump();

        verify(() => mockWirelessBloc.add(const ScanNetworks())).called(1);
        verifyNever(
          () => mockWirelessBloc.add(any(that: isA<ToggleWirelessPower>())),
        );
      });

      testWidgets(
        'WEP network accepts a 5 character key in the password sheet',
        (WidgetTester tester) async {
          const wepNetwork = WifiNetwork(
            name: 'OldRouter',
            isSecured: true,
            signalLevel: 2,
            security: WirelessSecurity.wep,
          );
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              availableNetworks: [wepNetwork],
            ),
          );

          await tester.tap(find.text('OldRouter'));
          await tester.pumpAndSettle();

          final sheet = find.byType(WirelessPasswordBottomSheet);
          expect(
            tester.widget<WirelessPasswordBottomSheet>(sheet).securityType,
            WirelessSecurity.wep,
          );

          await tester.enterText(find.byType(MechanixTextField), 'abcde');
          await tester.pump();

          final check = find.descendant(of: sheet, matching: findCheckButton);
          expect(tester.widget<MechanixIconButton>(check).onPressed, isNotNull);

          await tester.tap(check);
          await tester.pumpAndSettle();

          verify(
            () => mockWirelessBloc.add(
              const ConnectToNetworkEvent('OldRouter', 'abcde'),
            ),
          ).called(1);
        },
      );

      testWidgets(
        'WPA network accepts a 64 digit hex key in the password sheet',
        (WidgetTester tester) async {
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              availableNetworks: [tSecuredAvailableNetwork],
            ),
          );

          await tester.tap(find.text('OfficeWifi 3'));
          await tester.pumpAndSettle();

          final sheet = find.byType(WirelessPasswordBottomSheet);
          expect(
            tester.widget<WirelessPasswordBottomSheet>(sheet).securityType,
            WirelessSecurity.wpaWpa2Personal,
          );

          await tester.enterText(
            find.byType(MechanixTextField),
            'a' * 64,
          );
          await tester.pump();

          final check = find.descendant(of: sheet, matching: findCheckButton);
          expect(tester.widget<MechanixIconButton>(check).onPressed, isNotNull);
        },
      );

      testWidgets(
        'secured network opens password sheet and connects with entered password',
        (WidgetTester tester) async {
          await pumpBody(
            tester,
            const WirelessState(
              isWirelessOn: true,
              availableNetworks: [tSecuredAvailableNetwork],
            ),
          );

          await tester.tap(find.text('OfficeWifi 3'));
          await tester.pumpAndSettle();

          final sheet = find.byType(WirelessPasswordBottomSheet);
          expect(sheet, findsOneWidget);

          await tester.enterText(
            find.byType(MechanixTextField),
            'secretpass123',
          );
          await tester.pump();

          await tester.tap(
            find.descendant(of: sheet, matching: findCheckButton),
          );
          await tester.pumpAndSettle();

          verify(
            () => mockWirelessBloc.add(
              const ConnectToNetworkEvent('OfficeWifi 3', 'secretpass123'),
            ),
          ).called(1);
        },
      );

      testWidgets('unchecking connect automatically sends autoConnect: false', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            availableNetworks: [tSecuredAvailableNetwork],
          ),
        );
        final l10n = l10nOf(tester, find.byType(WirelessBody));

        await tester.tap(find.text('OfficeWifi 3'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n.connectAutomatically));
        await tester.pump();

        await tester.enterText(find.byType(MechanixTextField), 'secretpass123');
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: find.byType(WirelessPasswordBottomSheet),
            matching: findCheckButton,
          ),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            const ConnectToNetworkEvent(
              'OfficeWifi 3',
              'secretpass123',
              autoConnect: false,
            ),
          ),
        ).called(1);
      });

      testWidgets('cancelling the password sheet does not connect', (
        WidgetTester tester,
      ) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            availableNetworks: [tSecuredAvailableNetwork],
          ),
        );

        await tester.tap(find.text('OfficeWifi 3'));
        await tester.pumpAndSettle();

        expect(find.byType(WirelessPasswordBottomSheet), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(WirelessPasswordBottomSheet),
            matching: findBackButton,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WirelessPasswordBottomSheet), findsNothing);
        verifyNever(
          () => mockWirelessBloc.add(any(that: isA<ConnectToNetworkEvent>())),
        );
      });
    });

    group('Password required from the repository', () {
      testWidgets(
        'opens the password sheet and reconnects with the entered password',
        (WidgetTester tester) async {
          const initial = WirelessState(isWirelessOn: true);
          whenListen(
            mockWirelessBloc,
            Stream.fromIterable([
              initial.copyWith(connectingNetworkName: 'Cafe'),
              initial.copyWith(
                error: const WirelessFailure(
                  type: WirelessErrorType.passwordRequired,
                  data: {
                    'networkName': 'Cafe',
                    'security': WirelessSecurity.wpa3Personal,
                  },
                ),
              ),
            ]),
            initialState: initial,
          );

          await tester.pumpWidget(
            createWirelessTestWidget(
              wirelessBloc: mockWirelessBloc,
              child: const Scaffold(body: WirelessBody()),
            ),
          );
          await tester.pumpAndSettle();

          final sheet = find.byType(WirelessPasswordBottomSheet);
          expect(sheet, findsOneWidget);
          final sheetWidget = tester.widget<WirelessPasswordBottomSheet>(sheet);
          expect(sheetWidget.networkName, 'Cafe');
          expect(sheetWidget.securityType, WirelessSecurity.wpa3Personal);

          await tester.enterText(find.byType(MechanixTextField), 'newpass123');
          await tester.pump();
          await tester.tap(find.descendant(of: sheet, matching: findCheckButton));
          await tester.pumpAndSettle();

          verify(
            () => mockWirelessBloc.add(
              const ConnectToNetworkEvent('Cafe', 'newpass123'),
            ),
          ).called(1);
        },
      );

      testWidgets('does not open the sheet for other errors', (
        WidgetTester tester,
      ) async {
        const initial = WirelessState(isWirelessOn: true);
        whenListen(
          mockWirelessBloc,
          Stream.fromIterable([
            initial.copyWith(
              error: const WirelessFailure(
                type: WirelessErrorType.connectionFailed,
                data: {'networkName': 'Cafe'},
              ),
            ),
          ]),
          initialState: initial,
        );

        await tester.pumpWidget(
          createWirelessTestWidget(
            wirelessBloc: mockWirelessBloc,
            child: const Scaffold(body: WirelessBody()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WirelessPasswordBottomSheet), findsNothing);
      });
    });

    group('Join and manage tiles', () {
      testWidgets('tapping Join Network opens AddNetworkPage', (
        WidgetTester tester,
      ) async {
        await pumpBody(tester, const WirelessState(isWirelessOn: true));
        final l10n = l10nOf(tester, find.byType(WirelessBody));

        final joinTile = find.byKey(const ValueKey('join_network_tile'));
        expect(joinTile, findsOneWidget);
        expect(find.text(l10n.joinNetworkTitle), findsOneWidget);

        await tester.ensureVisible(joinTile);
        await tester.tap(joinTile);
        await tester.pumpAndSettle();

        expect(find.byType(AddNetworkPage), findsOneWidget);
      });

      testWidgets('tapping Manage Networks opens ManageNetworksScreen', (
        WidgetTester tester,
      ) async {
        await pumpBody(tester, const WirelessState(isWirelessOn: true));
        final l10n = l10nOf(tester, find.byType(WirelessBody));

        final manageTile = find.byKey(const ValueKey('manage_network_tile'));
        expect(manageTile, findsOneWidget);
        expect(find.text(l10n.manageNetworks), findsOneWidget);

        await tester.ensureVisible(manageTile);
        await tester.tap(manageTile);
        await tester.pumpAndSettle();

        expect(find.byType(ManageNetworksScreen), findsOneWidget);
      });
    });

    group('Captive portal', () {
      testWidgets(
        'dispatches OpenCaptivePortal once a connected network enters portal state',
        (WidgetTester tester) async {
          const initial = WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            myNetworks: [tConnectedNetwork],
          );

          whenListen(
            mockWirelessBloc,
            Stream.fromIterable([
              initial.copyWith(isCaptivePortal: true),
              // Further updates while still in portal state must not re-open.
              initial.copyWith(isCaptivePortal: true, isScanning: true),
            ]),
            initialState: initial,
          );

          await tester.pumpWidget(
            createWirelessTestWidget(
              wirelessBloc: mockWirelessBloc,
              child: const Scaffold(body: WirelessBody()),
            ),
          );
          await tester.pump();
          await tester.pump();

          verify(
            () => mockWirelessBloc.add(const OpenCaptivePortal()),
          ).called(1);
        },
      );

      testWidgets('does not open captive portal without a connected network', (
        WidgetTester tester,
      ) async {
        const initial = WirelessState(isWirelessOn: true);

        whenListen(
          mockWirelessBloc,
          Stream.fromIterable([initial.copyWith(isCaptivePortal: true)]),
          initialState: initial,
        );

        await tester.pumpWidget(
          createWirelessTestWidget(
            wirelessBloc: mockWirelessBloc,
            child: const Scaffold(body: WirelessBody()),
          ),
        );
        await tester.pump();
        await tester.pump();

        verifyNever(() => mockWirelessBloc.add(const OpenCaptivePortal()));
      });
    });

    testWidgets(
      'NetworkDetailScreen refresh menu dispatches RefreshNetworkDetails',
      (WidgetTester tester) async {
        await pumpBody(
          tester,
          const WirelessState(
            isWirelessOn: true,
            connectedNetworkName: 'OfficeWifi 1',
            savedNetworks: [tConnectedNetwork],
            myNetworks: [tConnectedNetwork],
          ),
        );

        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('connected_OfficeWifi 1')),
            matching: find.byType(MechanixIconButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(NetworkDetailScreen), findsOneWidget);

        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await tester.tap(findIconButtonWithAsset(SettingIcons.moreVert));
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n.refresh));
        await tester.pump();

        verify(
          () => mockWirelessBloc.add(
            RefreshNetworkDetails(tConnectedNetwork.name),
          ),
        ).called(1);
      },
    );
  });
}
