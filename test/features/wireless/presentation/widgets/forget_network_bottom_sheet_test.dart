import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/forget_network_bottom_sheet.dart';
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

  group('showForgetNetworkBottomSheet Widget Tests', () {
    late int confirmedCount;
    late bool closed;

    Future<void> openSheet(WidgetTester tester) async {
      confirmedCount = 0;
      closed = false;

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    await showForgetNetworkBottomSheet(
                      context: context,
                      network: tSavedNetwork,
                      onConfirmed: () => confirmedCount++,
                    );
                    closed = true;
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders prompt with network name and both buttons', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.text('Open'));

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
      expect(find.text(l10n.close.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.forget.toUpperCase()), findsOneWidget);
    });

    testWidgets(
      'forget button closes sheet, dispatches ForgetNetworkEvent and calls onConfirmed',
      (WidgetTester tester) async {
        await openSheet(tester);
        final l10n = l10nOf(tester, find.text('Open'));

        await tester.tap(find.byKey(const Key('delete_network_delete_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(l10n.forgetWifiPrompt(tSavedNetwork.name)),
          findsNothing,
        );
        expect(closed, isTrue);
        expect(confirmedCount, 1);
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
      },
    );

    testWidgets('close button dismisses without forgetting', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      final l10n = l10nOf(tester, find.text('Open'));

      await tester.tap(find.byKey(const Key('delete_network_cancel_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.forgetWifiPrompt(tSavedNetwork.name)),
        findsNothing,
      );
      expect(closed, isTrue);
      expect(confirmedCount, 0);
      verifyNever(() => mockWirelessBloc.add(any()));
    });
  });
}
