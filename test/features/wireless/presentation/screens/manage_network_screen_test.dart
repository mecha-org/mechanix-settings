import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/manage_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/manage_network/saved_network_tile.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  late MockWirelessBloc mockWirelessBloc;

  setUpAll(() {
    registerWirelessFallbackValues();
  });

  setUp(() {
    mockWirelessBloc = MockWirelessBloc();
  });

  Future<void> pumpManageNetworks(
    WidgetTester tester, {
    WirelessState state = const WirelessState(
      isWirelessOn: true,
      connectedNetworkName: 'OfficeWifi 1',
      savedNetworks: [tConnectedNetwork, tSavedNetwork],
    ),
  }) async {
    when(() => mockWirelessBloc.state).thenReturn(state);

    await tester.pumpWidget(
      createWirelessLauncherWidget(
        wirelessBloc: mockWirelessBloc,
        screenBuilder: (_) => const ManageNetworksScreen(),
      ),
    );
    await openScreenUnderTest(tester);
    expect(find.byType(ManageNetworksScreen), findsOneWidget);
  }

  Finder tileFor(String name) => find.ancestor(
    of: find.text(name),
    matching: find.byType(SavedNetworkTile),
  );

  group('ManageNetworksScreen Widget Tests', () {
    testWidgets('renders title and back button', (WidgetTester tester) async {
      await pumpManageNetworks(tester);
      final l10n = l10nOf(tester, find.byType(ManageNetworksScreen));

      expect(
        find.descendant(
          of: find.byType(MechanixAppBar),
          matching: find.text(l10n.manageNetworks),
        ),
        findsOneWidget,
      );
      expect(findBackButton, findsOneWidget);
    });

    testWidgets('tapping back pops the screen', (WidgetTester tester) async {
      await pumpManageNetworks(tester);

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(ManageNetworksScreen), findsNothing);
    });

    testWidgets('shows empty message when there are no saved networks', (
      WidgetTester tester,
    ) async {
      await pumpManageNetworks(
        tester,
        state: const WirelessState(isWirelessOn: true),
      );
      final l10n = l10nOf(tester, find.byType(ManageNetworksScreen));

      expect(find.text(l10n.noSavedNetwork), findsOneWidget);
      expect(find.byType(SavedNetworkTile), findsNothing);
    });

    testWidgets('lists every saved network with gear and delete buttons', (
      WidgetTester tester,
    ) async {
      await pumpManageNetworks(tester);
      final l10n = l10nOf(tester, find.byType(ManageNetworksScreen));

      expect(find.text(l10n.noSavedNetwork), findsNothing);
      expect(find.byType(SavedNetworkTile), findsNWidgets(2));
      expect(find.text(tConnectedNetwork.name), findsOneWidget);
      expect(find.text(tSavedNetwork.name), findsOneWidget);

      for (final name in [tConnectedNetwork.name, tSavedNetwork.name]) {
        expect(
          find.descendant(
            of: tileFor(name),
            matching: findIconButtonWithAsset(SettingIcons.setting),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tileFor(name),
            matching: findIconButtonWithAsset(SettingIcons.delete),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('tapping a saved network opens its detail screen', (
      WidgetTester tester,
    ) async {
      await pumpManageNetworks(tester);

      await tester.tap(find.text(tSavedNetwork.name));
      await tester.pumpAndSettle();

      expect(find.byType(NetworkDetailScreen), findsOneWidget);
      expect(
        tester
            .widget<NetworkDetailScreen>(find.byType(NetworkDetailScreen))
            .networkName,
        tSavedNetwork.name,
      );
    });

    testWidgets('tapping the gear button opens the detail screen', (
      WidgetTester tester,
    ) async {
      await pumpManageNetworks(tester);

      await tester.tap(
        find.descendant(
          of: tileFor(tConnectedNetwork.name),
          matching: findIconButtonWithAsset(SettingIcons.setting),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NetworkDetailScreen), findsOneWidget);
      expect(
        tester
            .widget<NetworkDetailScreen>(find.byType(NetworkDetailScreen))
            .networkName,
        tConnectedNetwork.name,
      );
    });

    testWidgets('tapping delete shows forget prompt for that network', (
      WidgetTester tester,
    ) async {
      await pumpManageNetworks(tester);
      final l10n = l10nOf(tester, find.byType(ManageNetworksScreen));

      await tester.tap(
        find.descendant(
          of: tileFor(tSavedNetwork.name),
          matching: findIconButtonWithAsset(SettingIcons.delete),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.forgetWifiPrompt(tSavedNetwork.name)),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('delete_network_cancel_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('delete_network_delete_button')),
        findsOneWidget,
      );
    });

    testWidgets('confirming forget dispatches ForgetNetworkEvent', (
      WidgetTester tester,
    ) async {
      await pumpManageNetworks(tester);
      final l10n = l10nOf(tester, find.byType(ManageNetworksScreen));

      await tester.tap(
        find.descendant(
          of: tileFor(tSavedNetwork.name),
          matching: findIconButtonWithAsset(SettingIcons.delete),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_network_delete_button')));
      await tester.pumpAndSettle();

      verify(
        () => mockWirelessBloc.add(
          any(
            that: isA<ForgetNetworkEvent>().having(
              (e) => e.network,
              'network',
              tSavedNetwork,
            ),
          ),
        ),
      ).called(1);
      expect(
        find.text(l10n.forgetWifiPrompt(tSavedNetwork.name)),
        findsNothing,
      );
      // The manage screen itself stays open.
      expect(find.byType(ManageNetworksScreen), findsOneWidget);
    });

    testWidgets('cancelling forget closes the prompt without dispatching', (
      WidgetTester tester,
    ) async {
      await pumpManageNetworks(tester);
      final l10n = l10nOf(tester, find.byType(ManageNetworksScreen));

      await tester.tap(
        find.descendant(
          of: tileFor(tSavedNetwork.name),
          matching: findIconButtonWithAsset(SettingIcons.delete),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_network_cancel_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.forgetWifiPrompt(tSavedNetwork.name)),
        findsNothing,
      );
      verifyNever(
        () => mockWirelessBloc.add(any(that: isA<ForgetNetworkEvent>())),
      );
    });
  });
}
