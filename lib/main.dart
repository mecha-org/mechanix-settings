import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/app_routes.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository_impl.dart';
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository.dart';
import 'package:mechanix_settings/features/date_time/data/repositories/date_time_repository_impl.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository_impl.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/wireless.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth.dart';
import 'package:mechanix_settings/features/battery/data/repositories/battery_repository.dart';
import 'package:mechanix_settings/features/battery/data/repositories/battery_repository_impl.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_bloc.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_event.dart';
import 'package:mechanix_settings/features/battery/presentation/screens/battery_screen.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:show_fps/show_fps.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WirelessRepository>(
          create: (_) => WirelessRepositoryImpl(),
        ),
        RepositoryProvider<BluetoothRepository>(
          create: (_) => BluetoothRepositoryImpl(),
        ),
        RepositoryProvider<DateTimeRepository>(
          create: (_) => DateTimeRepositoryImpl(),
        ),
        RepositoryProvider<BatteryRepository>(
          create: (_) => BatteryRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WirelessBloc>(
            create: (context) => WirelessBloc(
              wirelessRepository: context.read<WirelessRepository>(),
            )..add(InitWifi()),
          ),
          BlocProvider<BluetoothBloc>(
            create: (context) =>
                BluetoothBloc(context.read<BluetoothRepository>())
                  ..add(const LoadBluetooth()),
          ),
          BlocProvider<DateTimeBloc>(
            create: (context) =>
                DateTimeBloc(context.read<DateTimeRepository>())
                  ..add(const InitializeDateTimeEvent()),
          ),
          BlocProvider<BatteryBloc>(
            create: (context) {
              final bloc = BatteryBloc(
                batteryRepository: context.read<BatteryRepository>(),
              );

              bloc
                ..add(const BatteryInit())
                ..add(const BatteryInfoRequested());

              return bloc;
            },
          ),
        ],
        child: const MechanixSettingsApp(),
      ),
    ),
  );
}

class MechanixSettingsApp extends StatelessWidget {
  const MechanixSettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final showFps = Platform.environment['SHOW_FPS'] == 'true';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: showFps
          ? (context, child) {
              return ShowFPS(visible: showFps, showChart: false, child: child!);
            }
          : null,
      theme: AppTheme.darkTheme,
      home: const SettingsMenuScreen(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {
        AppRoutes.wireless: (context) => BlocProvider.value(
          value: context.read<WirelessBloc>(),
          child: const WirelessScreen(),
        ),
        AppRoutes.bluetooth: (context) => BlocProvider.value(
          value: context.read<BluetoothBloc>(),
          child: const BluetoothScreen(),
        ),
        AppRoutes.battery: (context) => BlocProvider.value(
          value: context.read<BatteryBloc>(),
          child: const BatteryScreen(),
        ),
      },
    );
  }
}
