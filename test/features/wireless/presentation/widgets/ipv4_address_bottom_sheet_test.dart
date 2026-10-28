import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv4_address.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  final saved = <IPv4SettingsResult>[];

  setUp(saved.clear);

  final network = tConnectedNetwork.copyWith(subnetMask: '255.255.255.0');

  Future<void> openSheet(
    WidgetTester tester, {
    IPv4ConfigType currentConfig = IPv4ConfigType.automatic,
    String ipAddress = '192.168.1.50',
    String gateway = '192.168.1.1',
    String? subnetMask,
  }) async {
    useTallSurface(tester);
    await pumpSheetHost(
      tester,
      open: (context) => IPv4AddressBottomSheet.show(
        context: context,
        network: network,
        currentConfig: currentConfig,
        ipAddress: ipAddress,
        gateway: gateway,
        subnetMask: subnetMask,
        onSaved: saved.add,
      ),
    );
    expect(find.byType(IPv4AddressBottomSheet), findsOneWidget);
  }

  Finder field(int index) => find.byType(MechanixTextField).at(index);

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(findCheckButton);
    await tester.pump();
  }

  group('IPv4AddressBottomSheet Widget Tests', () {
    testWidgets('renders header and both options, no fields when automatic', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(IPv4AddressBottomSheet));

      expect(find.text('IPV4 -Configure IP'), findsOneWidget);
      expect(findBackButton, findsOneWidget);
      expect(findCheckButton, findsOneWidget);
      expect(find.byKey(const Key('option_ipv4_automatic')), findsOneWidget);
      expect(find.byKey(const Key('option_ipv4_manual')), findsOneWidget);
      expect(find.text(l10n.automatic), findsOneWidget);
      expect(find.text(l10n.manual), findsOneWidget);
      expect(find.byType(MechanixTextField), findsNothing);
    });

    testWidgets('selecting manual shows prefilled IP, subnet and router', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(IPv4AddressBottomSheet));

      await tester.tap(find.byKey(const Key('option_ipv4_manual')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.ipAddressLabel), findsOneWidget);
      expect(find.text(l10n.subnetMaskLabel), findsOneWidget);
      expect(find.text(l10n.routerLabel), findsOneWidget);
      expect(find.byType(MechanixTextField), findsNWidgets(3));

      // Subnet falls back to the network's subnet when none is passed in.
      expect(find.text('192.168.1.50'), findsOneWidget);
      expect(find.text('255.255.255.0'), findsOneWidget);
      expect(find.text('192.168.1.1'), findsOneWidget);
    });

    testWidgets('uses the explicit subnet mask when one is passed in', (
      WidgetTester tester,
    ) async {
      await openSheet(
        tester,
        currentConfig: IPv4ConfigType.manual,
        subnetMask: '255.255.0.0',
      );

      expect(find.text('255.255.0.0'), findsOneWidget);
      expect(find.text('255.255.255.0'), findsNothing);
    });

    testWidgets('switching back to automatic hides the fields', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: IPv4ConfigType.manual);
      expect(find.byType(MechanixTextField), findsNWidgets(3));

      await tester.tap(find.byKey(const Key('option_ipv4_automatic')));
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
        IPv4SettingsResult(
          configType: IPv4ConfigType.automatic,
          ipAddress: '192.168.1.50',
          subnetMask: '255.255.255.0',
          gateway: '192.168.1.1',
        ),
      ]);
      expect(find.byType(IPv4AddressBottomSheet), findsNothing);
    });

    testWidgets('saving a valid manual config trims values and closes', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: IPv4ConfigType.manual);

      await tester.enterText(field(0), ' 10.0.0.20 ');
      await tester.enterText(field(1), ' 24 ');
      await tester.enterText(field(2), ' 10.0.0.1 ');
      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved, const [
        IPv4SettingsResult(
          configType: IPv4ConfigType.manual,
          ipAddress: '10.0.0.20',
          subnetMask: '24',
          gateway: '10.0.0.1',
        ),
      ]);
      expect(find.byType(IPv4AddressBottomSheet), findsNothing);
    });

    testWidgets('back button closes without saving', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: IPv4ConfigType.manual);

      await tester.enterText(field(0), '10.0.0.20');
      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(saved, isEmpty);
      expect(find.byType(IPv4AddressBottomSheet), findsNothing);
    });

    // Each invalid manual configuration must show its own error and keep the
    // sheet open without saving.
    final invalidCases =
        <
          ({
            String description,
            String ip,
            String subnet,
            String gateway,
            String Function(AppLocalizations) message,
          })
        >[
          (
            description: 'malformed IP address',
            ip: '999.1.1.1',
            subnet: '255.255.255.0',
            gateway: '192.168.1.1',
            message: (l) => l.invalidIpAddress,
          ),
          (
            description: 'unspecified IP address',
            ip: '0.0.0.0',
            subnet: '255.255.255.0',
            gateway: '192.168.1.1',
            message: (l) => l.unspecifiedIpAddress,
          ),
          (
            description: 'loopback IP address',
            ip: '127.0.0.5',
            subnet: '255.255.255.0',
            gateway: '127.0.0.1',
            message: (l) => l.loopbackIpAddress,
          ),
          (
            description: 'multicast IP address',
            ip: '224.0.0.5',
            subnet: '255.255.255.0',
            gateway: '224.0.0.1',
            message: (l) => l.multicastIpAddress,
          ),
          (
            description: 'empty subnet mask',
            ip: '192.168.1.50',
            subnet: '',
            gateway: '192.168.1.1',
            message: (l) => l.invalidSubnetMask,
          ),
          (
            description: 'malformed subnet mask',
            ip: '192.168.1.50',
            subnet: '255.255.300.0',
            gateway: '192.168.1.1',
            message: (l) => l.invalidSubnetMask,
          ),
          (
            description: 'non-contiguous subnet mask',
            ip: '192.168.1.50',
            subnet: '255.0.255.0',
            gateway: '192.168.1.1',
            message: (l) => l.invalidSubnetMask,
          ),
          (
            description: 'non-numeric prefix',
            ip: '192.168.1.50',
            subnet: 'abc',
            gateway: '192.168.1.1',
            message: (l) => l.invalidSubnetPrefix,
          ),
          (
            description: 'prefix out of range',
            ip: '192.168.1.50',
            subnet: '31',
            gateway: '192.168.1.1',
            message: (l) => l.invalidSubnetPrefixRange,
          ),
          (
            description: 'network address',
            ip: '192.168.1.0',
            subnet: '24',
            gateway: '192.168.1.1',
            message: (l) => l.networkAddressNotAllowed,
          ),
          (
            description: 'broadcast address',
            ip: '192.168.1.255',
            subnet: '24',
            gateway: '192.168.1.1',
            message: (l) => l.broadcastAddressNotAllowed,
          ),
          (
            description: 'malformed gateway',
            ip: '192.168.1.50',
            subnet: '24',
            gateway: 'router',
            message: (l) => l.invalidGateway,
          ),
          (
            description: 'gateway in a different subnet',
            ip: '192.168.1.50',
            subnet: '24',
            gateway: '10.0.0.1',
            message: (l) => l.gatewayDifferentSubnet,
          ),
          (
            description: 'gateway equal to the IP address',
            ip: '192.168.1.50',
            subnet: '24',
            gateway: '192.168.1.50',
            message: (l) => l.gatewaySameAsIp,
          ),
        ];

    for (final c in invalidCases) {
      testWidgets('shows error for ${c.description}', (
        WidgetTester tester,
      ) async {
        await openSheet(tester, currentConfig: IPv4ConfigType.manual);
        final l10n = l10nOf(tester, find.byType(IPv4AddressBottomSheet));

        await tester.enterText(field(0), c.ip);
        await tester.enterText(field(1), c.subnet);
        await tester.enterText(field(2), c.gateway);
        await tapSave(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(c.message(l10n)), findsOneWidget);
        expect(saved, isEmpty);
        expect(find.byType(IPv4AddressBottomSheet), findsOneWidget);

        await flushSnackbars(tester);
      });
    }
  });

  group('IPv4AddressScreen Widget Tests', () {
    testWidgets('hosts the sheet content and pops after saving', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      await pumpSheetHost(
        tester,
        open: (context) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => IPv4AddressScreen(
              network: network,
              currentConfig: IPv4ConfigType.automatic,
              ipAddress: '',
              gateway: '',
              onSaved: saved.add,
            ),
          ),
        ),
      );

      expect(find.byType(IPv4AddressScreen), findsOneWidget);
      expect(find.byType(IPv4AddressBottomSheet), findsOneWidget);

      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved.single.configType, IPv4ConfigType.automatic);
      expect(saved.single.subnetMask, '255.255.255.0');
      expect(find.byType(IPv4AddressScreen), findsNothing);
    });
  });
}
