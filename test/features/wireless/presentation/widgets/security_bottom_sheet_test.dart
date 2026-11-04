import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/security_bottom_sheet.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/security_selector.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  const supportedOptions = [
    WirelessSecurity.none,
    WirelessSecurity.wep,
    WirelessSecurity.wpaWpa2Personal,
    WirelessSecurity.wpa3Personal,
  ];

  group('SecurityBottomSheet Widget Tests', () {
    late WirelessSecurity? result;
    late bool closed;

    Future<void> openSheet(
      WidgetTester tester, {
      WirelessSecurity current = WirelessSecurity.none,
    }) async {
      result = null;
      closed = false;

      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await SecurityBottomSheet.show(
                    context: context,
                    currentSecurity: current,
                  );
                  closed = true;
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(SecurityBottomSheet), findsOneWidget);
    }

    testWidgets('renders title and one option per supported security', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(SecurityBottomSheet));

      expect(find.text(l10n.security), findsOneWidget);
      expect(findBackButton, findsOneWidget);
      expect(findCheckButton, findsOneWidget);

      for (final option in supportedOptions) {
        expect(
          find.byKey(ValueKey('option_security_${option.name}')),
          findsOneWidget,
        );
        expect(find.text(option.label(l10n)), findsOneWidget);
      }

      expect(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('option_security_'),
        ),
        findsNWidgets(supportedOptions.length),
      );
    });

    testWidgets('confirming without changes returns the current security', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, current: WirelessSecurity.wep);

      await tester.tap(findCheckButton);
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, WirelessSecurity.wep);
    });

    testWidgets('selecting an option and confirming returns it', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.tap(
        find.byKey(const ValueKey('option_security_wpa3Personal')),
      );
      await tester.pump();

      await tester.tap(findCheckButton);
      await tester.pumpAndSettle();

      expect(find.byType(SecurityBottomSheet), findsNothing);
      expect(result, WirelessSecurity.wpa3Personal);
    });

    testWidgets('tapping back closes the sheet and returns null', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.tap(
        find.byKey(const ValueKey('option_security_wpaWpa2Personal')),
      );
      await tester.pump();

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(SecurityBottomSheet), findsNothing);
      expect(closed, isTrue);
      expect(result, isNull);
    });
  });

  group('SecuritySelector Widget Tests', () {
    testWidgets('shows the current security label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: SecuritySelector(
            security: WirelessSecurity.wpa3Personal,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester, find.byType(SecuritySelector));
      expect(find.text(l10n.security), findsOneWidget);
      expect(
        find.text(WirelessSecurity.wpa3Personal.label(l10n)),
        findsOneWidget,
      );
    });

    testWidgets('calls onChanged with the option picked in the sheet', (
      WidgetTester tester,
    ) async {
      WirelessSecurity? changed;

      await tester.pumpWidget(
        createTestWidget(
          child: SecuritySelector(
            security: WirelessSecurity.none,
            onChanged: (value) => changed = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SecuritySelector));
      await tester.pumpAndSettle();
      expect(find.byType(SecurityBottomSheet), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('option_security_wep')));
      await tester.pump();
      await tester.tap(findCheckButton);
      await tester.pumpAndSettle();

      expect(changed, WirelessSecurity.wep);
    });

    testWidgets('does not call onChanged when the sheet is dismissed', (
      WidgetTester tester,
    ) async {
      var called = false;

      await tester.pumpWidget(
        createTestWidget(
          child: SecuritySelector(
            security: WirelessSecurity.none,
            onChanged: (_) => called = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SecuritySelector));
      await tester.pumpAndSettle();

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });
  });

  test('labels of supported options are distinct', () {
    // Guards against two options rendering the same text in the sheet.
    final l10n = lookupAppLocalizations(const Locale('en'));
    final labels = supportedOptions.map((o) => o.label(l10n)).toSet();
    expect(labels.length, supportedOptions.length);
  });
}
