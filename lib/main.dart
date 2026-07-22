import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/app_routes.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository_impl.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository_impl.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/wireless.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth.dart';
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
      },
    );
  }
}
