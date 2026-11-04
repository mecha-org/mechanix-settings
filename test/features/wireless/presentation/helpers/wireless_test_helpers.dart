import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class MockWirelessBloc extends MockBloc<WirelessEvent, WirelessState>
    implements WirelessBloc {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

class FakeWirelessEvent extends Fake implements WirelessEvent {}

void registerWirelessFallbackValues() {
  registerFallbackValue(FakeRoute());
  registerFallbackValue(FakeWirelessEvent());
  registerFallbackValue(const WifiNetwork(name: 'Fallback Network'));
}

/// Key of the button used by [createWirelessLauncherWidget] to push the
/// screen under test, so that tests can verify the screen pops itself.
const kOpenScreenButtonKey = ValueKey('open_screen_under_test');

const tConnectedNetwork = WifiNetwork(
  name: 'OfficeWifi 1',
  password: 'secretpass',
  isConnected: true,
  isSecured: true,
  signalLevel: 3,
  rawSignalStrength: 85,
  speedMbps: 300,
  frequency: 5180,
  security: WirelessSecurity.wpaWpa2Personal,
  autoJoin: true,
  lowDataMode: false,
  wirelessAddress: 'AA:BB:CC:DD:EE:FF',
);

const tSavedNetwork = WifiNetwork(
  name: 'OfficeWifi 2',
  password: 'anotherpass',
  isConnected: false,
  isSecured: true,
  signalLevel: 2,
  rawSignalStrength: 50,
  security: WirelessSecurity.wpaWpa2Personal,
);

const tSecuredAvailableNetwork = WifiNetwork(
  name: 'OfficeWifi 3',
  isConnected: false,
  isSecured: true,
  signalLevel: 2,
  security: WirelessSecurity.wpaWpa2Personal,
);

const tOpenAvailableNetwork = WifiNetwork(
  name: 'OfficeWifi 4',
  isConnected: false,
  isSecured: false,
  signalLevel: 1,
  security: WirelessSecurity.none,
);

/// Wraps [child] in the app theme, localizations and a [WirelessBloc] provider
/// that is visible to every route (including bottom sheets and pushed screens).
Widget createWirelessTestWidget({
  required Widget child,
  required WirelessBloc wirelessBloc,
  NavigatorObserver? navigatorObserver,
  ThemeData? theme,
}) {
  return MechanixTheme(
    builder: (context, mechanixTheme, _) {
      return MaterialApp(
        theme: theme ?? mechanixTheme.dark,
        navigatorObservers: [?navigatorObserver],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, navigatorChild) {
          return BlocProvider<WirelessBloc>.value(
            value: wirelessBloc,
            child: navigatorChild!,
          );
        },
        home: child,
      );
    },
  );
}

/// Same as [createWirelessTestWidget], but the home route only contains a
/// button that pushes the screen built by [screenBuilder]. Use this when the
/// test needs to verify that the screen pops itself.
Widget createWirelessLauncherWidget({
  required WidgetBuilder screenBuilder,
  required WirelessBloc wirelessBloc,
  NavigatorObserver? navigatorObserver,
}) {
  return createWirelessTestWidget(
    wirelessBloc: wirelessBloc,
    navigatorObserver: navigatorObserver,
    child: Builder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: TextButton(
              key: kOpenScreenButtonKey,
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: screenBuilder));
              },
              child: const Text('Open'),
            ),
          ),
        );
      },
    ),
  );
}

/// Wraps [child] in a [Scaffold] with theme and localizations only, for
/// widgets that do not depend on the [WirelessBloc].
Widget createTestWidget({
  required Widget child,
  NavigatorObserver? navigatorObserver,
  ThemeData? theme,
}) {
  return MechanixTheme(
    builder: (context, mechanixTheme, _) {
      return MaterialApp(
        theme: theme ?? mechanixTheme.dark,
        navigatorObservers: [?navigatorObserver],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    },
  );
}

/// Pushes the screen of a widget built with [createWirelessLauncherWidget].
Future<void> openScreenUnderTest(WidgetTester tester) async {
  await tester.tap(find.byKey(kOpenScreenButtonKey));
  await tester.pumpAndSettle();
}

/// Finds a [MechanixIconButton] whose icon is an [ImageIcon] of [assetName].
Finder findIconButtonWithAsset(String assetName) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is MechanixIconButton &&
        widget.icon is ImageIcon &&
        (widget.icon as ImageIcon).image is AssetImage &&
        ((widget.icon as ImageIcon).image as AssetImage).assetName == assetName,
  );
}

/// Finds an [ImageIcon] of [assetName].
Finder findImageIconWithAsset(String assetName) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ImageIcon &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == assetName,
  );
}

Finder get findBackButton => findIconButtonWithAsset(SettingIcons.back);

Finder get findCheckButton => findIconButtonWithAsset(SettingIcons.check);

AppLocalizations l10nOf(WidgetTester tester, Finder finder) {
  return AppLocalizations.of(tester.element(finder))!;
}

/// Uses a tall test surface so long pages and bottom sheets are fully laid
/// out without scrolling.
void useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps a page with a single "Open" button that runs [open] with a context
/// below the [MaterialApp] (and below the [WirelessBloc] when [wirelessBloc]
/// is given), then taps it and settles.
Future<void> pumpSheetHost(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) open,
  WirelessBloc? wirelessBloc,
}) async {
  final host = Builder(
    builder: (context) {
      return Scaffold(
        body: Center(
          child: TextButton(
            key: kOpenScreenButtonKey,
            onPressed: () => open(context),
            child: const Text('Open'),
          ),
        ),
      );
    },
  );

  await tester.pumpWidget(
    wirelessBloc != null
        ? createWirelessTestWidget(wirelessBloc: wirelessBloc, child: host)
        : createTestWidget(child: host),
  );
  await tester.tap(find.byKey(kOpenScreenButtonKey));
  await tester.pumpAndSettle();
}

/// Lets a [MechanixSnackbar] and its auto-dismiss timer run to completion so
/// no timers are left pending when the test ends.
Future<void> flushSnackbars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
