import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_device_list_item.dart';
import '../helpers/bluetooth_test_helpers.dart';

void main() {
  group('BluetoothDeviceListItem Widget Tests', () {
    testWidgets('renders device name and device type icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothDeviceListItem(device: tPairedDevice, onTap: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tPairedDevice.name), findsOneWidget);

      final iconFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ImageIcon &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == tPairedDevice.type.icon,
      );
      expect(iconFinder, findsOneWidget);

      // Verify connected ellipse indicator is NOT present
      final ellipseFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ImageIcon &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == SettingIcons.ellipse,
      );
      expect(ellipseFinder, findsNothing);
    });

    testWidgets('renders correct icons for all device types', (
      WidgetTester tester,
    ) async {
      const types = [
        BluetoothDeviceType.mobile,
        BluetoothDeviceType.speaker,
        BluetoothDeviceType.computer,
        BluetoothDeviceType.car,
        BluetoothDeviceType.tv,
        BluetoothDeviceType.headphones,
        BluetoothDeviceType.unknown,
      ];

      for (final type in types) {
        final device = BluetoothDevice(
          name: '${type.name} Item',
          deviceName: '${type.name} Item',
          type: type,
        );

        await tester.pumpWidget(
          createTestWidget(
            child: BluetoothDeviceListItem(device: device, onTap: () {}),
          ),
        );
        await tester.pumpAndSettle();

        final iconFinder = find.byWidgetPredicate(
          (widget) =>
              widget is ImageIcon &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == type.icon,
        );
        expect(iconFinder, findsOneWidget);
      }
    });

    testWidgets('triggers onTap callback when tapped in normal state', (
      WidgetTester tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothDeviceListItem(
            device: tPairedDevice,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(tPairedDevice.name));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows progress indicator and disables tap when connecting', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      final connectingDevice = tPairedDevice.copyWith(isConnecting: true);

      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothDeviceListItem(
            device: connectingDevice,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text(connectingDevice.name));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets(
      'renders settings icon button and triggers callback when saved',
      (WidgetTester tester) async {
        var settingsTapped = false;

        await tester.pumpWidget(
          createTestWidget(
            child: BluetoothDeviceListItem(
              device: tPairedDevice, // isSaved is true
              onTap: () {},
              onSettingsTap: () {
                settingsTapped = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final settingsButtonFinder = find.byWidgetPredicate(
          (widget) =>
              widget is MechanixIconButton &&
              widget.icon is ImageIcon &&
              ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                  SettingIcons.setting,
        );
        expect(settingsButtonFinder, findsOneWidget);

        await tester.tap(settingsButtonFinder);
        await tester.pump();

        expect(settingsTapped, isTrue);
      },
    );

    testWidgets('does not render settings icon button when not saved', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothDeviceListItem(
            device: tDiscoveredDevice, // isSaved is false
            onTap: () {},
            onSettingsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final settingsButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is ImageIcon &&
            ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                SettingIcons.setting,
      );
      expect(settingsButtonFinder, findsNothing);
    });

    testWidgets('does not render settings button when onSettingsTap is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothDeviceListItem(
            device: tPairedDevice,
            onTap: () {},
            onSettingsTap: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final settingsButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is MechanixIconButton &&
            widget.icon is ImageIcon &&
            ((widget.icon as ImageIcon).image as AssetImage).assetName ==
                SettingIcons.setting,
      );
      expect(settingsButtonFinder, findsNothing);
    });
  });
}
