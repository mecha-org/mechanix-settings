import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/output_device_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/input_device_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/notification_sound_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/widgets/volume_slider.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class SoundScreen extends StatefulWidget {
  const SoundScreen({super.key});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  final ScrollController _breadcrumbController = ScrollController();

  @override
  void dispose() {
    _breadcrumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<SoundBloc, SoundState>(
      listenWhen: (previous, current) =>
          previous.error != current.error && current.error != null,
      listener: (context, state) {
        if (state.error == null) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getSoundErrorMessage(AppLocalizations.of(context)!, state.error!),
            ),
          ),
        );
      },
      child: Scaffold(
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
              BreadcrumbItem(label: l10n.sound),
            ],
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: BlocBuilder<SoundBloc, SoundState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VolumeSlider(
                      title: l10n.output,
                      value: state.outputVolume,
                      showSlider: state.selectedOutputDevice.isNotEmpty,
                      onChanged: (val) {
                        context.read<SoundBloc>().add(SetOutputVolume(val));
                      },
                    ),
                    const SizedBox(height: 8),
                    _NavigationRow(
                      label: l10n.device,
                      value: state.selectedOutputDevice.isEmpty
                          ? l10n.noOutputDevices
                          : state.selectedOutputDevice,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OutputDeviceScreen(),
                          ),
                        );
                      },
                    ),
                    const CustomDivider(verticalPadding: 0),
                    const SizedBox(height: 16),
                    VolumeSlider(
                      title: l10n.input,
                      value: state.inputVolume,
                      showSlider: state.selectedInputDevice.isNotEmpty,
                      onChanged: (val) {
                        context.read<SoundBloc>().add(SetInputVolume(val));
                      },
                    ),
                    const SizedBox(height: 8),
                    _NavigationRow(
                      label: l10n.device,
                      value: state.selectedInputDevice.isEmpty
                          ? l10n.noInputDevices
                          : state.selectedInputDevice,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InputDeviceScreen(),
                          ),
                        );
                      },
                    ),
                    const CustomDivider(verticalPadding: 0),
                    _ToggleRow(
                      label: l10n.launcher,
                      value: state.launcherSoundsEnabled,
                      onChanged: (val) {
                        context.read<SoundBloc>().add(
                          ToggleLauncherSounds(val),
                        );
                      },
                    ),
                    const CustomDivider(verticalPadding: 0),
                    _ToggleRow(
                      label: l10n.hapticFeedback,
                      value: state.hapticFeedbackEnabled,
                      onChanged: (val) {
                        context.read<SoundBloc>().add(
                          ToggleHapticFeedback(val),
                        );
                      },
                    ),
                    const CustomDivider(verticalPadding: 0),
                    _NavigationRow(
                      label: l10n.notification,
                      value: l10n.notificationSoundName(
                        state.selectedNotificationSound,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSoundScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: BottomBar(
          leading: CustomIconButton.asset(
            assetPath: SettingIcons.back,
            enabled: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _NavigationRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            const Spacer(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          CustomToggle(value: value, onChanged: onChanged, l10n: l10n),
        ],
      ),
    );
  }
}
