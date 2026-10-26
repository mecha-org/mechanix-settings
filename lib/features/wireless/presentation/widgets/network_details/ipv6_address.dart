import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/widgets/toast/custom_app_toast.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/utils/ip_validation_utils.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class IPv6AddressBottomSheet extends StatefulWidget {
  final WifiNetwork network;
  final IPv6ConfigType currentConfig;
  final String ipAddress;
  final int prefix;
  final String gateway;
  final ValueChanged<Map<String, dynamic>> onSaved;

  const IPv6AddressBottomSheet({
    super.key,
    required this.network,
    required this.currentConfig,
    required this.ipAddress,
    required this.prefix,
    required this.gateway,
    required this.onSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required WifiNetwork network,
    required IPv6ConfigType currentConfig,
    required String ipAddress,
    required int prefix,
    required String gateway,
    required ValueChanged<Map<String, dynamic>> onSaved,
  }) {
    return MechanixBottomSheet.showModal(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return IPv6AddressBottomSheet(
          network: network,
          currentConfig: currentConfig,
          ipAddress: ipAddress,
          prefix: prefix,
          gateway: gateway,
          onSaved: onSaved,
        );
      },
    );
  }

  @override
  State<IPv6AddressBottomSheet> createState() => _IPv6AddressBottomSheetState();
}

class _IPv6AddressBottomSheetState extends State<IPv6AddressBottomSheet> {
  late IPv6ConfigType _configType;
  late final TextEditingController _ipController;
  late final TextEditingController _prefixController;
  late final TextEditingController _routerController;

  @override
  void initState() {
    super.initState();

    _configType = widget.currentConfig;

    _ipController = TextEditingController(text: widget.ipAddress);
    _prefixController = TextEditingController(
      text: widget.network.ipv6Prefix == 0
          ? ''
          : widget.network.ipv6Prefix.toString(),
    );
    _routerController = TextEditingController(text: widget.gateway);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _prefixController.dispose();
    _routerController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    final l10n = AppLocalizations.of(context)!;
    if (_configType == IPv6ConfigType.manual) {
      final error = IpValidationUtils.validateManualIpv6Config(
        ip: _ipController.text.trim(),
        prefixStr: _prefixController.text.trim(),
        gateway: _routerController.text.trim(),
        l10n: l10n,
      );

      if (error != null) {
        CustomAppToast.show(
          context: context,
          message: error,
          type: ToastType.error,
        );
        return;
      }
    }

    final prefixVal = int.tryParse(_prefixController.text.trim()) ?? 64;
    widget.onSaved({
      'config': _configType,
      'ipAddress': _ipController.text.trim(),
      'gateway': _routerController.text.trim(),
      'prefix': prefixVal,
    });

    Navigator.of(context).pop();
  }

  Widget _buildInputFieldRow({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimaryFixed,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
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
              keyboardType: keyboardType,
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
                'IPV6 -Configure IP',
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
            key: const Key('option_ipv6_automatic'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leadingWidgets: [
              MechanixRadio<IPv6ConfigType>(
                value: IPv6ConfigType.automatic,
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
                color: _configType == IPv6ConfigType.automatic
                    ? theme.colorScheme.onSecondaryFixed
                    : theme.colorScheme.onPrimary,
              ),
            ),
            onTap: () {
              setState(() => _configType = IPv6ConfigType.automatic);
            },
          ),

          // Radio item: Manual
          MechanixListTile(
            key: const Key('option_ipv6_manual'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leadingWidgets: [
              MechanixRadio<IPv6ConfigType>(
                value: IPv6ConfigType.manual,
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
                color: _configType == IPv6ConfigType.manual
                    ? theme.colorScheme.onSecondaryFixed
                    : theme.colorScheme.onPrimary,
              ),
            ),
            onTap: () {
              setState(() => _configType = IPv6ConfigType.manual);
            },
          ),

          // Manual inputs
          if (_configType == IPv6ConfigType.manual) ...[
            const SizedBox(height: 8),
            _buildInputFieldRow(
              context: context,
              label: l10n.ipv6AddressLabel,
              controller: _ipController,
              hintText: '::',
            ),
            _buildInputFieldRow(
              context: context,
              label: l10n.ipv6PrefixLabel,
              controller: _prefixController,
              hintText: '64',
              keyboardType: TextInputType.number,
            ),
            _buildInputFieldRow(
              context: context,
              label: l10n.ipv6GatewayLabel,
              controller: _routerController,
              hintText: '::',
            ),
          ],
        ],
      ),
    );
  }
}

class IPv6AddressScreen extends StatelessWidget {
  final WifiNetwork network;
  final IPv6ConfigType currentConfig;
  final String ipAddress;
  final int prefix;
  final String gateway;
  final ValueChanged<Map<String, dynamic>> onSaved;

  const IPv6AddressScreen({
    super.key,
    required this.network,
    required this.currentConfig,
    required this.ipAddress,
    required this.prefix,
    required this.gateway,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: IPv6AddressBottomSheet(
          network: network,
          currentConfig: currentConfig,
          ipAddress: ipAddress,
          prefix: prefix,
          gateway: gateway,
          onSaved: onSaved,
        ),
      ),
    );
  }
}
