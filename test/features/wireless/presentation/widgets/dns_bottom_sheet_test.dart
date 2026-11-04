import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/dns.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  final saved = <DNSSettingsResult>[];

  setUp(saved.clear);

  final network = tConnectedNetwork.copyWith(
    dnsSearchDomains: ['corp.example.com'],
  );

  Future<void> openSheet(
    WidgetTester tester, {
    DNSConfigType currentConfig = DNSConfigType.automatic,
    List<String> servers = const ['1.1.1.1', '8.8.8.8'],
  }) async {
    useTallSurface(tester);
    await pumpSheetHost(
      tester,
      open: (context) => DNSBottomSheet.show(
        context: context,
        network: network,
        currentConfig: currentConfig,
        servers: servers,
        onSaved: saved.add,
      ),
    );
    expect(find.byType(DNSBottomSheet), findsOneWidget);
  }

  Finder field(int index) => find.byType(MechanixTextField).at(index);

  Finder deleteButton(int index) =>
      findIconButtonWithAsset(SettingIcons.delete).at(index);

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(findCheckButton);
    await tester.pump();
  }

  Future<void> addServer(WidgetTester tester) async {
    await tester.tap(findIconButtonWithAsset(SettingIcons.add));
    await tester.pumpAndSettle();
  }

  group('DNSBottomSheet Widget Tests', () {
    testWidgets('renders header and both options, no servers when automatic', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(DNSBottomSheet));

      expect(find.text(l10n.dns), findsOneWidget);
      expect(findBackButton, findsOneWidget);
      expect(findCheckButton, findsOneWidget);
      expect(find.byKey(const Key('option_dns_automatic')), findsOneWidget);
      expect(find.byKey(const Key('option_dns_manual')), findsOneWidget);
      expect(find.byType(MechanixTextField), findsNothing);
      expect(find.text(l10n.addServer), findsNothing);
    });

    testWidgets('selecting manual lists existing servers and add button', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(DNSBottomSheet));

      await tester.tap(find.byKey(const Key('option_dns_manual')));
      await tester.pumpAndSettle();

      expect(find.byType(MechanixTextField), findsNWidgets(2));
      expect(find.text('1.1.1.1'), findsOneWidget);
      expect(find.text('8.8.8.8'), findsOneWidget);
      expect(findIconButtonWithAsset(SettingIcons.delete), findsNWidgets(2));
      expect(find.text(l10n.addServer), findsOneWidget);
    });

    testWidgets('ignores blank servers and trims the others', (
      WidgetTester tester,
    ) async {
      await openSheet(
        tester,
        currentConfig: DNSConfigType.manual,
        servers: const [' 9.9.9.9 ', '   ', ''],
      );

      expect(find.byType(MechanixTextField), findsOneWidget);
      expect(find.text('9.9.9.9'), findsOneWidget);
    });

    testWidgets('add button and add row both append an empty server', (
      WidgetTester tester,
    ) async {
      await openSheet(
        tester,
        currentConfig: DNSConfigType.manual,
        servers: const [],
      );
      final l10n = l10nOf(tester, find.byType(DNSBottomSheet));

      expect(find.byType(MechanixTextField), findsNothing);

      await addServer(tester);
      expect(find.byType(MechanixTextField), findsOneWidget);

      await tester.tap(find.text(l10n.addServer));
      await tester.pumpAndSettle();
      expect(find.byType(MechanixTextField), findsNWidgets(2));
    });

    testWidgets('delete button removes that server row', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: DNSConfigType.manual);

      await tester.tap(deleteButton(0));
      await tester.pumpAndSettle();

      expect(find.byType(MechanixTextField), findsOneWidget);
      expect(find.text('1.1.1.1'), findsNothing);
      expect(find.text('8.8.8.8'), findsOneWidget);
    });

    testWidgets('switching back to automatic hides the server list', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: DNSConfigType.manual);

      await tester.tap(find.byKey(const Key('option_dns_automatic')));
      await tester.pumpAndSettle();

      expect(find.byType(MechanixTextField), findsNothing);
    });

    testWidgets('saving automatic config keeps servers and search domains', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved, const [
        DNSSettingsResult(
          configType: DNSConfigType.automatic,
          servers: ['1.1.1.1', '8.8.8.8'],
          searchDomains: ['corp.example.com'],
        ),
      ]);
      expect(find.byType(DNSBottomSheet), findsNothing);
    });

    testWidgets('saving a valid manual list drops empty rows and closes', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: DNSConfigType.manual);

      await addServer(tester);
      await tester.enterText(field(2), ' 2606:4700:4700::1111 ');
      await addServer(tester); // left empty on purpose
      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved, const [
        DNSSettingsResult(
          configType: DNSConfigType.manual,
          servers: ['1.1.1.1', '8.8.8.8', '2606:4700:4700::1111'],
          searchDomains: ['corp.example.com'],
        ),
      ]);
      expect(find.byType(DNSBottomSheet), findsNothing);
    });

    testWidgets('back button closes without saving', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: DNSConfigType.manual);

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(saved, isEmpty);
      expect(find.byType(DNSBottomSheet), findsNothing);
    });

    testWidgets('manual with no servers shows "add at least one" error', (
      WidgetTester tester,
    ) async {
      await openSheet(
        tester,
        currentConfig: DNSConfigType.manual,
        servers: const [],
      );
      final l10n = l10nOf(tester, find.byType(DNSBottomSheet));

      await addServer(tester); // an empty row does not count
      await tapSave(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(l10n.pleaseEnterAtLeastOneDnsServer), findsOneWidget);
      expect(saved, isEmpty);
      expect(find.byType(DNSBottomSheet), findsOneWidget);

      await flushSnackbars(tester);
    });

    for (final invalid in const ['dns.server', '127.0.0.53', '0.0.0.0']) {
      testWidgets('manual with invalid server "$invalid" shows error', (
        WidgetTester tester,
      ) async {
        await openSheet(tester, currentConfig: DNSConfigType.manual);
        final l10n = l10nOf(tester, find.byType(DNSBottomSheet));

        await tester.enterText(field(1), invalid);
        await tapSave(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(l10n.invalidDnsServers), findsOneWidget);
        expect(saved, isEmpty);

        await flushSnackbars(tester);
      });
    }

    testWidgets('manual with duplicate servers shows error', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, currentConfig: DNSConfigType.manual);
      final l10n = l10nOf(tester, find.byType(DNSBottomSheet));

      await tester.enterText(field(1), ' 1.1.1.1 ');
      await tapSave(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(l10n.duplicateDnsServers), findsOneWidget);
      expect(saved, isEmpty);

      await flushSnackbars(tester);
    });
  });

  group('DNSScreen Widget Tests', () {
    testWidgets('hosts the sheet content and pops after saving', (
      WidgetTester tester,
    ) async {
      useTallSurface(tester);
      await pumpSheetHost(
        tester,
        open: (context) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DNSScreen(
              network: network,
              currentConfig: DNSConfigType.automatic,
              servers: const [],
              onSaved: saved.add,
            ),
          ),
        ),
      );

      expect(find.byType(DNSScreen), findsOneWidget);
      expect(find.byType(DNSBottomSheet), findsOneWidget);

      await tapSave(tester);
      await tester.pumpAndSettle();

      expect(saved.single.configType, DNSConfigType.automatic);
      expect(saved.single.servers, isEmpty);
      expect(find.byType(DNSScreen), findsNothing);
    });
  });
}
