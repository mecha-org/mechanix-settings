import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class AboutDeviceScreen extends StatelessWidget {
  const AboutDeviceScreen({super.key});

  void _openEditDeviceNameBottomSheet(
    BuildContext context,
    String currentName,
  ) {
    MechanixBottomSheet.showModal(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _EditDeviceNameBottomSheet(
          initialName: currentName,
          onSave: (newName) {
            context.read<BluetoothBloc>().add(RenameLocalDeviceEvent(newName));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: MechanixAppBar.small(
        primary: false,
        leading: MechanixIconButton.standard(
          icon: ImageIcon(
            const AssetImage(SettingIcons.back),
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          l10n.aboutDevice.toUpperCase(),
          style: theme.textTheme.headlineSmall!.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocSelector<BluetoothBloc, BluetoothState, (String, bool)>(
        selector: (s) => (s.localDeviceName, s.isDiscoverable),
        builder: (context, selected) {
          final (localDeviceName, isDiscoverable) = selected;

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device name
                  MechanixListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 24,
                    ),
                    labelText: l10n.deviceName,
                    trailingWidgets: [
                      Text(
                        localDeviceName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryFixed,
                        ),
                      ),
                      MechanixIconButton.standard(
                        type: IconButtonType.rounded,
                        icon: Image.asset(
                          SettingIcons.edit,
                          height: 20,
                          width: 20,
                          color: theme.colorScheme.onSecondaryFixed,
                        ),
                        onPressed: () {
                          _openEditDeviceNameBottomSheet(
                            context,
                            localDeviceName,
                          );
                        },
                      ),
                    ],
                    onTap: () {
                      _openEditDeviceNameBottomSheet(context, localDeviceName);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Device type
                  MechanixListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    labelText: l10n.deviceType,
                    trailingWidgets: [
                      ImageIcon(
                        const AssetImage(SettingIcons.comet),
                        size: 20,
                        color: theme.colorScheme.onSecondaryFixed,
                      ),
                      Text(
                        l10n.cometType.toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSecondaryFixed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Device Discoverable
                  MechanixListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    labelText: l10n.deviceDiscoverable,
                    trailingWidgets: [
                      MechanixSwitch(
                        value: isDiscoverable,
                        onChanged: (value) {
                          context.read<BluetoothBloc>().add(
                            ToggleBluetoothDiscoverable(value),
                          );
                        },
                      ),
                    ],
                    onTap: () {
                      context.read<BluetoothBloc>().add(
                        ToggleBluetoothDiscoverable(!isDiscoverable),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditDeviceNameBottomSheet extends StatefulWidget {
  const _EditDeviceNameBottomSheet({
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final ValueChanged<String> onSave;

  @override
  State<_EditDeviceNameBottomSheet> createState() =>
      _EditDeviceNameBottomSheetState();
}

class _EditDeviceNameBottomSheetState
    extends State<_EditDeviceNameBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    final newName = _controller.text.trim();
    if (newName.isNotEmpty && newName.length <= 30) {
      widget.onSave(newName);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 24),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          final trimmed = value.text.trim();
          final isValid = trimmed.isNotEmpty && trimmed.length <= 30;
          final errorText = trimmed.length > 30 ? l10n.deviceNameLimit : null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MechanixIconButton.standard(
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.back),
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.deviceName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  MechanixIconButton.standard(
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.check),
                      color: isValid
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: isValid ? _saveAndPop : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MechanixTextField.outlined(
                controller: _controller,
                autofocus: true,
                hintText: l10n.enterName,
                suffix: ImageIcon(
                  const AssetImage(SettingIcons.edit),
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                errorText: errorText,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (isValid) {
                    _saveAndPop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
