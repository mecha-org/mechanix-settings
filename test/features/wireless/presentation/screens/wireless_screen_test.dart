import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/wireless.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless/wireless_body.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  late MockWirelessBloc mockWirelessBloc;

  setUpAll(() {
    registerWirelessFallbackValues();
  });

  setUp(() {
    mockWirelessBloc = MockWirelessBloc();
  });

  Future<void> pumpWithError(
    WidgetTester tester,
    WirelessFailure failure,
  ) async {
    const initial = WirelessState(isWirelessOn: true);

    whenListen(
      mockWirelessBloc,
      Stream.fromIterable([WirelessState(isWirelessOn: true, error: failure)]),
      initialState: initial,
    );

    await tester.pumpWidget(
      createWirelessTestWidget(
        wirelessBloc: mockWirelessBloc,
        child: const WirelessScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('WirelessScreen Widget Tests', () {
    testWidgets('renders app bar with uppercase title, back button and body', (
      WidgetTester tester,
    ) async {
      when(
        () => mockWirelessBloc.state,
      ).thenReturn(const WirelessState(isWirelessOn: false));

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const WirelessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = l10nOf(tester, find.byType(WirelessScreen));

      expect(
        find.descendant(
          of: find.byType(MechanixAppBar),
          matching: find.text(l10n.wireless.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(findBackButton, findsOneWidget);
      expect(find.byType(WirelessBody), findsOneWidget);
    });

    testWidgets('tapping back button pops the screen', (
      WidgetTester tester,
    ) async {
      when(
        () => mockWirelessBloc.state,
      ).thenReturn(const WirelessState(isWirelessOn: false));

      final navigatorObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        createWirelessLauncherWidget(
          wirelessBloc: mockWirelessBloc,
          navigatorObserver: navigatorObserver,
          screenBuilder: (_) => const WirelessScreen(),
        ),
      );
      await openScreenUnderTest(tester);
      expect(find.byType(WirelessScreen), findsOneWidget);

      await tester.tap(findBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(WirelessScreen), findsNothing);
      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });

    testWidgets('shows snackbar on connectionFailed error with network name', (
      WidgetTester tester,
    ) async {
      await pumpWithError(
        tester,
        const WirelessFailure(
          type: WirelessErrorType.connectionFailed,
          data: {'networkName': 'OfficeWifi 3'},
        ),
      );

      final l10n = l10nOf(tester, find.byType(WirelessScreen));
      expect(
        find.text(l10n.connectionFailedWithNetwork('OfficeWifi 3')),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows snackbar on connectionFailed error without network name',
      (WidgetTester tester) async {
        await pumpWithError(
          tester,
          const WirelessFailure(type: WirelessErrorType.connectionFailed),
        );

        final l10n = l10nOf(tester, find.byType(WirelessScreen));
        expect(find.text(l10n.connectionFailed), findsOneWidget);
      },
    );

    testWidgets('shows snackbar on addNetworkFailed error with network name', (
      WidgetTester tester,
    ) async {
      await pumpWithError(
        tester,
        const WirelessFailure(
          type: WirelessErrorType.addNetworkFailed,
          data: {'networkName': 'HiddenWifi'},
        ),
      );

      final l10n = l10nOf(tester, find.byType(WirelessScreen));
      expect(
        find.text(l10n.addNetworkFailedWithNetwork('HiddenWifi')),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows snackbar on addNetworkFailed error without network name',
      (WidgetTester tester) async {
        await pumpWithError(
          tester,
          const WirelessFailure(type: WirelessErrorType.addNetworkFailed),
        );

        final l10n = l10nOf(tester, find.byType(WirelessScreen));
        expect(find.text(l10n.addNetworkFailed), findsOneWidget);
      },
    );

    testWidgets('shows snackbar on unknown error', (WidgetTester tester) async {
      await pumpWithError(
        tester,
        const WirelessFailure(type: WirelessErrorType.unknown),
      );

      final l10n = l10nOf(tester, find.byType(WirelessScreen));
      expect(find.text(l10n.unknownError), findsOneWidget);
    });

    testWidgets('does not show a snackbar when state has no error', (
      WidgetTester tester,
    ) async {
      whenListen(
        mockWirelessBloc,
        Stream.fromIterable([
          const WirelessState(isWirelessOn: true, isScanning: true),
        ]),
        initialState: const WirelessState(isWirelessOn: true),
      );

      await tester.pumpWidget(
        createWirelessTestWidget(
          wirelessBloc: mockWirelessBloc,
          child: const WirelessScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final l10n = l10nOf(tester, find.byType(WirelessScreen));
      expect(find.text(l10n.unknownError), findsNothing);
      expect(find.text(l10n.connectionFailed), findsNothing);
      expect(find.text(l10n.addNetworkFailed), findsNothing);
    });
  });
}
