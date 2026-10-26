import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_password.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  group('WirelessPasswordBottomSheet Widget Tests', () {
    late WirelessPasswordResult? result;
    late bool closed;

    Future<void> openSheet(
      WidgetTester tester, {
      String networkName = 'OfficeWifi 3',
      String? security = 'WPA & WPA2 Personal',
      WirelessSecurity? securityType,
      bool initialAutoConnect = true,
    }) async {
      result = null;
      closed = false;

      await tester.pumpWidget(
        createTestWidget(
          child: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showPasswordBottomSheet(
                    context,
                    networkName,
                    security: security,
                    securityType: securityType,
                    initialAutoConnect: initialAutoConnect,
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
      expect(find.byType(WirelessPasswordBottomSheet), findsOneWidget);
    }

    MechanixIconButton checkButton(WidgetTester tester) {
      return tester.widget<MechanixIconButton>(findCheckButton);
    }

    TextField passwordField(WidgetTester tester) {
      return tester.widget<TextField>(
        find.descendant(
          of: find.byType(MechanixTextField),
          matching: find.byType(TextField),
        ),
      );
    }

    testWidgets(
      'renders network name, password hint, security and auto-connect',
      (WidgetTester tester) async {
        await openSheet(tester);
        final l10n = l10nOf(tester, find.byType(WirelessPasswordBottomSheet));

        expect(find.text('OfficeWifi 3'), findsOneWidget);
        expect(find.text(l10n.enterPassword), findsOneWidget);
        expect(find.text(l10n.security), findsOneWidget);
        expect(find.text('WPA & WPA2 Personal'), findsOneWidget);
        expect(find.text(l10n.connectAutomatically), findsOneWidget);
        expect(findBackButton, findsOneWidget);
        expect(findCheckButton, findsOneWidget);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      },
    );

    testWidgets('shows a dash when no security label is given', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, security: null);

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('respects initialAutoConnect = false', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, initialAutoConnect: false);

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    });

    testWidgets('password is obscured by default and can be revealed', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      expect(passwordField(tester).obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(passwordField(tester).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('check button is disabled until password is valid', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      expect(checkButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(MechanixTextField), 'short');
      await tester.pump();
      expect(checkButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(MechanixTextField), 'longenough');
      await tester.pump();
      expect(checkButton(tester).onPressed, isNotNull);
    });

    testWidgets('accepts WEP keys when securityType is WEP', (
      WidgetTester tester,
    ) async {
      await openSheet(
        tester,
        security: 'WEP',
        securityType: WirelessSecurity.wep,
      );

      await tester.enterText(find.byType(MechanixTextField), 'abcde');
      await tester.pump();
      expect(checkButton(tester).onPressed, isNotNull);

      await tester.enterText(find.byType(MechanixTextField), 'abcdef');
      await tester.pump();
      expect(checkButton(tester).onPressed, isNull);
    });

    testWidgets('tapping check returns the password with auto-connect on', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(find.byType(MechanixTextField), 'secretpass123');
      await tester.pump();

      await tester.tap(findCheckButton);
      await tester.pumpAndSettle();

      expect(find.byType(WirelessPasswordBottomSheet), findsNothing);
      expect(closed, isTrue);
      expect(
        result,
        const WirelessPasswordResult(
          password: 'secretpass123',
          connectAutomatically: true,
        ),
      );
    });

    testWidgets('unchecking auto-connect is reflected in the result', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.byType(WirelessPasswordBottomSheet));

      await tester.tap(find.text(l10n.connectAutomatically));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      await tester.enterText(find.byType(MechanixTextField), 'secretpass123');
      await tester.pump();
      await tester.tap(findCheckButton);
      await tester.pumpAndSettle();

      expect(
        result,
        const WirelessPasswordResult(
          password: 'secretpass123',
          connectAutomatically: false,
        ),
      );
    });

    testWidgets('submitting a valid password from the keyboard connects', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(find.byType(MechanixTextField), 'secretpass123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(result?.password, 'secretpass123');
    });

    testWidgets('submitting an invalid password keeps the sheet open', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(find.byType(MechanixTextField), 'short');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(WirelessPasswordBottomSheet), findsOneWidget);
      expect(closed, isFalse);
    });

    testWidgets('tapping back closes the sheet and returns null', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(find.byType(MechanixTextField), 'secretpass123');
      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(WirelessPasswordBottomSheet), findsNothing);
      expect(closed, isTrue);
      expect(result, isNull);
    });
  });
}
