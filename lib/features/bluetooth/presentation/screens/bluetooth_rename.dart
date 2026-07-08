import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_text_field.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class BluetoothRenameScreen extends StatefulWidget {
  const BluetoothRenameScreen({super.key});

  @override
  State<BluetoothRenameScreen> createState() => _BluetoothRenameScreenState();
}

class _BluetoothRenameScreenState extends State<BluetoothRenameScreen> {
  late final TextEditingController _controller;
  final ScrollController _breadcrumbScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final currentName = context.read<BluetoothBloc>().state.localDeviceName;
    _controller = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    _breadcrumbScrollController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    final newName = _controller.text.trim();
    if (newName.isNotEmpty) {
      context.read<BluetoothBloc>().add(RenameLocalDeviceEvent(newName));
    }
    Navigator.of(context).pop();
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
          scrollController: _breadcrumbScrollController,
          items: [
            BreadcrumbItem(
              label: l10n.settings,
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            BreadcrumbItem(
              label: l10n.bluetooth,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(label: l10n.deviceName),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: CustomDivider(verticalPadding: 0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomTextField(
          controller: _controller,
          hintText: l10n.deviceName,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveAndPop(),
        ),
      ),

      bottomNavigationBar: BottomBar(
        leading: CustomIconButton.asset(
          assetPath: SettingIcons.back,
          enabled: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        trailing: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final isEnabled = value.text.trim().isNotEmpty;
              return CustomIconButton.asset(
                assetPath: SettingIcons.check,
                enabled: isEnabled,
                onPressed: isEnabled ? _saveAndPop : () {},
              );
            },
          ),
        ],
      ),
    );
  }
}
