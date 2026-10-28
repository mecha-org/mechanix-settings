import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/dns.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv4_address.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv6_address.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/network_details_body.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  late MockWirelessBloc mockWirelessBloc;

  setUpAll(() {
    registerWirelessFallbackValues();
  });

  setUp(() {
    mockWirelessBloc = MockWirelessBloc();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required String networkName,
    WirelessState state = const WirelessState(
      isWirelessOn: true,
      connectedNetworkName: 'OfficeWifi 1',
      savedNetworks: [tConnectedNetwork, tSavedNetwork],
      myNetworks: [tConnectedNetwork, tSavedNetwork],
    ),
  }) async {
    useTallSurface(tester);
    when(() => mockWirelessBloc.state).thenReturn(state);

    await tester.pumpWidget(
      createWirelessLauncherWidget(
        wirelessBloc: mockWirelessBloc,
        screenBuilder: (_) => NetworkDetailScreen(networkName: networkName),
      ),
    );
    await openScreenUnderTest(tester);
    expect(find.byType(NetworkDetailScreen), findsOneWidget);
  }

  final findForgetButton = find.byKey(const Key('network_detail_forget_button'));

  Future<void> tapForget(WidgetTester tester) async {
    await tester.tap(findForgetButton);
    await tester.pumpAndSettle();
  }

  Future<void> expandTile(WidgetTester tester, String tileKey) async {
    final accordion = find.descendant(
      of: find.byKey(ValueKey(tileKey)),
      matching: findIconButtonWithAsset(SettingIcons.caretDown),
    );
    await tester.ensureVisible(accordion);
    await tester.tap(accordion);
    await tester.pumpAndSettle();
  }

  group('NetworkDetailScreen Widget Tests', () {
    testWidgets('renders network name as title, back and forget buttons', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);

      expect(
        find.descendant(
          of: find.byType(MechanixAppBar),
          matching: find.text(tConnectedNetwork.name),
        ),
        findsOneWidget,
      );
      expect(findBackButton, findsOneWidget);
      expect(findForgetButton, findsOneWidget);
      expect(
        find.descendant(
          of: findForgetButton,
          matching: find.byWidgetPredicate(
            (w) =>
                w is ImageIcon &&
                w.image is AssetImage &&
                (w.image as AssetImage).assetName == SettingIcons.delete,
          ),
        ),
        findsOneWidget,
      );
      // The overflow menu (refresh / forget) was removed.
      expect(findIconButtonWithAsset(SettingIcons.moreVert), findsNothing);
      expect(find.byType(NetworkDetailsBody), findsOneWidget);
    });

    testWidgets('tapping back pops the screen', (WidgetTester tester) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(NetworkDetailScreen), findsNothing);
    });

    testWidgets('shows details of a connected network', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      expect(find.text(l10n.password), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);

      expect(find.text(l10n.wirelessAddress), findsOneWidget);
      expect(find.text(tConnectedNetwork.wirelessAddress), findsOneWidget);

      expect(find.text(l10n.signalStrength), findsOneWidget);
      expect(find.text(l10n.signalStrengthExcellent), findsOneWidget);

      expect(find.text(l10n.linkSpeed), findsOneWidget);
      expect(
        find.text('300Mb/s (${l10n.wifiFrequencyGHz('5.2')})'),
        findsOneWidget,
      );

      expect(find.text(l10n.security), findsOneWidget);
      expect(
        find.text(WirelessSecurity.wpaWpa2Personal.label(l10n)),
        findsOneWidget,
      );

      expect(find.text(l10n.connectAutomatically), findsOneWidget);
      expect(find.text(l10n.lowDataMode), findsOneWidget);
      expect(find.text(l10n.advanceSettingsNotice), findsNothing);

      expect(find.byKey(const ValueKey('ipv4_address_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('ipv6_address_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('dns_tile')), findsOneWidget);
    });

    testWidgets('tapping the eye icon reveals and hides the password', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);

      expect(find.text(tConnectedNetwork.password), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(find.text(tConnectedNetwork.password), findsOneWidget);
      expect(find.text('••••••••'), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.text(tConnectedNetwork.password), findsNothing);
      expect(find.text('••••••••'), findsOneWidget);
    });

    testWidgets('hides password and address rows when they are empty', (
      WidgetTester tester,
    ) async {
      const network = WifiNetwork(
        name: 'Bare',
        isConnected: true,
        security: WirelessSecurity.none,
        isSecured: false,
      );
      await pumpDetail(
        tester,
        networkName: network.name,
        state: const WirelessState(
          isWirelessOn: true,
          connectedNetworkName: 'Bare',
          savedNetworks: [network],
        ),
      );
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      expect(find.text(l10n.password), findsNothing);
      expect(find.text(l10n.wirelessAddress), findsNothing);
      expect(find.text(l10n.linkSpeed), findsNothing);
      expect(find.text(WirelessSecurity.none.label(l10n)), findsOneWidget);
    });

    testWidgets('long pressing the wireless address copies it', (
      WidgetTester tester,
    ) async {
      final copied = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await pumpDetail(tester, networkName: tConnectedNetwork.name);
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      expect(findIconButtonWithAsset(SettingIcons.copy), findsNothing);

      await tester.longPress(find.text(tConnectedNetwork.wirelessAddress));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(copied, [tConnectedNetwork.wirelessAddress]);
      expect(find.text(l10n.copiedToClipboard), findsOneWidget);
      expect(findIconButtonWithAsset(SettingIcons.copy), findsOneWidget);

      // The copy indicator resets after two seconds; let all timers finish.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(findIconButtonWithAsset(SettingIcons.copy), findsNothing);
    });

    testWidgets(
      'toggling connect automatically dispatches UpdateNetworkSettingsEvent',
      (WidgetTester tester) async {
        await pumpDetail(tester, networkName: tConnectedNetwork.name);

        final switches = find.byType(MechanixSwitch);
        expect(switches, findsNWidgets(2));
        expect(tester.widget<MechanixSwitch>(switches.at(0)).value, isTrue);

        await tester.tap(switches.at(0));
        await tester.pump();

        verify(
          () => mockWirelessBloc.add(
            UpdateNetworkSettingsEvent(
              tConnectedNetwork.copyWith(autoJoin: false),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'toggling low data mode dispatches UpdateNetworkSettingsEvent',
      (WidgetTester tester) async {
        await pumpDetail(tester, networkName: tConnectedNetwork.name);

        final switches = find.byType(MechanixSwitch);
        expect(tester.widget<MechanixSwitch>(switches.at(1)).value, isFalse);

        await tester.tap(switches.at(1));
        await tester.pump();

        verify(
          () => mockWirelessBloc.add(
            UpdateNetworkSettingsEvent(
              tConnectedNetwork.copyWith(lowDataMode: true),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('disconnected network shows notice and ignores switch taps', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tSavedNetwork.name);
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      expect(find.text(l10n.advanceSettingsNotice), findsOneWidget);

      final switches = find.byType(MechanixSwitch);
      // While disconnected the switches reflect the saved values but are
      // disabled (wrapped in IgnorePointer).
      expect(
        tester.widget<MechanixSwitch>(switches.at(0)).value,
        tSavedNetwork.autoJoin,
      );
      expect(
        tester.widget<MechanixSwitch>(switches.at(1)).value,
        tSavedNetwork.lowDataMode,
      );
      for (var i = 0; i < 2; i++) {
        expect(
          find.ancestor(
            of: switches.at(i),
            matching: find.byWidgetPredicate(
              (w) => w is IgnorePointer && w.ignoring,
            ),
          ),
          findsWidgets,
        );
      }

      await tester.tap(switches.at(0), warnIfMissed: false);
      await tester.tap(switches.at(1), warnIfMissed: false);
      await tester.pump();

      verifyNever(
        () =>
            mockWirelessBloc.add(any(that: isA<UpdateNetworkSettingsEvent>())),
      );
    });

    testWidgets('disconnected network cannot expand IPv4 section', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tSavedNetwork.name);
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      final accordion = find.descendant(
        of: find.byKey(const ValueKey('ipv4_address_tile')),
        matching: findIconButtonWithAsset(SettingIcons.caretDown),
      );
      await tester.ensureVisible(accordion);
      await tester.tap(accordion, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text(l10n.configureIp), findsNothing);
    });

    testWidgets('expanding IPv4 shows config row that opens the IPv4 sheet', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      await expandTile(tester, 'ipv4_address_tile');

      expect(find.text(l10n.configureIp), findsOneWidget);
      expect(
        find.text(IPv4ConfigType.automatic.label(l10n).toUpperCase()),
        findsWidgets,
      );

      await tester.tap(find.text(l10n.configureIp));
      await tester.pumpAndSettle();

      expect(find.byType(IPv4AddressBottomSheet), findsOneWidget);
    });

    testWidgets('manual IPv4 config shows address, subnet and router', (
      WidgetTester tester,
    ) async {
      final network = tConnectedNetwork.copyWith(
        ipConfigType: IPv4ConfigType.manual,
        ipAddress: '192.168.1.50',
        subnetMask: '255.255.255.0',
        router: '192.168.1.1',
      );
      await pumpDetail(
        tester,
        networkName: network.name,
        state: WirelessState(
          isWirelessOn: true,
          connectedNetworkName: network.name,
          savedNetworks: [network],
        ),
      );
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      await expandTile(tester, 'ipv4_address_tile');

      expect(find.text(l10n.ipAddressLabel), findsOneWidget);
      expect(find.text('192.168.1.50'), findsOneWidget);
      expect(find.text(l10n.subnetMaskLabel), findsOneWidget);
      expect(find.text('255.255.255.0'), findsOneWidget);
      expect(find.text(l10n.routerLabel), findsOneWidget);
      expect(find.text('192.168.1.1'), findsOneWidget);
    });

    testWidgets('expanding IPv6 shows config row that opens the IPv6 sheet', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      await expandTile(tester, 'ipv6_address_tile');

      expect(find.text(l10n.configureIpv6), findsOneWidget);

      await tester.tap(find.text(l10n.configureIpv6));
      await tester.pumpAndSettle();

      expect(find.byType(IPv6AddressBottomSheet), findsOneWidget);
    });

    testWidgets('expanding DNS shows config row that opens the DNS sheet', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      await expandTile(tester, 'dns_tile');

      expect(find.text(l10n.configureDns), findsOneWidget);

      await tester.tap(find.text(l10n.configureDns));
      await tester.pumpAndSettle();

      expect(find.byType(DNSBottomSheet), findsOneWidget);
    });

    testWidgets('manual DNS config lists each server', (
      WidgetTester tester,
    ) async {
      final network = tConnectedNetwork.copyWith(
        dnsConfigType: DNSConfigType.manual,
        dnsServers: ['1.1.1.1', '8.8.8.8'],
      );
      await pumpDetail(
        tester,
        networkName: network.name,
        state: WirelessState(
          isWirelessOn: true,
          connectedNetworkName: network.name,
          savedNetworks: [network],
        ),
      );
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      await expandTile(tester, 'dns_tile');

      expect(find.text(l10n.serverNumber(1)), findsOneWidget);
      expect(find.text('1.1.1.1'), findsOneWidget);
      expect(find.text(l10n.serverNumber(2)), findsOneWidget);
      expect(find.text('8.8.8.8'), findsOneWidget);
    });

    testWidgets(
      'forget button confirms, dispatches ForgetNetworkEvent and pops',
      (WidgetTester tester) async {
        await pumpDetail(tester, networkName: tConnectedNetwork.name);
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await tapForget(tester);

        expect(
          find.text(l10n.forgetWifiPrompt(tConnectedNetwork.name)),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('delete_network_delete_button')));
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            any(
              that: isA<ForgetNetworkEvent>().having(
                (e) => e.network,
                'network',
                tConnectedNetwork,
              ),
            ),
          ),
        ).called(1);
        expect(find.byType(NetworkDetailScreen), findsNothing);
      },
    );

    testWidgets('cancelling forget keeps the detail screen open', (
      WidgetTester tester,
    ) async {
      await pumpDetail(tester, networkName: tConnectedNetwork.name);

      await tapForget(tester);

      await tester.tap(find.byKey(const Key('delete_network_cancel_button')));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockWirelessBloc.add(any(that: isA<ForgetNetworkEvent>())),
      );
      expect(find.byType(NetworkDetailScreen), findsOneWidget);
    });

    testWidgets('resolves a network that is only in available networks', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        networkName: tSecuredAvailableNetwork.name,
        state: const WirelessState(
          isWirelessOn: true,
          availableNetworks: [tSecuredAvailableNetwork],
        ),
      );
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      expect(
        find.text(WirelessSecurity.wpaWpa2Personal.label(l10n)),
        findsOneWidget,
      );
      expect(find.text(l10n.advanceSettingsNotice), findsOneWidget);
    });

    testWidgets('falls back to an empty network when name is unknown', (
      WidgetTester tester,
    ) async {
      await pumpDetail(
        tester,
        networkName: 'Ghost',
        state: const WirelessState(isWirelessOn: true),
      );
      final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

      expect(
        find.descendant(
          of: find.byType(MechanixAppBar),
          matching: find.text('Ghost'),
        ),
        findsOneWidget,
      );
      expect(find.text(WirelessSecurity.none.label(l10n)), findsOneWidget);
      expect(find.text(l10n.password), findsNothing);
      expect(find.text(l10n.advanceSettingsNotice), findsOneWidget);
    });

    testWidgets(
      'state updates refresh changed rows and keep local row state',
      (WidgetTester tester) async {
        useTallSurface(tester);
        final controller = StreamController<WirelessState>();
        addTearDown(controller.close);

        const initial = WirelessState(
          isWirelessOn: true,
          connectedNetworkName: 'OfficeWifi 1',
          savedNetworks: [tConnectedNetwork],
        );
        whenListen(mockWirelessBloc, controller.stream, initialState: initial);

        await tester.pumpWidget(
          createWirelessLauncherWidget(
            wirelessBloc: mockWirelessBloc,
            screenBuilder: (_) =>
                NetworkDetailScreen(networkName: tConnectedNetwork.name),
          ),
        );
        await openScreenUnderTest(tester);
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        // Reveal the password (local state of the password row).
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();
        expect(find.text(tConnectedNetwork.password), findsOneWidget);
        expect(find.text(l10n.signalStrengthExcellent), findsOneWidget);

        // A scan reports a weaker signal and a new link speed.
        controller.add(
          initial.copyWith(
            savedNetworks: [
              tConnectedNetwork.copyWith(
                rawSignalStrength: 45,
                speedMbps: 144,
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text(l10n.signalStrengthFair), findsOneWidget);
        expect(find.text(l10n.signalStrengthExcellent), findsNothing);
        expect(
          find.text('144Mb/s (${l10n.wifiFrequencyGHz('5.2')})'),
          findsOneWidget,
        );
        // Unrelated row kept its state.
        expect(find.text(tConnectedNetwork.password), findsOneWidget);
      },
    );

    testWidgets('toggle uses the latest network from the bloc state', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      final controller = StreamController<WirelessState>();
      addTearDown(controller.close);

      const initial = WirelessState(
        isWirelessOn: true,
        connectedNetworkName: 'OfficeWifi 1',
        savedNetworks: [tConnectedNetwork],
      );
      whenListen(mockWirelessBloc, controller.stream, initialState: initial);

      await tester.pumpWidget(
        createWirelessLauncherWidget(
          wirelessBloc: mockWirelessBloc,
          screenBuilder: (_) =>
              NetworkDetailScreen(networkName: tConnectedNetwork.name),
        ),
      );
      await openScreenUnderTest(tester);

      final updated = tConnectedNetwork.copyWith(lowDataMode: true);
      controller.add(initial.copyWith(savedNetworks: [updated]));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(MechanixSwitch).first);
      await tester.pump();

      verify(
        () => mockWirelessBloc.add(
          UpdateNetworkSettingsEvent(updated.copyWith(autoJoin: false)),
        ),
      ).called(1);
    });

    group('detail rows', () {
      WirelessState stateFor(WifiNetwork network) => WirelessState(
        isWirelessOn: true,
        connectedNetworkName: network.isConnected ? network.name : null,
        savedNetworks: [network],
      );

      testWidgets('formats sub-GHz frequencies in MHz', (
        WidgetTester tester,
      ) async {
        final network = tConnectedNetwork.copyWith(frequency: 900);
        await pumpDetail(
          tester,
          networkName: network.name,
          state: stateFor(network),
        );
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        expect(
          find.text('300Mb/s (${l10n.wifiFrequencyMHz(900)})'),
          findsOneWidget,
        );
      });

      testWidgets('shows only the speed when frequency is unknown', (
        WidgetTester tester,
      ) async {
        final network = tConnectedNetwork.copyWith(frequency: 0);
        await pumpDetail(
          tester,
          networkName: network.name,
          state: stateFor(network),
        );

        expect(find.text('300Mb/s'), findsOneWidget);
      });

      final signalLabels = <int, String Function(AppLocalizations)>{
        85: (l) => l.signalStrengthExcellent,
        65: (l) => l.signalStrengthGood,
        45: (l) => l.signalStrengthFair,
        10: (l) => l.signalStrengthWeak,
      };

      for (final entry in signalLabels.entries) {
        testWidgets('signal strength ${entry.key}% shows its label', (
          WidgetTester tester,
        ) async {
          final network = tConnectedNetwork.copyWith(
            rawSignalStrength: entry.key,
          );
          await pumpDetail(
            tester,
            networkName: network.name,
            state: stateFor(network),
          );
          final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

          expect(find.text(entry.value(l10n)), findsOneWidget);
        });
      }

      testWidgets('signal strength shows none when only level is known', (
        WidgetTester tester,
      ) async {
        final network = tConnectedNetwork.copyWith(rawSignalStrength: 0);
        await pumpDetail(
          tester,
          networkName: network.name,
          state: stateFor(network),
        );
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        expect(find.text(l10n.signalStrengthNone), findsOneWidget);
      });

      testWidgets('copy button and right click copy the address again', (
        WidgetTester tester,
      ) async {
        final copied = <String>[];
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
        addTearDown(
          () =>
              messenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );

        await pumpDetail(tester, networkName: tConnectedNetwork.name);

        // Right click (secondary tap) copies.
        await tester.tap(
          find.text(tConnectedNetwork.wirelessAddress),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        expect(copied, hasLength(1));

        // While the copied indicator is visible, tapping it copies again.
        final copyButton = findIconButtonWithAsset(SettingIcons.copy);
        expect(copyButton, findsOneWidget);
        // Invoke directly: the top snackbar may sit over the row.
        tester.widget<MechanixIconButton>(copyButton).onPressed!();
        await tester.pump();
        expect(copied, [
          tConnectedNetwork.wirelessAddress,
          tConnectedNetwork.wirelessAddress,
        ]);

        await flushSnackbars(tester);
        expect(findIconButtonWithAsset(SettingIcons.copy), findsNothing);
      });

      testWidgets('manual IPv4 with empty values shows dashes', (
        WidgetTester tester,
      ) async {
        final network = tConnectedNetwork.copyWith(
          ipConfigType: IPv4ConfigType.manual,
          ipAddress: '',
          subnetMask: '',
          router: '',
        );
        await pumpDetail(
          tester,
          networkName: network.name,
          state: stateFor(network),
        );

        await expandTile(tester, 'ipv4_address_tile');

        expect(find.text('-'), findsNWidgets(3));
      });

      testWidgets('manual IPv6 shows address, prefix and gateway rows', (
        WidgetTester tester,
      ) async {
        final network = tConnectedNetwork.copyWith(
          ipv6ConfigType: IPv6ConfigType.manual,
          ipv6Address: '2001:db8::10',
          ipv6Prefix: 48,
          ipv6Gateway: 'fe80::1',
        );
        await pumpDetail(
          tester,
          networkName: network.name,
          state: stateFor(network),
        );
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await expandTile(tester, 'ipv6_address_tile');

        expect(find.text(l10n.ipv6AddressLabel), findsWidgets);
        expect(find.text('2001:db8::10'), findsOneWidget);
        expect(find.text(l10n.ipv6PrefixLabel), findsOneWidget);
        expect(find.text('48'), findsOneWidget);
        expect(find.text('fe80::1'), findsOneWidget);
      });

      testWidgets('manual IPv6 hides rows that have no value', (
        WidgetTester tester,
      ) async {
        final network = tConnectedNetwork.copyWith(
          ipv6ConfigType: IPv6ConfigType.manual,
          ipv6Address: '',
          ipv6Prefix: 0,
          ipv6Gateway: '',
        );
        await pumpDetail(
          tester,
          networkName: network.name,
          state: stateFor(network),
        );
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await expandTile(tester, 'ipv6_address_tile');

        expect(find.text(l10n.configureIpv6), findsOneWidget);
        expect(find.text(l10n.ipv6PrefixLabel), findsNothing);
      });
    });

    group('saving from configuration sheets', () {
      Future<void> openConfig(
        WidgetTester tester,
        String tileKey,
        String configureLabel,
      ) async {
        await expandTile(tester, tileKey);
        await tester.tap(find.text(configureLabel));
        await tester.pumpAndSettle();
      }

      testWidgets('saving IPv4 sheet dispatches UpdateIPSettingsEvent', (
        WidgetTester tester,
      ) async {
        await pumpDetail(tester, networkName: tConnectedNetwork.name);
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await openConfig(tester, 'ipv4_address_tile', l10n.configureIp);
        await tester.tap(
          find.descendant(
            of: find.byType(IPv4AddressBottomSheet),
            matching: findCheckButton,
          ),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            UpdateIPSettingsEvent(
              network: tConnectedNetwork,
              ipConfigType: IPv4ConfigType.automatic,
              ipAddress: tConnectedNetwork.ipAddress,
              subnetMask: tConnectedNetwork.subnetMask,
              router: tConnectedNetwork.router,
            ),
          ),
        ).called(1);
        expect(find.byType(IPv4AddressBottomSheet), findsNothing);
      });

      testWidgets('saving IPv6 sheet dispatches UpdateIPv6SettingsEvent', (
        WidgetTester tester,
      ) async {
        await pumpDetail(tester, networkName: tConnectedNetwork.name);
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await openConfig(tester, 'ipv6_address_tile', l10n.configureIpv6);
        await tester.tap(
          find.descendant(
            of: find.byType(IPv6AddressBottomSheet),
            matching: findCheckButton,
          ),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            UpdateIPv6SettingsEvent(
              network: tConnectedNetwork,
              ipv6ConfigType: IPv6ConfigType.automatic,
              ipv6Address: tConnectedNetwork.ipv6Address,
              ipv6Prefix: tConnectedNetwork.ipv6Prefix,
              ipv6Gateway: tConnectedNetwork.ipv6Gateway,
            ),
          ),
        ).called(1);
        expect(find.byType(IPv6AddressBottomSheet), findsNothing);
      });

      testWidgets('saving DNS sheet dispatches UpdateDNSSettingsEvent', (
        WidgetTester tester,
      ) async {
        await pumpDetail(tester, networkName: tConnectedNetwork.name);
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await openConfig(tester, 'dns_tile', l10n.configureDns);
        await tester.tap(
          find.descendant(
            of: find.byType(DNSBottomSheet),
            matching: findCheckButton,
          ),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            UpdateDNSSettingsEvent(
              network: tConnectedNetwork,
              dnsConfigType: DNSConfigType.automatic,
              dnsServers: tConnectedNetwork.dnsServers,
              dnsSearchDomains: tConnectedNetwork.dnsSearchDomains,
            ),
          ),
        ).called(1);
        expect(find.byType(DNSBottomSheet), findsNothing);
      });

      testWidgets('closing a sheet with back does not dispatch updates', (
        WidgetTester tester,
      ) async {
        await pumpDetail(tester, networkName: tConnectedNetwork.name);
        final l10n = l10nOf(tester, find.byType(NetworkDetailScreen));

        await openConfig(tester, 'ipv4_address_tile', l10n.configureIp);
        await tester.tap(
          find.descendant(
            of: find.byType(IPv4AddressBottomSheet),
            matching: findBackButton,
          ),
        );
        await tester.pumpAndSettle();

        verifyNever(
          () => mockWirelessBloc.add(any(that: isA<UpdateIPSettingsEvent>())),
        );
      });

      test('sheet results compare by value', () {
        expect(
          const IPv4SettingsResult(
            configType: IPv4ConfigType.manual,
            ipAddress: '10.0.0.2',
            subnetMask: '24',
            gateway: '10.0.0.1',
          ),
          const IPv4SettingsResult(
            configType: IPv4ConfigType.manual,
            ipAddress: '10.0.0.2',
            subnetMask: '24',
            gateway: '10.0.0.1',
          ),
        );
        expect(
          const IPv6SettingsResult(
            configType: IPv6ConfigType.manual,
            ipAddress: '::1',
            prefix: 64,
            gateway: '',
          ).props,
          [IPv6ConfigType.manual, '::1', 64, ''],
        );
        expect(
          const DNSSettingsResult(
            configType: DNSConfigType.manual,
            servers: ['1.1.1.1'],
            searchDomains: [],
          ).props,
          [
            DNSConfigType.manual,
            ['1.1.1.1'],
            <String>[],
          ],
        );
      });
    });
  });
}
