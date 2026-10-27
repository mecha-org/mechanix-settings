import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/typed_sheet_results.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/utils/ip_validation_utils.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class _DnsItem {
  final TextEditingController controller;

  _DnsItem(String text) : controller = TextEditingController(text: text);
}

class DNSBottomSheet extends StatefulWidget {
  final WifiNetwork network;
  final DNSConfigType currentConfig;
  final List<String> servers;
  final ValueChanged<DNSSettingsResult> onSaved;

  const DNSBottomSheet({
    super.key,
    required this.network,
    required this.currentConfig,
    required this.servers,
    required this.onSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required WifiNetwork network,
    required DNSConfigType currentConfig,
    required List<String> servers,
    required ValueChanged<DNSSettingsResult> onSaved,
  }) {
    return MechanixBottomSheet.showModal(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return DNSBottomSheet(
          network: network,
          currentConfig: currentConfig,
          servers: servers,
          onSaved: onSaved,
        );
      },
    );
  }

  @override
  State<DNSBottomSheet> createState() => _DNSBottomSheetState();
}

class _DNSBottomSheetState extends State<DNSBottomSheet> {
  late DNSConfigType _configType;
  final List<_DnsItem> _items = [];

  @override
  void initState() {
    super.initState();
    _configType = widget.currentConfig;

    for (final s in widget.servers) {
      if (s.trim().isNotEmpty) {
        _items.add(_DnsItem(s.trim()));
      }
    }
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.controller.dispose();
    }
    super.dispose();
  }

  void _saveAndPop() {
    final l10n = AppLocalizations.of(context)!;
    final servers = _items
        .map((e) => e.controller.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (_configType == DNSConfigType.manual) {
      if (servers.isEmpty) {
        MechanixSnackbar.text(
          position: MechanixSnackbarPosition.top,
          text: l10n.pleaseEnterAtLeastOneDnsServer,
        ).show(context);
        return;
      }

      if (!IpValidationUtils.areDnsAddressesValid(servers)) {
        MechanixSnackbar.text(
          position: MechanixSnackbarPosition.top,
          text: l10n.invalidDnsServers,
        ).show(context);
        return;
      }

      if (IpValidationUtils.hasDuplicateDnsAddresses(servers)) {
        MechanixSnackbar.text(
          position: MechanixSnackbarPosition.top,
          text: l10n.duplicateDnsServers,
        ).show(context);
        return;
      }
    }

    widget.onSaved(
      DNSSettingsResult(
        configType: _configType,
        servers: servers,
        searchDomains: widget.network.dnsSearchDomains,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                  l10n.dns,
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
              key: const Key('option_dns_automatic'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              leadingWidgets: [
                MechanixRadio<DNSConfigType>(
                  value: DNSConfigType.automatic,
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
                  color: _configType == DNSConfigType.automatic
                      ? theme.colorScheme.onSecondaryFixed
                      : theme.colorScheme.onPrimary,
                ),
              ),
              onTap: () {
                setState(() => _configType = DNSConfigType.automatic);
              },
            ),

            // Radio item: Manual
            MechanixListTile(
              key: const Key('option_dns_manual'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              leadingWidgets: [
                MechanixRadio<DNSConfigType>(
                  value: DNSConfigType.manual,
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
                  color: _configType == DNSConfigType.manual
                      ? theme.colorScheme.onSecondaryFixed
                      : theme.colorScheme.onPrimary,
                ),
              ),
              onTap: () {
                setState(() => _configType = DNSConfigType.manual);
              },
            ),

            // Manual DNS list
            if (_configType == DNSConfigType.manual) ...[
              const SizedBox(height: 8),
              ...List.generate(
                _items.length,
                (index) => _DnsServerRow(
                  key: ValueKey(_items[index]),
                  controller: _items[index].controller,
                  onDelete: () {
                    setState(() {
                      final removed = _items.removeAt(index);
                      removed.controller.dispose();
                    });
                  },
                ),
              ),

              MechanixListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                label: Text(
                  l10n.addServer,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                leadingWidgets: [
                  MechanixIconButton.filled(
                    type: IconButtonType.rounded,
                    size: IconButtonSize.xSmall,
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.add),
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      setState(() {
                        _items.add(_DnsItem(''));
                      });
                    },
                  ),
                ],
                onTap: () {
                  setState(() {
                    _items.add(_DnsItem(''));
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DnsServerRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDelete;

  const _DnsServerRow({
    super.key,
    required this.controller,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MechanixIconButton.filled(
            backgroundColor: theme.colorScheme.secondaryContainer,
            size: IconButtonSize.small,
            type: IconButtonType.rounded,
            icon: ImageIcon(
              const AssetImage(SettingIcons.delete),
              color: theme.colorScheme.error,
              size: 20,
            ),
            onPressed: onDelete,
          ),

          const SizedBox(width: 12),
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
              keyboardType: TextInputType.text,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DNSScreen extends StatelessWidget {
  final WifiNetwork network;
  final DNSConfigType currentConfig;
  final List<String> servers;
  final ValueChanged<DNSSettingsResult> onSaved;

  const DNSScreen({
    super.key,
    required this.network,
    required this.currentConfig,
    required this.servers,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: DNSBottomSheet(
          network: network,
          currentConfig: currentConfig,
          servers: servers,
          onSaved: onSaved,
        ),
      ),
    );
  }
}
