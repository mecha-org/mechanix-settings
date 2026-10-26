import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/add_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/security_bottom_sheet.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/add_network/security_selector.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  late MockWirelessBloc mockWirelessBloc;

  setUpAll(() {
    registerWirelessFallbackValues();
  });

  setUp(() {
    mockWirelessBloc = MockWirelessBloc();
    when(
      () => mockWirelessBloc.state,
    ).thenReturn(const WirelessState(isWirelessOn: true));
  });

  Future<void> pumpAddNetworkPage(WidgetTester tester) async {
    await tester.pumpWidget(
      createWirelessLauncherWidget(
        wirelessBloc: mockWirelessBloc,
        screenBuilder: (_) => const AddNetworkPage(),
      ),
    );
    await openScreenUnderTest(tester);
    expect(find.byType(AddNetworkPage), findsOneWidget);
  }

  /// The confirm (check) button in the page app bar.
  Finder pageCheckButton() => find.descendant(
    of: find.byType(MechanixAppBar),
    matching: findCheckButton,
  );

  Future<void> selectSecurity(
    WidgetTester tester,
    WirelessSecurity security,
  ) async {
    await tester.tap(find.byType(SecuritySelector));
    await tester.pumpAndSettle();
    expect(find.byType(SecurityBottomSheet), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('option_security_${security.name}')));
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(SecurityBottomSheet),
        matching: findCheckButton,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SecurityBottomSheet), findsNothing);
  }

  group('AddNetworkPage Widget Tests', () {
    testWidgets(
      'renders title, back and check buttons, name field and security None',
      (WidgetTester tester) async {
        await pumpAddNetworkPage(tester);

        final l10n = l10nOf(tester, find.byType(AddNetworkPage));

        expect(
          find.descendant(
            of: find.byType(MechanixAppBar),
            matching: find.text(l10n.joinNetworkTitle),
          ),
          findsOneWidget,
        );
        expect(findBackButton, findsOneWidget);
        expect(pageCheckButton(), findsOneWidget);

        // Only the network name field is shown for open networks.
        expect(find.byType(MechanixTextField), findsOneWidget);
        expect(find.text(l10n.networkName), findsOneWidget);

        expect(find.byType(SecuritySelector), findsOneWidget);
        expect(find.text(l10n.security), findsOneWidget);
        expect(find.text(WirelessSecurity.none.label(l10n)), findsOneWidget);
      },
    );

    testWidgets('tapping back pops the page without dispatching events', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(AddNetworkPage), findsNothing);
      verifyNever(() => mockWirelessBloc.add(any()));
    });

    testWidgets('shows name required error and stays open when name is empty', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      final l10n = l10nOf(tester, find.byType(AddNetworkPage));

      await tester.tap(pageCheckButton());
      await tester.pumpAndSettle();

      expect(find.text(l10n.networkNameRequired), findsOneWidget);
      expect(find.byType(AddNetworkPage), findsOneWidget);
      verifyNever(
        () => mockWirelessBloc.add(any(that: isA<AddNetworkEvent>())),
      );
    });

    testWidgets('clears name error once the user types', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      final l10n = l10nOf(tester, find.byType(AddNetworkPage));

      await tester.tap(pageCheckButton());
      await tester.pumpAndSettle();
      expect(find.text(l10n.networkNameRequired), findsOneWidget);

      await tester.enterText(find.byType(MechanixTextField), 'G');
      await tester.pumpAndSettle();

      expect(find.text(l10n.networkNameRequired), findsNothing);
    });

    testWidgets(
      'dispatches AddNetworkEvent for an open network with trimmed name and pops',
      (WidgetTester tester) async {
        await pumpAddNetworkPage(tester);

        await tester.enterText(find.byType(MechanixTextField), '  GuestWifi  ');
        await tester.pump();

        await tester.tap(pageCheckButton());
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            const AddNetworkEvent('GuestWifi', WirelessSecurity.none),
          ),
        ).called(1);
        expect(find.byType(AddNetworkPage), findsNothing);
      },
    );

    testWidgets('security sheet lists only personal security options', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);

      await tester.tap(find.byType(SecuritySelector));
      await tester.pumpAndSettle();

      for (final security in const [
        WirelessSecurity.none,
        WirelessSecurity.wep,
        WirelessSecurity.wpaWpa2Personal,
        WirelessSecurity.wpa3Personal,
      ]) {
        expect(
          find.byKey(ValueKey('option_security_${security.name}')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('option_security_enhancedOpen')),
        findsNothing,
      );
    });

    testWidgets(
      'closing the security sheet with back keeps the current security',
      (WidgetTester tester) async {
        await pumpAddNetworkPage(tester);
        final l10n = l10nOf(tester, find.byType(AddNetworkPage));

        await tester.tap(find.byType(SecuritySelector));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('option_security_wpaWpa2Personal')),
        );
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: find.byType(SecurityBottomSheet),
            matching: findBackButton,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SecurityBottomSheet), findsNothing);
        expect(find.text(WirelessSecurity.none.label(l10n)), findsOneWidget);
        expect(find.byType(MechanixTextField), findsOneWidget);
      },
    );

    testWidgets('selecting WPA/WPA2 shows the password field', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      final l10n = l10nOf(tester, find.byType(AddNetworkPage));

      await selectSecurity(tester, WirelessSecurity.wpaWpa2Personal);

      expect(
        find.text(WirelessSecurity.wpaWpa2Personal.label(l10n)),
        findsOneWidget,
      );
      expect(find.byType(MechanixTextField), findsNWidgets(2));
      expect(find.text(l10n.password), findsOneWidget);
    });

    testWidgets('shows password required error for WPA/WPA2 without password', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      final l10n = l10nOf(tester, find.byType(AddNetworkPage));

      await selectSecurity(tester, WirelessSecurity.wpaWpa2Personal);

      await tester.enterText(find.byType(MechanixTextField).at(0), 'HomeWifi');
      await tester.tap(pageCheckButton());
      await tester.pumpAndSettle();

      expect(find.text(l10n.passwordRequired), findsOneWidget);
      expect(find.byType(AddNetworkPage), findsOneWidget);
      verifyNever(
        () => mockWirelessBloc.add(any(that: isA<AddNetworkEvent>())),
      );
    });

    testWidgets('shows invalid WPA password error for short passwords', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      final l10n = l10nOf(tester, find.byType(AddNetworkPage));

      await selectSecurity(tester, WirelessSecurity.wpaWpa2Personal);

      await tester.enterText(find.byType(MechanixTextField).at(0), 'HomeWifi');
      await tester.enterText(find.byType(MechanixTextField).at(1), 'short');
      await tester.tap(pageCheckButton());
      await tester.pumpAndSettle();

      expect(find.text(l10n.invalidWpaPassword), findsOneWidget);
      verifyNever(
        () => mockWirelessBloc.add(any(that: isA<AddNetworkEvent>())),
      );
    });

    testWidgets('shows invalid WEP key error for wrong length keys', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      final l10n = l10nOf(tester, find.byType(AddNetworkPage));

      await selectSecurity(tester, WirelessSecurity.wep);

      await tester.enterText(find.byType(MechanixTextField).at(0), 'OldRouter');
      await tester.enterText(find.byType(MechanixTextField).at(1), 'abcdef');
      await tester.tap(pageCheckButton());
      await tester.pumpAndSettle();

      expect(find.text(l10n.invalidWepPassword), findsOneWidget);
      verifyNever(
        () => mockWirelessBloc.add(any(that: isA<AddNetworkEvent>())),
      );
    });

    testWidgets(
      'dispatches AddNetworkEvent with password for WPA/WPA2 and pops',
      (WidgetTester tester) async {
        await pumpAddNetworkPage(tester);

        await selectSecurity(tester, WirelessSecurity.wpaWpa2Personal);

        await tester.enterText(
          find.byType(MechanixTextField).at(0),
          'HomeWifi',
        );
        await tester.enterText(
          find.byType(MechanixTextField).at(1),
          'password123',
        );
        await tester.tap(pageCheckButton());
        await tester.pumpAndSettle();

        verify(
          () => mockWirelessBloc.add(
            const AddNetworkEvent(
              'HomeWifi',
              WirelessSecurity.wpaWpa2Personal,
              password: 'password123',
            ),
          ),
        ).called(1);
        expect(find.byType(AddNetworkPage), findsNothing);
      },
    );

    testWidgets('dispatches AddNetworkEvent with a valid WEP key', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);

      await selectSecurity(tester, WirelessSecurity.wep);

      await tester.enterText(find.byType(MechanixTextField).at(0), 'OldRouter');
      await tester.enterText(find.byType(MechanixTextField).at(1), 'abcde');
      await tester.tap(pageCheckButton());
      await tester.pumpAndSettle();

      verify(
        () => mockWirelessBloc.add(
          const AddNetworkEvent(
            'OldRouter',
            WirelessSecurity.wep,
            password: 'abcde',
          ),
        ),
      ).called(1);
    });

    testWidgets('switching back to None hides the password field', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);

      await selectSecurity(tester, WirelessSecurity.wpa3Personal);
      expect(find.byType(MechanixTextField), findsNWidgets(2));

      await selectSecurity(tester, WirelessSecurity.none);
      expect(find.byType(MechanixTextField), findsOneWidget);
    });
    testWidgets('tapping the caret button also opens the security sheet', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(SecuritySelector),
          matching: findIconButtonWithAsset(SettingIcons.caretRight),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SecurityBottomSheet), findsOneWidget);
    });

    testWidgets('password visibility can be toggled', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      await selectSecurity(tester, WirelessSecurity.wpaWpa2Personal);

      TextField passwordField() => tester.widget<TextField>(
        find.descendant(
          of: find.byType(MechanixTextField).at(1),
          matching: find.byType(TextField),
        ),
      );

      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(passwordField().obscureText, isFalse);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(passwordField().obscureText, isTrue);
    });

    testWidgets('typing a password clears the password error', (
      WidgetTester tester,
    ) async {
      await pumpAddNetworkPage(tester);
      final l10n = l10nOf(tester, find.byType(AddNetworkPage));

      await selectSecurity(tester, WirelessSecurity.wpaWpa2Personal);
      await tester.enterText(find.byType(MechanixTextField).at(0), 'HomeWifi');
      await tester.tap(pageCheckButton());
      await tester.pumpAndSettle();
      expect(find.text(l10n.passwordRequired), findsOneWidget);

      await tester.enterText(find.byType(MechanixTextField).at(1), 'p');
      await tester.pumpAndSettle();

      expect(find.text(l10n.passwordRequired), findsNothing);
    });
  });
}
