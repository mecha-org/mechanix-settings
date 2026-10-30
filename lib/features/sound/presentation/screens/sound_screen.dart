import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/utils/helper.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/features/sound/presentation/widgets/sound_selection_sheets.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class SoundScreen extends StatelessWidget {
  const SoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocListener<SoundBloc, SoundState>(
      listenWhen: (previous, current) =>
          previous.error != current.error && current.error != null,
      listener: (context, state) {
        if (state.error == null) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getSoundErrorMessage(l10n, state.error!))),
        );
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: MechanixAppBar.small(
          primary: false,
          leading: MechanixIconButton.standard(
            size: IconButtonSize.small,
            icon: ImageIcon(
              const AssetImage(SettingIcons.back),
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          titleSpacing: 0,
          leadingWidth: 48,
          title: Text(
            l10n.sound.toUpperCase(),
            style: theme.textTheme.headlineSmall!.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
        ),
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: SingleChildScrollView(
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Output
                const _VolumeSection(isInput: false),
                _NavigationTile(
                  label: l10n.device,
                  selector: (state, l10n) => state.selectedOutputDevice.isEmpty
                      ? l10n.noOutputDevices
                      : state.selectedOutputDevice,
                  onTap: () => OutputDeviceSheet.show(context),
                ),
                const MechanixDivider(space: 0, indent: 0, endIndent: 0),

                // Input
                const _VolumeSection(isInput: true),
                _NavigationTile(
                  label: l10n.device,
                  selector: (state, l10n) => state.selectedInputDevice.isEmpty
                      ? l10n.noInputDevices
                      : state.selectedInputDevice,
                  onTap: () => InputDeviceSheet.show(context),
                ),
                const MechanixDivider(space: 0, indent: 0, endIndent: 0),

                // Launcher sounds
                _SwitchTile(
                  label: l10n.launcher,
                  selector: (state) => state.launcherSoundsEnabled,
                  onChanged: (context, val) =>
                      context.read<SoundBloc>().add(ToggleLauncherSounds(val)),
                ),

                // Notification sound
                // Haptic feedback
                _SwitchTile(
                  label: l10n.hapticFeedback,
                  selector: (state) => state.hapticFeedbackEnabled,
                  onChanged: (context, val) =>
                      context.read<SoundBloc>().add(ToggleHapticFeedback(val)),
                ),
                _NavigationTile(
                  label: l10n.notification,
                  selector: (state, l10n) => l10n.notificationSoundName(
                    state.selectedNotificationSound,
                  ),
                  onTap: () => NotificationSoundSheet.show(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Volume header and slider for one channel; rebuilds only when that
/// channel's volume or device availability changes.
class _VolumeSection extends StatelessWidget {
  final bool isInput;

  const _VolumeSection({required this.isInput});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<SoundBloc, SoundState, (double, bool)>(
      selector: (state) => isInput
          ? (state.inputVolume, state.selectedInputDevice.isNotEmpty)
          : (state.outputVolume, state.selectedOutputDevice.isNotEmpty),
      builder: (context, data) {
        final (volume, hasDevice) = data;
        return _VolumeControl(
          label: isInput ? l10n.input : l10n.output,
          volume: volume,
          enabled: hasDevice,
          icon: isInput ? SettingIcons.micIcon : SettingIcons.speaker,
          onCommit: (value) => context.read<SoundBloc>().add(
            isInput ? SetInputVolume(value) : SetOutputVolume(value),
          ),
        );
      },
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final String label;
  final double volume;
  final bool enabled;
  final String icon;
  final ValueChanged<double> onCommit;

  const _VolumeControl({
    required this.label,
    required this.volume,
    required this.enabled,
    required this.icon,
    required this.onCommit,
  });

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  // Local value for smooth UI rendering; volume updates are throttled to 400ms
  // during continuous sliding and applied immediately upon release or mute toggle.
  late double _value;
  late double _lastNonZeroValue;

  Timer? _throttleTimer;
  double? _lastCommittedValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _value = widget.volume.clamp(0.0, 1.0);
    _lastNonZeroValue = _value > 0.0 ? _value : 0.5;
    _lastCommittedValue = _value;
  }

  @override
  void didUpdateWidget(covariant _VolumeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external changes only when not actively dragging to prevent jitter.
    if (!_isDragging && oldWidget.volume != widget.volume) {
      _value = widget.volume.clamp(0.0, 1.0);
      if (_value > 0.0) _lastNonZeroValue = _value;
      _lastCommittedValue = _value;
    }
  }

  void _onSliderChanged(double val) {
    _isDragging = true;
    setState(() {
      _value = val;
      if (val > 0.0) _lastNonZeroValue = val;
    });

    // Start 400ms throttle timer if not already running
    _throttleTimer ??= Timer(const Duration(milliseconds: 400), () {
      _throttleTimer = null;
      if (_value != _lastCommittedValue) {
        _lastCommittedValue = _value;
        widget.onCommit(_value);
      }
    });
  }

  void _onSliderChangeEnd(double val) {
    _isDragging = false;

    // Discard any active timer immediately
    _throttleTimer?.cancel();
    _throttleTimer = null;

    // Apply the final value immediately if it hasn't been committed yet
    if (val != _lastCommittedValue) {
      _lastCommittedValue = val;
      widget.onCommit(val);
    }
  }

  void _toggleMute() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _isDragging = false;

    final next = _value > 0.0 ? 0.0 : _lastNonZeroValue;
    setState(() {
      if (_value > 0.0) _lastNonZeroValue = _value;
      _value = next;
    });
    _lastCommittedValue = next;
    widget.onCommit(next);
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MechanixListTile(
          contentPadding: const EdgeInsets.symmetric(
            // vertical: 18,
            horizontal: 24,
          ),
          leadingWidgets: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? _toggleMute : null,
              child: ImageIcon(
                AssetImage(widget.icon),
                color: theme.colorScheme.onSurface,
                size: 19,
              ),
            ),
          ],
          gap: 12,
          height: 56,
          // labelText: widget.label,
          label: Text(
            widget.label,
            style: theme.textTheme.titleLarge!.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailingWidgets: [
            if (widget.enabled)
              Text(
                l10n.volumePercentage((_value * 100).round()),
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFamily: MechanixFontFamily.geistMono,
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MechanixSlider(
            value: _value,
            min: 0,
            max: 1,
            size: MechanixSliderSize.medium,
            showValueLabel: false,
            // A null onChanged disables the slider when no device is detected.
            onChanged: widget.enabled ? _onSliderChanged : null,
            onChangeEnd: widget.enabled ? _onSliderChangeEnd : null,
          ),
        ),
      ],
    );
  }
}

/// Label + current value + caret; the whole row navigates.
class _NavigationTile extends StatelessWidget {
  final String label;
  final String Function(SoundState state, AppLocalizations l10n) selector;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.label,
    required this.selector,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return MechanixListTile(
      contentPadding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 4,
        bottom: 4,
      ),
      height: 56,
      labelText: label,
      onTap: onTap,
      trailingWidgets: [
        // MechanixListTile does not route taps on trailing widgets to onTap.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            // Trailing widgets get unbounded width; cap long device names.
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.5,
            ),
            child: BlocSelector<SoundBloc, SoundState, String>(
              selector: (state) => selector(state, l10n),
              builder: (context, value) {
                return Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: theme.colorScheme.onPrimaryFixed,
                  ),
                );
              },
            ),
          ),
        ),
        ImageIcon(
          const AssetImage(SettingIcons.caretRight),
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool Function(SoundState state) selector;
  final void Function(BuildContext context, bool value) onChanged;

  const _SwitchTile({
    required this.label,
    required this.selector,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MechanixListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      height: 76,
      labelText: label,
      trailingWidgets: [
        BlocSelector<SoundBloc, SoundState, bool>(
          selector: selector,
          builder: (context, value) {
            return MechanixSwitch(
              value: value,
              labelOn: l10n.onToggle,
              labelOff: l10n.offToggle,
              onChanged: (val) => onChanged(context, val),
            );
          },
        ),
      ],
    );
  }
}
