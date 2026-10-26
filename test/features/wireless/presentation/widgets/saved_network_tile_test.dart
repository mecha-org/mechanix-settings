import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/manage_network/saved_network_tile.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wifi_signal_icon.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  late MockWirelessBloc mockWirelessBloc;

  setUpAll(() {
    registerWirelessFallbackValues();
  });

  setUp(() {
    mockWirelessBloc = MockWirelessBloc();
    when(() => mockWirelessBloc.state).thenReturn(
      const WirelessState(isWirelessOn: true, savedNetworks: [tSavedNetwork]),
    );
  });

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.pumpWidget(
      createWirelessTestWidget(
        wirelessBloc: mockWirelessBloc,
        child: const Scaffold(body: SavedNetworkTile(network: tSavedNetwork)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SavedNetworkTile Widget Tests', () {
    testWidgets('renders name, signal icon, gear and delete buttons', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);

      expect(find.text(tSavedNetwork.name), findsOneWidget);
      expect(
        tester.widget<WifiSignalIcon>(find.byType(WifiSignalIcon)).type,
        tSavedNetwork.signalType,
      );
      expect(findIconButtonWithAsset(SettingIcons.setting), findsOneWidget);
      expect(findIconButtonWithAsset(SettingIcons.delete), findsOneWidget);
    });

    testWidgets('tapping the tile opens NetworkDetailScreen', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);

      await tester.tap(find.text(tSavedNetwork.name));
      await tester.pumpAndSettle();

      expect(find.byType(NetworkDetailScreen), findsOneWidget);
    });

    testWidgets('tapping the gear opens NetworkDetailScreen', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);

      await tester.tap(findIconButtonWithAsset(SettingIcons.setting));
      await tester.pumpAndSettle();

      expect(find.byType(NetworkDetailScreen), findsOneWidget);
    });

    testWidgets('tapping delete opens the forget prompt', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);
      final l10n = l10nOf(tester, find.byType(SavedNetworkTile));

      await tester.tap(findIconButtonWithAsset(SettingIcons.delete));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.forgetWifiPrompt(tSavedNetwork.name)),
        findsOneWidget,
      );
    });
  });
}
