import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_list_item.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wifi_signal_icon.dart';
import '../helpers/wireless_test_helpers.dart';

void main() {
  group('NetworkListItem Widget Tests', () {
    testWidgets('renders name, subtitle and signal icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: NetworkListItem(
            name: 'OfficeWifi 1',
            subtitle: 'No Internet Connection',
            signalType: WifiSignalType.highLocked,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OfficeWifi 1'), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);

      final signalIcon = tester.widget<WifiSignalIcon>(
        find.byType(WifiSignalIcon),
      );
      expect(signalIcon.type, WifiSignalType.highLocked);
    });

    testWidgets('does not render an empty subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: NetworkListItem(
            name: 'OfficeWifi 1',
            subtitle: '',
            signalType: WifiSignalType.mediumOpen,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tile = tester.widget<MechanixListTile>(
        find.byType(MechanixListTile),
      );
      expect(tile.supportingText, isNull);
    });

    testWidgets('renders the matching signal icon for every signal type', (
      WidgetTester tester,
    ) async {
      for (final type in WifiSignalType.values) {
        await tester.pumpWidget(
          createTestWidget(
            child: NetworkListItem(
              name: '${type.name} network',
              signalType: type,
              onTap: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.widget<WifiSignalIcon>(find.byType(WifiSignalIcon)).type,
          type,
        );
      }
    });

    testWidgets('shows connected indicator only when connected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: NetworkListItem(
            name: 'OfficeWifi 1',
            isConnected: true,
            signalType: WifiSignalType.highLocked,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findImageIconWithAsset(SettingIcons.ellipse), findsOneWidget);

      await tester.pumpWidget(
        createTestWidget(
          child: NetworkListItem(
            name: 'OfficeWifi 1',
            signalType: WifiSignalType.highLocked,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findImageIconWithAsset(SettingIcons.ellipse), findsNothing);
    });

    testWidgets('triggers onTap when tapped', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          child: NetworkListItem(
            name: 'OfficeWifi 1',
            signalType: WifiSignalType.highLocked,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('OfficeWifi 1'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'shows progress indicator instead of signal icon and disables tap when connecting',
      (WidgetTester tester) async {
        var tapped = false;

        await tester.pumpWidget(
          createTestWidget(
            child: NetworkListItem(
              name: 'OfficeWifi 1',
              isConnecting: true,
              signalType: WifiSignalType.highLocked,
              onTap: () => tapped = true,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(WifiSignalIcon), findsNothing);

        await tester.tap(find.text('OfficeWifi 1'));
        await tester.pump();

        expect(tapped, isFalse);
      },
    );

    testWidgets('renders gear button and triggers onSettingsTap', (
      WidgetTester tester,
    ) async {
      var settingsTapped = false;
      var tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          child: NetworkListItem(
            name: 'OfficeWifi 1',
            signalType: WifiSignalType.highLocked,
            onTap: () => tapped = true,
            onSettingsTap: () => settingsTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gear = findIconButtonWithAsset(SettingIcons.setting);
      expect(gear, findsOneWidget);

      await tester.tap(gear);
      await tester.pump();

      expect(settingsTapped, isTrue);
      expect(tapped, isFalse);
    });

    testWidgets('does not render gear button when onSettingsTap is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          child: NetworkListItem(
            name: 'OfficeWifi 1',
            signalType: WifiSignalType.highLocked,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findIconButtonWithAsset(SettingIcons.setting), findsNothing);
    });
  });
}
