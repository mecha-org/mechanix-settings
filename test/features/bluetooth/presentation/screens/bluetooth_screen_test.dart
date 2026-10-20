import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import '../helpers/bluetooth_test_helpers.dart';

void main() {
  late MockBluetoothBloc mockBluetoothBloc;

  setUpAll(() {
    registerBluetoothFallbackValues();
  });

  setUp(() {
    mockBluetoothBloc = MockBluetoothBloc();
  });

  group('BluetoothScreen Widget Tests', () {
    testWidgets(
      'renders app bar with title and back button, fires initial scan',
      (WidgetTester tester) async {
        when(
          () => mockBluetoothBloc.state,
        ).thenReturn(const BluetoothState(isBluetoothOn: false));

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const BluetoothScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(BluetoothScreen));
        final l10n = AppLocalizations.of(context)!;

        // Verify app bar title
        expect(
          find.descendant(
            of: find.byType(MechanixAppBar),
            matching: find.text(l10n.bluetooth.toUpperCase()),
          ),
          findsOneWidget,
        );

        // Verify back button is present
        final backButton = find.byWidgetPredicate(
          (widget) =>
              widget is MechanixIconButton &&
              widget.icon is ImageIcon &&
              ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                  SettingIcons.back,
        );
        expect(backButton, findsOneWidget);

        // Verify ScanBluetoothDevices was dispatched on post-frame callback
        verify(
          () => mockBluetoothBloc.add(const ScanBluetoothDevices()),
        ).called(1);
      },
    );

    testWidgets(
      'tapping back button dispatches StopBluetoothDiscovery and pops route',
      (WidgetTester tester) async {
        when(
          () => mockBluetoothBloc.state,
        ).thenReturn(const BluetoothState(isBluetoothOn: false));

        final navigatorObserver = MockNavigatorObserver();

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            navigatorObserver: navigatorObserver,
            child: const BluetoothScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final backButton = find.byWidgetPredicate(
          (widget) =>
              widget is MechanixIconButton &&
              widget.icon is ImageIcon &&
              ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                  SettingIcons.back,
        );

        await tester.tap(backButton);
        await tester.pumpAndSettle();

        verify(
          () => mockBluetoothBloc.add(const StopBluetoothDiscovery()),
        ).called(1);
        verify(() => navigatorObserver.didPop(any(), any())).called(1);
      },
    );

    testWidgets('disposing BluetoothScreen dispatches StopBluetoothDiscovery', (
      WidgetTester tester,
    ) async {
      when(
        () => mockBluetoothBloc.state,
      ).thenReturn(const BluetoothState(isBluetoothOn: false));

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const BluetoothScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Replace with a different widget to trigger dispose()
      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => mockBluetoothBloc.add(const StopBluetoothDiscovery()),
      ).called(1);
    });

    testWidgets('shows snackbar on connectionFailed error with device name', (
      WidgetTester tester,
    ) async {
      const initial = BluetoothState(isBluetoothOn: true);
      const withError = BluetoothState(
        isBluetoothOn: true,
        error: BluetoothFailure(
          type: BluetoothErrorType.connectionFailed,
          data: {'deviceName': 'Headphones Pro'},
        ),
      );

      whenListen(
        mockBluetoothBloc,
        Stream.fromIterable([withError]),
        initialState: initial,
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const BluetoothScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final context = tester.element(find.byType(BluetoothScreen));
      final l10n = AppLocalizations.of(context)!;
      final expectedMsg = l10n.bluetoothConnectionFailedWithName(
        'Headphones Pro',
      );

      expect(find.text(expectedMsg), findsOneWidget);
    });

    testWidgets(
      'shows snackbar on connectionFailed error without device name',
      (WidgetTester tester) async {
        const initial = BluetoothState(isBluetoothOn: true);
        const withError = BluetoothState(
          isBluetoothOn: true,
          error: BluetoothFailure(type: BluetoothErrorType.connectionFailed),
        );

        whenListen(
          mockBluetoothBloc,
          Stream.fromIterable([withError]),
          initialState: initial,
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const BluetoothScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final context = tester.element(find.byType(BluetoothScreen));
        final l10n = AppLocalizations.of(context)!;
        final expectedMsg = l10n.bluetoothConnectionFailed;

        expect(find.text(expectedMsg), findsOneWidget);
      },
    );

    testWidgets('shows snackbar on pairingFailed error with device name', (
      WidgetTester tester,
    ) async {
      const initial = BluetoothState(isBluetoothOn: true);
      const withError = BluetoothState(
        isBluetoothOn: true,
        error: BluetoothFailure(
          type: BluetoothErrorType.pairingFailed,
          data: {'deviceName': 'Smart Watch'},
        ),
      );

      whenListen(
        mockBluetoothBloc,
        Stream.fromIterable([withError]),
        initialState: initial,
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const BluetoothScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final context = tester.element(find.byType(BluetoothScreen));
      final l10n = AppLocalizations.of(context)!;
      final expectedMsg = l10n.bluetoothPairingFailedWithName('Smart Watch');

      expect(find.text(expectedMsg), findsOneWidget);
    });

    testWidgets('shows snackbar on pairingFailed error without device name', (
      WidgetTester tester,
    ) async {
      const initial = BluetoothState(isBluetoothOn: true);
      const withError = BluetoothState(
        isBluetoothOn: true,
        error: BluetoothFailure(type: BluetoothErrorType.pairingFailed),
      );

      whenListen(
        mockBluetoothBloc,
        Stream.fromIterable([withError]),
        initialState: initial,
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const BluetoothScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final context = tester.element(find.byType(BluetoothScreen));
      final l10n = AppLocalizations.of(context)!;
      final expectedMsg = l10n.bluetoothPairingFailed;

      expect(find.text(expectedMsg), findsOneWidget);
    });

    testWidgets('shows snackbar on unknown error', (WidgetTester tester) async {
      const initial = BluetoothState(isBluetoothOn: true);
      const withError = BluetoothState(
        isBluetoothOn: true,
        error: BluetoothFailure(type: BluetoothErrorType.unknown),
      );

      whenListen(
        mockBluetoothBloc,
        Stream.fromIterable([withError]),
        initialState: initial,
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const BluetoothScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final context = tester.element(find.byType(BluetoothScreen));
      final l10n = AppLocalizations.of(context)!;
      final expectedMsg = l10n.unknownError;

      expect(find.text(expectedMsg), findsOneWidget);
    });
  });
}
