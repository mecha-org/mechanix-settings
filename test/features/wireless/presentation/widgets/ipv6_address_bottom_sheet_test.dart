import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv6_address.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  final saved = <IPv6SettingsResult>[];

  setUp(saved.clear);

  final network = tConnectedNetwork.copyWith(ipv6Prefix: 64);

  Future<void> openSheet(
    WidgetTester tester, {
    WifiNetwork? forNetwork,
    IPv6ConfigType currentConfig = IPv6ConfigType.automatic,
    String ipAddress = '2001:db8::10',
    String gateway = 'fe80::1',
  }) async {
    final target = forNetwork ?? network;
    useTallSurface(tester);
    await pumpSheetHost(
      tester,
      open: (context) => IPv6AddressBottomSheet.show(
        context: context,
        network: target,
        currentConfig: currentConfig,
        ipAddress: ipAddress,
        prefix: target.ipv6Prefix,
        gateway: gateway,
        onSaved: saved.add,
      ),
    );
    expect(find.byType(IPv6AddressBottomSheet), findsOneWidget);
  }

  Finder field(int index) => find.byType(MechanixTextField).at(index);

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(findCheckButton);
    await tester.pump();
  }

  group('IPv6AddressBottomSheet Widget Tests', () {
    testWidgets('renders header and both options, no fields when automatic', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(IPv6AddressBottomSheet));

      expect(find.text('IPV6 -Configure IP'), findsOneWidget);
      expect(findBackButton, findsOneWidget);
      expect(findCheckButton, findsOneWidget);
      expect(find.text(l10n.automatic), findsOneWidget);
      expect(find.text(l10n.manual), findsOneWidget);
      expect(find.byType(MechanixTextField), findsNothing);
    });

    testWidgets('selecting manual shows prefilled address, prefix and router', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(IPv6AddressBottomSheet));

      await tester.tap(find.text(l10n.manual));
      await tester.pumpAndSettle();

      expect(find.byType(MechanixTextField), findsNWidgets(3));
      expect(find.text(l10n.ipv6AddressLabel), findsOneWidget);
      expect(find.text(l10n.ipv6PrefixLabel), findsOneWidget);
      expect(find.text(l10n.ipv6GatewayLabel), findsOneWidget);
      expect(find.text('2001:db8::10'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
      expect(find.text('fe80::1'), findsOneWidget);
    });

    testWidgets('prefix field is empty when the network prefix is 0', (
      WidgetTester tester,
    ) async {
      await openSheet(
        tester,
        forNetwork: tConnectedNetwork.copyWith(ipv6Prefix: 0),
        currentConfig: IPv6ConfigType.manual,
      );

      final prefixField = tester.widget<TextField>(
        find.descendant(of: field(1), matching: find.byType(TextField)),
      );
      expect(prefixField.controller!.text, isEmpty);
    });

    testWidgets('switching back to automatic hides the fields', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: IPv6ConfigType.manual);
      final l10n = l10nOf(tester, find.byType(IPv6AddressBottomSheet));

      await tester.tap(find.text(l10n.automatic));
      await tester.pumpAndSettle();

      expect(find.byType(MechanixTextField), findsNothing);
    });

    testWidgets('saving automatic config calls onSaved and closes', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved, const [
        IPv6SettingsResult(
          configType: IPv6ConfigType.automatic,
          ipAddress: '2001:db8::10',
          prefix: 64,
          gateway: 'fe80::1',
        ),
      ]);
      expect(find.byType(IPv6AddressBottomSheet), findsNothing);
    });

    testWidgets('saving automatic config defaults an empty prefix to 64', (
      WidgetTester tester,
    ) async {
      await openSheet(
        tester,
        forNetwork: tConnectedNetwork.copyWith(ipv6Prefix: 0),
      );

      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved.single.prefix, 64);
    });

    testWidgets('saving a valid manual config trims values and closes', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: IPv6ConfigType.manual);

      await tester.enterText(field(0), ' 2001:db8:1::20 ');
      await tester.enterText(field(1), ' 48 ');
      await tester.enterText(field(2), ' 2001:db8:1::1 ');
      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved, const [
        IPv6SettingsResult(
          configType: IPv6ConfigType.manual,
          ipAddress: '2001:db8:1::20',
          prefix: 48,
          gateway: '2001:db8:1::1',
        ),
      ]);
      expect(find.byType(IPv6AddressBottomSheet), findsNothing);
    });

    testWidgets('manual config allows an empty gateway', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: IPv6ConfigType.manual);

      await tester.enterText(field(2), '');
      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved.single.gateway, isEmpty);
    });

    testWidgets('back button closes without saving', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: IPv6ConfigType.manual);

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(saved, isEmpty);
      expect(find.byType(IPv6AddressBottomSheet), findsNothing);
    });

    final invalidCases =
        <
          ({
            String description,
            String ip,
            String prefix,
            String gateway,
            String Function(AppLocalizations) message,
          })
        >[
          (
            description: 'malformed IPv6 address',
            ip: 'not-an-ip',
            prefix: '64',
            gateway: 'fe80::1',
            message: (l) => l.invalidIpv6Address,
          ),
          (
            description: 'IPv4 address in the IPv6 field',
            ip: '192.168.1.10',
            prefix: '64',
            gateway: 'fe80::1',
            message: (l) => l.invalidIpv6Address,
          ),
          (
            description: 'empty prefix',
            ip: '2001:db8::10',
            prefix: '',
            gateway: 'fe80::1',
            message: (l) => l.ipv6PrefixRange,
          ),
          (
            description: 'prefix below range',
            ip: '2001:db8::10',
            prefix: '0',
            gateway: 'fe80::1',
            message: (l) => l.ipv6PrefixRange,
          ),
          (
            description: 'prefix above range',
            ip: '2001:db8::10',
            prefix: '129',
            gateway: 'fe80::1',
            message: (l) => l.ipv6PrefixRange,
          ),
          (
            description: 'malformed gateway',
            ip: '2001:db8::10',
            prefix: '64',
            gateway: 'gateway',
            message: (l) => l.invalidIpv6Gateway,
          ),
        ];

    for (final c in invalidCases) {
      testWidgets('shows error for ${c.description}', (
        WidgetTester tester,
      ) async {
        await openSheet(tester, currentConfig: IPv6ConfigType.manual);
        final l10n = l10nOf(tester, find.byType(IPv6AddressBottomSheet));

        await tester.enterText(field(0), c.ip);
        await tester.enterText(field(1), c.prefix);
        await tester.enterText(field(2), c.gateway);
        await tapSave(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(c.message(l10n)), findsOneWidget);
        expect(saved, isEmpty);
        expect(find.byType(IPv6AddressBottomSheet), findsOneWidget);

        await flushSnackbars(tester);
      });
    }
  });

  group('IPv6AddressScreen Widget Tests', () {
    testWidgets('hosts the sheet content and pops after saving', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      await pumpSheetHost(
        tester,
        open: (context) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IPv6AddressScreen(
              network: network,
              currentConfig: IPv6ConfigType.automatic,
              ipAddress: '',
              prefix: 64,
              gateway: '',
              onSaved: saved.add,
            ),
          ),
        ),
      );

      expect(find.byType(IPv6AddressScreen), findsOneWidget);
      expect(find.byType(IPv6AddressBottomSheet), findsOneWidget);

      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved.single.configType, IPv6ConfigType.automatic);
      expect(find.byType(IPv6AddressScreen), findsNothing);
    });
  });
}
