import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/check_box/circular_checkbox.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class NotificationSoundScreen extends StatefulWidget {
  const NotificationSoundScreen({super.key});

  @override
  State<NotificationSoundScreen> createState() =>
      _NotificationSoundScreenState();
}

class _NotificationSoundScreenState extends State<NotificationSoundScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: AppBreadcrumbs(
          scrollController: _breadcrumbController,
          items: [
            BreadcrumbItem(
              label: l10n.settings,
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            BreadcrumbItem(
              label: l10n.sound,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            BreadcrumbItem(label: l10n.notification),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: CustomDivider(verticalPadding: 0),
        ),
      ),
      body: BlocBuilder<SoundBloc, SoundState>(
        builder: (context, state) {
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notificationSounds.length,
              itemBuilder: (context, index) {
                final sound = state.notificationSounds[index];
                final isSelected = sound == state.selectedNotificationSound;

                return GestureDetector(
                  onTap: () {
                    context.read<SoundBloc>().add(SetNotificationSound(sound));
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 16,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        CustomCircleCheckbox(
                          isChecked: isSelected,
                          onTap: () {
                            context.read<SoundBloc>().add(
                              SetNotificationSound(sound),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            l10n.notificationSoundName(sound),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomBar(
        leading: CustomIconButton.asset(
          assetPath: SettingIcons.back,
          enabled: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
