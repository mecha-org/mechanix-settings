import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/custom_loader.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_bloc.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_event.dart';
import 'package:mechanix_settings/features/sound/blocs/sound_state.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class OutputDeviceSheet extends StatelessWidget {
  const OutputDeviceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return MechanixBottomSheet.showModal<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const OutputDeviceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SoundSelectionSheet<String>(
      title: AppLocalizations.of(context)!.outputDevice,
      selector: (state) => (
        state.outputDevices,
        state.selectedOutputDevice,
        state.outputDeviceLoading,
      ),
      valueOf: (device) => device,
      onSelect: (context, device) =>
          context.read<SoundBloc>().add(SetOutputDevice(device)),
    );
  }
}

class InputDeviceSheet extends StatelessWidget {
  const InputDeviceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return MechanixBottomSheet.showModal<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const InputDeviceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SoundSelectionSheet<String>(
      title: AppLocalizations.of(context)!.inputDevice,
      selector: (state) => (
        state.inputDevices,
        state.selectedInputDevice,
        state.inputDeviceLoading,
      ),
      valueOf: (device) => device,
      onSelect: (context, device) =>
          context.read<SoundBloc>().add(SetInputDevice(device)),
    );
  }
}

class NotificationSoundSheet extends StatelessWidget {
  const NotificationSoundSheet({super.key});

  static Future<void> show(BuildContext context) {
    return MechanixBottomSheet.showModal<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const NotificationSoundSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SoundSelectionSheet<String>(
      title: l10n.notification,
      selector: (state) =>
          (state.notificationSounds, state.selectedNotificationSound, false),
      valueOf: (sound) => sound,
      labelFor: l10n.notificationSoundName,
      onSelect: (context, sound) =>
          context.read<SoundBloc>().add(SetNotificationSound(sound)),
    );
  }
}

/// (options, selected option value, loading)
typedef _SheetData<T> = (List<T>, String, bool);

/// Header (back + title) followed by a radio list. Selecting an option applies
/// it immediately; the sheet stays open until dismissed.
class _SoundSelectionSheet<T> extends StatelessWidget {
  final String title;
  final _SheetData<T> Function(SoundState state) selector;

  /// The string that identifies an option and is passed to [onSelect].
  final String Function(T option) valueOf;
  final String Function(String value)? labelFor;
  final String Function(T option)? iconFor;
  final void Function(BuildContext context, String value) onSelect;

  const _SoundSelectionSheet({
    required this.title,
    required this.selector,
    required this.valueOf,
    required this.onSelect,
    this.labelFor,
    this.iconFor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MechanixAppBar.small(
            primary: false,
            backgroundColor: Colors.transparent,
            titleSpacing: 0,
            leadingWidth: 48,
            toolbarHeight: 64,
            leading: MechanixIconButton.standard(
              size: IconButtonSize.small,
              icon: ImageIcon(
                const AssetImage(SettingIcons.back),
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.emphasized.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: BlocSelector<SoundBloc, SoundState, _SheetData<T>>(
              selector: selector,
              builder: (context, data) {
                final (options, selected, loading) = data;

                if (loading) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CustomLoader()),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final value = valueOf(option);
                    return _OptionTile(
                      key: ValueKey(value),
                      label: labelFor?.call(value) ?? value,
                      icon: iconFor?.call(option),
                      isSelected: value == selected,
                      onSelect: () {
                        if (value != selected) onSelect(context, value);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String? icon;
  final bool isSelected;
  final VoidCallback onSelect;

  const _OptionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.onSecondaryFixed
        : theme.colorScheme.onPrimaryFixed;

    return MechanixListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      gap: 4,
      height: 72,
      onTap: onSelect,
      leadingWidgets: [
        MechanixRadio<bool>(
          value: true,
          groupValue: isSelected,
          onChanged: (_) => onSelect(),
        ),
      ],
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleLarge!.copyWith(color: color),
      ),
      trailingWidgets: [
        if (icon != null) ImageIcon(AssetImage(icon!), color: color, size: 20),
      ],
    );
  }
}
