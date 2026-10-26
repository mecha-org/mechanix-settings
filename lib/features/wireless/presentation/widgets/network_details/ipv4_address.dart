import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/utils/ip_validation_utils.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class IPv4AddressBottomSheet extends StatefulWidget {
  final WifiNetwork network;
  final IPv4ConfigType currentConfig;
  final String ipAddress;
  final String gateway;
  final String? subnetMask;
  final ValueChanged<IPv4SettingsResult> onSaved;

  const IPv4AddressBottomSheet({
    super.key,
    required this.network,
    required this.currentConfig,
    required this.ipAddress,
    required this.gateway,
    this.subnetMask,
    required this.onSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required WifiNetwork network,
    required IPv4ConfigType currentConfig,
    required String ipAddress,
    required String gateway,
    String? subnetMask,
    required ValueChanged<IPv4SettingsResult> onSaved,
  }) {
    return MechanixBottomSheet.showModal(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return IPv4AddressBottomSheet(
          network: network,
          currentConfig: currentConfig,
          ipAddress: ipAddress,
          gateway: gateway,
          subnetMask: subnetMask,
          onSaved: onSaved,
        );
      },
    );
  }

  @override
  State<IPv4AddressBottomSheet> createState() => _IPv4AddressBottomSheetState();
}

class _IPv4AddressBottomSheetState extends State<IPv4AddressBottomSheet> {
  late IPv4ConfigType _configType;
  late final TextEditingController _ipController;
  late final TextEditingController _subnetController;
  late final TextEditingController _routerController;

  @override
  void initState() {
    super.initState();
    _configType = widget.currentConfig;
    _ipController = TextEditingController(text: widget.ipAddress);
    _subnetController = TextEditingController(
      text: widget.subnetMask ?? widget.network.subnetMask,
    );
    _routerController = TextEditingController(text: widget.gateway);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _subnetController.dispose();
    _routerController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    final l10n = AppLocalizations.of(context)!;
    if (_configType == IPv4ConfigType.manual) {
      final error = IpValidationUtils.validateManualIpConfig(
        ip: _ipController.text.trim(),
        subnetMask: _subnetController.text.trim(),
        gateway: _routerController.text.trim(),
        l10n: l10n,
      );

      if (error != null) {
        MechanixSnackbar.text(
          position: MechanixSnackbarPosition.top,
          text: error,
        ).show(context);
        return;
      }
    }

    widget.onSaved(
      IPv4SettingsResult(
        configType: _configType,
        ipAddress: _ipController.text.trim(),
        subnetMask: _subnetController.text.trim(),
        gateway: _routerController.text.trim(),
      ),
    );

    Navigator.of(context).pop();
  }

  Widget _buildInputFieldRow({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimaryFixed,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: MechanixTextField(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                fillColor: theme.colorScheme.surfaceContainerHigh,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
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
                'IPV4 -Configure IP',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              MechanixIconButton.standard(
                icon: ImageIcon(
                  const AssetImage(SettingIcons.check),
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: _saveAndPop,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Radio item: Automatic
          MechanixListTile(
            key: const Key('option_ipv4_automatic'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leadingWidgets: [
              MechanixRadio<IPv4ConfigType>(
                value: IPv4ConfigType.automatic,
                groupValue: _configType,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _configType = val);
                  }
                },
              ),
            ],
            label: Text(
              l10n.automatic,
              style: theme.textTheme.headlineSmall!.copyWith(
                color: _configType == IPv4ConfigType.automatic
                    ? theme.colorScheme.onSecondaryFixed
                    : theme.colorScheme.onPrimary,
              ),
            ),
            onTap: () {
              setState(() => _configType = IPv4ConfigType.automatic);
            },
          ),

          // Radio item: Manual
          MechanixListTile(
            key: const Key('option_ipv4_manual'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leadingWidgets: [
              MechanixRadio<IPv4ConfigType>(
                value: IPv4ConfigType.manual,
                groupValue: _configType,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _configType = val);
                  }
                },
              ),
            ],
            label: Text(
              l10n.manual,
              style: theme.textTheme.headlineSmall!.copyWith(
                color: _configType == IPv4ConfigType.manual
                    ? theme.colorScheme.onSecondaryFixed
                    : theme.colorScheme.onPrimary,
              ),
            ),
            onTap: () {
              setState(() => _configType = IPv4ConfigType.manual);
            },
          ),

          // Manual inputs
          if (_configType == IPv4ConfigType.manual) ...[
            const SizedBox(height: 8),
            _buildInputFieldRow(
              context: context,
              label: l10n.ipAddressLabel,
              controller: _ipController,
              hintText: '0.0.0.0',
            ),
            _buildInputFieldRow(
              context: context,
              label: l10n.subnetMaskLabel,
              controller: _subnetController,
              hintText: '255.255.0.0',
            ),
            _buildInputFieldRow(
              context: context,
              label: l10n.routerLabel,
              controller: _routerController,
              hintText: '-',
            ),
          ],
        ],
      ),
    );
  }
}

class IPv4AddressScreen extends StatelessWidget {
  final WifiNetwork network;
  final IPv4ConfigType currentConfig;
  final String ipAddress;
  final String gateway;
  final String? subnetMask;
  final ValueChanged<IPv4SettingsResult> onSaved;

  const IPv4AddressScreen({
    super.key,
    required this.network,
    required this.currentConfig,
    required this.ipAddress,
    required this.gateway,
    this.subnetMask,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: IPv4AddressBottomSheet(
          network: network,
          currentConfig: currentConfig,
          ipAddress: ipAddress,
          gateway: gateway,
          subnetMask: subnetMask,
          onSaved: onSaved,
        ),
      ),
    );
  }
}
