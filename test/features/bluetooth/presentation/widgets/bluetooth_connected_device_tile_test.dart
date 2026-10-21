import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/widgets/bluetooth_connected_device_tile.dart';
import '../helpers/bluetooth_test_helpers.dart';

void main() {
  group('BluetoothConnectedDeviceTile Widget Tests', () {
    testWidgets('renders device name and connected indicator icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothConnectedDeviceTile(
            device: tConnectedDevice,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tConnectedDevice.name), findsOneWidget);

      final ellipseFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ImageIcon &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == SettingIcons.ellipse,
      );
      expect(ellipseFinder, findsOneWidget);
    });

    testWidgets('renders correct icon for different device types', (
      WidgetTester tester,
    ) async {
      const typesToTest = [
        BluetoothDeviceType.mobile,
        BluetoothDeviceType.speaker,
        BluetoothDeviceType.computer,
        BluetoothDeviceType.car,
        BluetoothDeviceType.tv,
        BluetoothDeviceType.headphones,
        BluetoothDeviceType.unknown,
      ];

      for (final type in typesToTest) {
        final device = BluetoothDevice(
          name: '${type.name} Device',
          deviceName: '${type.name} Device',
          type: type,
          isConnected: true,
        );

        await tester.pumpWidget(
          createTestWidget(
            child: BluetoothConnectedDeviceTile(device: device, onTap: () {}),
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
          child: BluetoothConnectedDeviceTile(
            device: tConnectedDevice,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(tConnectedDevice.name));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows progress indicator and disables tap when connecting', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      final connectingDevice = tConnectedDevice.copyWith(isConnecting: true);

      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothConnectedDeviceTile(
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
      'renders settings icon button and triggers onSettingsTap when saved',
      (WidgetTester tester) async {
        var settingsTapped = false;

        await tester.pumpWidget(
          createTestWidget(
            child: BluetoothConnectedDeviceTile(
              device: tConnectedDevice, // isSaved is true
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

    testWidgets(
      'does not render settings icon button when device is not saved',
      (WidgetTester tester) async {
        final unsavedDevice = tConnectedDevice.copyWith(isSaved: false);

        await tester.pumpWidget(
          createTestWidget(
            child: BluetoothConnectedDeviceTile(
              device: unsavedDevice,
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
      },
    );

    testWidgets('does not render settings button when onSettingsTap is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: BluetoothConnectedDeviceTile(
            device: tConnectedDevice,
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
