import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:widgets/widgets.dart';

import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';

class MockBluetoothBloc extends MockBloc<BluetoothEvent, BluetoothState>
    implements BluetoothBloc {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

class FakeBluetoothEvent extends Fake implements BluetoothEvent {}

void registerBluetoothFallbackValues() {
  registerFallbackValue(FakeRoute());
  registerFallbackValue(FakeBluetoothEvent());
  registerFallbackValue(
    const BluetoothDevice(
      name: 'Fallback Device',
      deviceName: 'Fallback Device',
      type: BluetoothDeviceType.unknown,
    ),
  );
}

const tConnectedDevice = BluetoothDevice(
  name: 'Headphones Pro',
  deviceName: 'Headphones Pro',
  type: BluetoothDeviceType.headphones,
  isConnected: true,
  isSaved: true,
  macAddress: '11:22:33:44:55:66',
);

const tPairedDevice = BluetoothDevice(
  name: 'Saved Phone',
  deviceName: 'Saved Phone',
  type: BluetoothDeviceType.mobile,
  isConnected: false,
  isSaved: true,
  macAddress: '22:33:44:55:66:77',
);

const tDiscoveredDevice = BluetoothDevice(
  name: 'Smart Speaker',
  deviceName: 'Smart Speaker',
  type: BluetoothDeviceType.speaker,
  isConnected: false,
  isSaved: false,
  macAddress: '33:44:55:66:77:88',
);

const tConnectingDevice = BluetoothDevice(
  name: 'Connecting TV',
  deviceName: 'Connecting TV',
  type: BluetoothDeviceType.tv,
  isConnected: false,
  isConnecting: true,
  isSaved: true,
  macAddress: '44:55:66:77:88:99',
);

Widget createBluetoothTestWidget({
  required Widget child,
  required BluetoothBloc bluetoothBloc,
  NavigatorObserver? navigatorObserver,
  ThemeData? theme,
  Map<String, WidgetBuilder>? routes,
}) {
  return MechanixTheme(
    builder: (context, mechanixTheme, _) {
      return MaterialApp(
        theme: theme ?? mechanixTheme.dark,
        navigatorObservers: [?navigatorObserver],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: routes ?? const {},
        builder: (context, navigatorChild) {
          return BlocProvider<BluetoothBloc>.value(
            value: bluetoothBloc,
            child: navigatorChild!,
          );
        },
        home: child,
      );
    },
  );
}

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
