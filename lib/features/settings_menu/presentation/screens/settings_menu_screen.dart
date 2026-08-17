import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/constants/app_routes.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';
import 'package:mechanix_settings/core/widgets/section_list/section_item.dart';
import 'package:mechanix_settings/core/widgets/section_list/section_list.dart';
import 'package:mechanix_settings/features/bluetooth/presentation/screens/bluetooth.dart';
import 'package:mechanix_settings/features/settings_menu/presentation/widgets/settings_menu_bottombar.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/wireless.dart';
import 'package:mechanix_settings/features/date_time/presentation/screens/date_time_screen.dart';
import 'package:mechanix_settings/features/battery/presentation/screens/battery_screen.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class SettingsMenuScreen extends StatefulWidget {
  const SettingsMenuScreen({super.key});

  @override
  State<StatefulWidget> createState() => SettingsMenuScreenState();
}

class SettingsMenuScreenState extends State<SettingsMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: CustomDivider(verticalPadding: 0),
        ),
      ),

      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SectionList(
                items: [
                  SectionItem(
                    title: AppLocalizations.of(context)!.wireless,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.wireless,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WirelessScreen(),
                        ),
                      );
                    },
                  ),

                  SectionItem(
                    title: AppLocalizations.of(context)!.cellularData,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.cellularData,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),

                  SectionItem(
                    title: AppLocalizations.of(context)!.bluetooth,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.bluetooth,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BluetoothScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const CustomDivider(),

              SectionList(
                items: [
                  SectionItem(
                    title: AppLocalizations.of(context)!.display,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.display,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),

                  SectionItem(
                    title: AppLocalizations.of(context)!.sound,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.sound,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),

                  SectionItem(
                    title: AppLocalizations.of(context)!.system,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.system,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),
                ],
              ),

              const CustomDivider(),
              SectionList(
                items: [
                  SectionItem(
                    title: AppLocalizations.of(context)!.timeAndDate,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.timeAndDate,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DateTimeScreen(),
                        ),
                      );
                    },
                  ),

                  SectionItem(
                    title: AppLocalizations.of(context)!.language,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.languages,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),

                  SectionItem(
                    title: AppLocalizations.of(context)!.battery,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.battery,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BatteryScreen(),
                        ),
                      );
                    },
                  ),

                  SectionItem(
                    title: AppLocalizations.of(context)!.about,
                    titleStyle: Theme.of(context).textTheme.bodyLarge,
                    leading: const CustomImage(
                      assetPath: SettingIcons.about,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.about);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SettingsMenuBottombar(),
    );
  }
}
