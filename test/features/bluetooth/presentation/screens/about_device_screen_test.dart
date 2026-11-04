import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/about_device_screen.dart';
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

  group('AboutDeviceScreen Widget Tests', () {
    testWidgets('renders all device info and handles back button', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          localDeviceName: 'My Comet Device',
          isDiscoverable: false,
        ),
      );

      final navigatorObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          navigatorObserver: navigatorObserver,
          child: const AboutDeviceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AboutDeviceScreen));
      final l10n = AppLocalizations.of(context)!;

      // Title
      expect(find.text(l10n.aboutDevice), findsOneWidget);

      // Device Name
      expect(find.text(l10n.deviceName), findsOneWidget);
      expect(find.text('My Comet Device'), findsOneWidget);

      // Device Type
      expect(find.text(l10n.deviceType), findsOneWidget);
      expect(find.text(l10n.cometType.toUpperCase()), findsOneWidget);

      // Discoverable
      expect(find.text(l10n.deviceDiscoverable), findsOneWidget);
      final switchFinder = find.byType(MechanixSwitch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<MechanixSwitch>(switchFinder).value, isFalse);

      // Back button
      final backButton = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is ImageIcon &&
            ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                SettingIcons.back,
      );
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      verify(() => navigatorObserver.didPop(any(), any())).called(1);
    });

    testWidgets(
      'toggling discoverable switch dispatches ToggleBluetoothDiscoverable',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            localDeviceName: 'My Comet Device',
            isDiscoverable: false,
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const AboutDeviceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final switchFinder = find.byType(MechanixSwitch);
        await tester.tap(switchFinder);
        await tester.pump();

        verify(
          () => mockBluetoothBloc.add(const ToggleBluetoothDiscoverable(true)),
        ).called(1);
      },
    );

    testWidgets(
      'tapping discoverable tile dispatches inverted ToggleBluetoothDiscoverable',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(
            isBluetoothOn: true,
            localDeviceName: 'My Comet Device',
            isDiscoverable: true,
          ),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const AboutDeviceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(AboutDeviceScreen));
        final l10n = AppLocalizations.of(context)!;

        await tester.tap(find.text(l10n.deviceDiscoverable));
        await tester.pump();

        verify(
          () => mockBluetoothBloc.add(const ToggleBluetoothDiscoverable(false)),
        ).called(1);
      },
    );

    testWidgets('tapping edit button opens bottom sheet and renames device', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(
          isBluetoothOn: true,
          localDeviceName: 'Old Device Name',
        ),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const AboutDeviceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find edit button (which uses Image.asset SettingIcons.edit)
      final editButton = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is Image &&
            ((widget.icon as Image).image as AssetImage).assetName ==
                SettingIcons.edit,
      );
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Check bottom sheet text field is present with initial name
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      expect(
        tester.widget<TextField>(textFieldFinder).controller?.text,
        'Old Device Name',
      );

      // Enter new valid device name
      await tester.enterText(textFieldFinder, 'New Comet');
      await tester.pump();

      // Tap check button in sheet
      final checkButton = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is ImageIcon &&
            ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                SettingIcons.check,
      );
      expect(checkButton, findsOneWidget);

      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      verify(
        () => mockBluetoothBloc.add(const RenameLocalDeviceEvent('New Comet')),
      ).called(1);

      // Bottom sheet should be dismissed
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
      'bottom sheet shows error and disables check button when name exceeds 30 characters',
      (WidgetTester tester) async {
        when(() => mockBluetoothBloc.state).thenReturn(
          const BluetoothState(isBluetoothOn: true, localDeviceName: 'Comet'),
        );

        await tester.pumpWidget(
          createBluetoothTestWidget(
            bluetoothBloc: mockBluetoothBloc,
            child: const AboutDeviceScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(AboutDeviceScreen));
        final l10n = AppLocalizations.of(context)!;

        // Tap device name tile to open bottom sheet
        await tester.tap(find.text(l10n.deviceName));
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);

        // Enter name longer than 30 characters
        const longName =
            'This name is definitely way more than thirty characters long';
        await tester.enterText(textFieldFinder, longName);
        await tester.pump();

        // Verify error text is displayed
        expect(find.text(l10n.deviceNameLimit), findsOneWidget);

        // Find check button - its onPressed should be null
        final checkButton = find.byWidgetPredicate(
          (widget) =>
              widget is MechanixIconButton &&
              widget.icon is ImageIcon &&
              ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                  SettingIcons.check,
        );
        expect(checkButton, findsOneWidget);
        expect(
          tester.widget<MechanixIconButton>(checkButton).onPressed,
          isNull,
        );
      },
    );

    testWidgets('bottom sheet disables check button when name is empty', (
      WidgetTester tester,
    ) async {
      when(() => mockBluetoothBloc.state).thenReturn(
        const BluetoothState(isBluetoothOn: true, localDeviceName: 'Comet'),
      );

      await tester.pumpWidget(
        createBluetoothTestWidget(
          bluetoothBloc: mockBluetoothBloc,
          child: const AboutDeviceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(AboutDeviceScreen));
      final l10n = AppLocalizations.of(context)!;

      await tester.tap(find.text(l10n.deviceName));
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '   ');
      await tester.pump();

      final checkButton = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is ImageIcon &&
            ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                SettingIcons.check,
      );
      expect(tester.widget<MechanixIconButton>(checkButton).onPressed, isNull);
    });
  });
}
