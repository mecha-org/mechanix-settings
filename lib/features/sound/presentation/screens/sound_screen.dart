import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/features/sound/presentation/widgets/rectangular_slider_thumb_shape.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/output_device_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/input_device_screen.dart';
import 'package:mechanix_settings/features/sound/presentation/screens/notification_sound_screen.dart';
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
                  _VolumeSlider(
                    title: l10n.output,
                    value: state.outputVolume,
                    onChanged: (val) {
                      context.read<SoundBloc>().add(SetOutputVolume(val));
                    },
                  ),
                  const SizedBox(height: 8),
                  _NavigationRow(
                    label: l10n.device,
                    value: state.selectedOutputDevice,

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
                  _VolumeSlider(
                    title: l10n.input,
                    value: state.inputVolume,
                    onChanged: (val) {
                      context.read<SoundBloc>().add(SetInputVolume(val));
                    },
                  ),
                  const SizedBox(height: 8),
                  _NavigationRow(
                    label: l10n.device,
                    value: state.selectedInputDevice,
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
                      context.read<SoundBloc>().add(ToggleLauncherSounds(val));
                    },
                  ),
                  const CustomDivider(verticalPadding: 0),
                  _ToggleRow(
                    label: l10n.hapticFeedback,
                    value: state.hapticFeedbackEnabled,
                    onChanged: (val) {
                      context.read<SoundBloc>().add(ToggleHapticFeedback(val));
                    },
                  ),
                  const CustomDivider(verticalPadding: 0),
                  _NavigationRow(
                    label: l10n.notification,
                    value: _translateNotificationSound(
                      state.selectedNotificationSound,
                      l10n,
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
    );
  }

  String _translateNotificationSound(String name, AppLocalizations l10n) {
    switch (name) {
      case "Wakeup":
        return l10n.wakeup;
      case "Siren":
        return l10n.siren;
      case "Cosmic":
        return l10n.cosmic;
      case "Space":
        return l10n.space;
      case "Supernova":
        return l10n.supernova;
      case "Crash":
        return l10n.crash;

      default:
        return name;
    }
  }
}

class _VolumeSlider extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            Text(
              "$percentage %",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.volume_up_outlined,
              color: AppColors.onSurface,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: AppColors.backgroundVariant,
                  thumbColor: Colors.white,
                  thumbShape: const RectangularSliderThumbShape(
                    thumbWidth: 16,
                    thumbHeight: 16,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(value: value, onChanged: onChanged),
              ),
            ),
          ],
        ),
      ],
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
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
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          CustomToggle(value: value, onChanged: onChanged, l10n: l10n),
        ],
      ),
    );
  }
}
