import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm/nm.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/main.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/wireless.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/add_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/manage_network.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wireless Integration Tests', () {
    late MockWirelessRepository mockWirelessRepository;

    late StreamController<List<String>> wifiEventsController;
    late StreamController<List<String>> deviceEventsController;
    late StreamController<List<String>> wirelessDeviceEventsController;

    const tConnectedNetwork = WifiNetwork(
      name: 'OfficeWifi_Connected',
      isConnected: true,
      signalLevel: 3,
      security: WirelessSecurity.wpaWpa2Personal,
    );

    const tSavedNetwork = WifiNetwork(
      name: 'OfficeWifi_Saved',
      isConnected: false,
      signalLevel: 2,
      security: WirelessSecurity.wpaWpa2Personal,
    );

    const tOpenNetwork = WifiNetwork(
      name: 'Guest_Open',
      isConnected: false,
      signalLevel: 2,
      security: WirelessSecurity.none,
    );

    const tSecuredNetwork = WifiNetwork(
      name: 'Corporate_Secured',
      isConnected: false,
      signalLevel: 3,
      security: WirelessSecurity.wpaWpa2Personal,
    );

    setUpAll(() {
      registerFallbackValue(
        const WifiNetwork(
          name: 'Fallback Network',
          security: WirelessSecurity.none,
        ),
      );
      registerFallbackValue(WirelessSecurity.none);
      registerFallbackValue(IPv4ConfigType.automatic);
      registerFallbackValue(IPv6ConfigType.automatic);
      registerFallbackValue(DNSConfigType.automatic);
    });

    setUp(() {
      wifiEventsController = StreamController<List<String>>.broadcast();
      deviceEventsController = StreamController<List<String>>.broadcast();
      wirelessDeviceEventsController =
          StreamController<List<String>>.broadcast();

      mockWirelessRepository = MockWirelessRepository();

      when(() => mockWirelessRepository.init()).thenAnswer((_) async {});
      when(() => mockWirelessRepository.close()).thenAnswer((_) async {});
      when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(false);
      when(
        () => mockWirelessRepository.getConnectivityState(),
      ).thenReturn(NetworkManagerConnectivityState.unknown);
      when(
        () => mockWirelessRepository.getWifiEventsStream(),
      ).thenAnswer((_) => wifiEventsController.stream);
      when(
        () => mockWirelessRepository.getDeviceEventsStream(),
      ).thenAnswer((_) => deviceEventsController.stream);
      when(
        () => mockWirelessRepository.getWirelessDeviceEventsStream(),
      ).thenAnswer((_) => wirelessDeviceEventsController.stream);
      when(
        () => mockWirelessRepository.getWifiDeviceState(),
      ).thenReturn(NetworkManagerDeviceState.activated);
      when(
        () => mockWirelessRepository.getSavedNetworks(),
      ).thenAnswer((_) async => []);
      when(
        () => mockWirelessRepository.getMyNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => []);
      when(() => mockWirelessRepository.requestScan()).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.setWifiEnabled(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.connectToNetwork(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.addNetwork(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.forgetNetwork(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockWirelessRepository.isCaptivePortal(),
      ).thenAnswer((_) async => false);
    });

    tearDown(() {
      wifiEventsController.close();
      deviceEventsController.close();
      wirelessDeviceEventsController.close();
    });

    Widget createTestApp(MockWirelessRepository mockWirelessRepository) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<WirelessRepository>.value(
            value: mockWirelessRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<WirelessBloc>(
              create: (_) =>
                  WirelessBloc(wirelessRepository: mockWirelessRepository)
                    ..add(InitWifi()),
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

    testWidgets('Wireless navigation and initial screen state (Wi-Fi OFF)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(mockWirelessRepository));
      await tester.pumpAndSettle();

      // Verify initial screen is SettingsMenuScreen
      expect(find.byType(SettingsMenuScreen), findsOneWidget);

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Find and tap on Wireless menu tile
      final wirelessMenuTile = find.text(l10n.wireless);
      expect(wirelessMenuTile, findsOneWidget);

      await tester.tap(wirelessMenuTile);
      await tester.pumpAndSettle();

      // Verify we are now on WirelessScreen
      expect(find.byType(WirelessScreen), findsOneWidget);

      // Verify title displays uppercase WIRELESS
      expect(find.text(l10n.wireless.toUpperCase()), findsOneWidget);

      // Verify Wi-Fi switch is OFF
      final powerSwitch = find.byType(MechanixSwitch);
      expect(powerSwitch, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(powerSwitch).value, isFalse);

      // Verify network sections and action tiles are hidden when Wi-Fi is OFF
      expect(
        find.byKey(const ValueKey('connected_OfficeWifi_Connected')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('my_networks')), findsNothing);
      expect(find.byKey(const ValueKey('available_networks')), findsNothing);
      expect(find.byKey(const ValueKey('join_network_tile')), findsNothing);
      expect(find.byKey(const ValueKey('manage_network_tile')), findsNothing);

      // Go back using the back button
      final backButton = findMechanixIconButtonByAsset(SettingIcons.back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify back on SettingsMenuScreen
      expect(find.byType(SettingsMenuScreen), findsOneWidget);
    });

    testWidgets('Toggling Wi-Fi ON and displaying network sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(mockWirelessRepository));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Navigate to WirelessScreen
      await tester.tap(find.text(l10n.wireless));
      await tester.pumpAndSettle();

      final powerSwitch = find.byType(MechanixSwitch);
      expect(tester.widget<MechanixSwitch>(powerSwitch).value, isFalse);

      // Stub repository responses when Wi-Fi is turned ON
      when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
      when(
        () => mockWirelessRepository.getSavedNetworks(),
      ).thenAnswer((_) async => [tConnectedNetwork, tSavedNetwork]);
      when(
        () => mockWirelessRepository.getMyNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => [tConnectedNetwork, tSavedNetwork]);
      when(
        () => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => [tOpenNetwork, tSecuredNetwork]);

      // Toggle Wi-Fi switch to ON
      await tester.tap(powerSwitch);
      await tester.pump();

      verify(() => mockWirelessRepository.setWifiEnabled(true)).called(1);

      // Trigger reactive stream refresh
      deviceEventsController.add(['State']);
      await tester.pumpAndSettle();

      // Verify switch is ON
      expect(tester.widget<MechanixSwitch>(powerSwitch).value, isTrue);

      // Verify connected network tile
      expect(
        find.byKey(const ValueKey('connected_OfficeWifi_Connected')),
        findsOneWidget,
      );
      expect(find.text('OfficeWifi_Connected'), findsOneWidget);

      // Verify My networks section
      expect(find.byKey(const ValueKey('my_networks')), findsOneWidget);
      expect(find.text(l10n.myNetworks), findsOneWidget);
      expect(find.text('OfficeWifi_Saved'), findsOneWidget);

      // Verify Available networks section
      expect(find.byKey(const ValueKey('available_networks')), findsOneWidget);
      expect(find.text(l10n.avaialableNetworks), findsOneWidget);
      expect(find.text('Guest_Open'), findsOneWidget);
      expect(find.text('Corporate_Secured'), findsOneWidget);

      // Verify Join Network and Manage Networks tiles
      expect(find.byKey(const ValueKey('join_network_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('manage_network_tile')), findsOneWidget);
    });

    testWidgets('Connecting to an open Wi-Fi network directly', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
      when(
        () => mockWirelessRepository.getSavedNetworks(),
      ).thenAnswer((_) async => []);
      when(
        () => mockWirelessRepository.getMyNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => [tOpenNetwork]);

      await tester.pumpWidget(createTestApp(mockWirelessRepository));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Navigate to WirelessScreen
      await tester.tap(find.text(l10n.wireless));
      await tester.pumpAndSettle();

      // Tap open network
      final openTile = find.text('Guest_Open');
      expect(openTile, findsOneWidget);
      await tester.tap(openTile);
      await tester.pump();
    });

    testWidgets('Navigating to NetworkDetailScreen and tapping refresh', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
      when(
        () => mockWirelessRepository.getSavedNetworks(),
      ).thenAnswer((_) async => [tConnectedNetwork]);
      when(
        () => mockWirelessRepository.getMyNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => [tConnectedNetwork]);
      when(
        () => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestApp(mockWirelessRepository));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Navigate to WirelessScreen
      await tester.tap(find.text(l10n.wireless));
      await tester.pumpAndSettle();

      // Tap settings on connected network tile
      final settingsBtn = find.descendant(
        of: find.byKey(const ValueKey('connected_OfficeWifi_Connected')),
        matching: find.byType(MechanixIconButton),
      );
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      await tester.pumpAndSettle();

      // Verify on NetworkDetailScreen
      expect(find.byType(NetworkDetailScreen), findsOneWidget);
      expect(find.text('OfficeWifi_Connected'), findsWidgets);

      // Tap moreVert menu button
      final moreBtn = findMechanixIconButtonByAsset(SettingIcons.moreVert);
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Tap refresh menu item
      final refreshItem = find.text(l10n.refresh);
      expect(refreshItem, findsOneWidget);
      await tester.tap(refreshItem);
      await tester.pump();

      // Verify getSavedNetworks re-called to reload details
      verify(
        () => mockWirelessRepository.getSavedNetworks(),
      ).called(greaterThanOrEqualTo(1));

      // Tap back to return to WirelessScreen
      final backButton = findMechanixIconButtonByAsset(SettingIcons.back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(WirelessScreen), findsOneWidget);
    });

    testWidgets('Navigating to Join Network and Manage Networks screens', (
      WidgetTester tester,
    ) async {
      when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
      when(
        () => mockWirelessRepository.getSavedNetworks(),
      ).thenAnswer((_) async => []);
      when(
        () => mockWirelessRepository.getMyNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => []);
      when(
        () => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestApp(mockWirelessRepository));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(SettingsMenuScreen),
      );
      final l10n = AppLocalizations.of(context)!;

      // Navigate to WirelessScreen
      await tester.tap(find.text(l10n.wireless));
      await tester.pumpAndSettle();

      // Tap Join Network tile
      final joinTile = find.byKey(const ValueKey('join_network_tile'));
      expect(joinTile, findsOneWidget);
      await tester.tap(joinTile);
      await tester.pumpAndSettle();

      // Verify on AddNetworkPage
      expect(find.byType(AddNetworkPage), findsOneWidget);

      // Go back
      final backFromAdd = findMechanixIconButtonByAsset(SettingIcons.back);
      expect(backFromAdd, findsOneWidget);
      await tester.tap(backFromAdd);
      await tester.pumpAndSettle();

      expect(find.byType(WirelessScreen), findsOneWidget);

      // Tap Manage Networks tile
      final manageTile = find.byKey(const ValueKey('manage_network_tile'));
      expect(manageTile, findsOneWidget);
      await tester.tap(manageTile);
      await tester.pumpAndSettle();

      // Verify on ManageNetworksScreen
      expect(find.byType(ManageNetworksScreen), findsOneWidget);

      // Go back
      final backFromManage = findMechanixIconButtonByAsset(SettingIcons.back);
      expect(backFromManage, findsOneWidget);
      await tester.tap(backFromManage);
      await tester.pumpAndSettle();

      expect(find.byType(WirelessScreen), findsOneWidget);
    });
  });
}
