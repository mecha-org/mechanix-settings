import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/app_routes.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_bloc.dart';
import 'package:mechanix_settings/features/date_time/blocs/date_time_event.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/screens/settings_menu_screen.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/wireless.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:show_fps/show_fps.dart';

void main() {
  final wirelessRepository = WirelessRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<WirelessRepository>.value(value: wirelessRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WirelessBloc>(
            create: (context) =>
                WirelessBloc(wirelessRepository)..add(const LoadWireless()),
          ),

          BlocProvider<DateTimeBloc>(
            create: (context) =>
                DateTimeBloc()..add(const InitializeDateTimeEvent()),
          ),
        ],
        child: const MechanixMessageApp(),
      ),
    ),
  );
}

class MechanixMessageApp extends StatelessWidget {
  const MechanixMessageApp({super.key});

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
      routes: {AppRoutes.wireless: (context) => const WirelessScreen()},
    );
  }
}
