import 'package:flutter/material.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/breadcrumbs.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/widgets/custom_text_field.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/utils/ip_validation_utils.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_section_header.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class IPv6AddressScreen extends StatefulWidget {
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
  State<IPv6AddressScreen> createState() => _IPv6AddressScreenState();
}

class _IPv6AddressScreenState extends State<IPv6AddressScreen> {
  late IPv6ConfigType _configType;

  final ScrollController _breadcrumbScrollController = ScrollController();
  late final TextEditingController _ipController;
  late final TextEditingController _prefixController;
  late final TextEditingController _routerController;

  @override
  void initState() {
    super.initState();

    _configType = widget.currentConfig;

    _ipController = TextEditingController(text: widget.ipAddress);
    _prefixController = TextEditingController(
      text: widget.network.ipv6Prefix == 0 ? '' : widget.network.ipv6Prefix.toString(),
    );
    _routerController = TextEditingController(text: widget.gateway);

    _ipController.addListener(_onTextChanged);
    _prefixController.addListener(_onTextChanged);
    _routerController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _ipController.removeListener(_onTextChanged);
    _prefixController.removeListener(_onTextChanged);
    _routerController.removeListener(_onTextChanged);
    _ipController.dispose();
    _prefixController.dispose();
    _routerController.dispose();
    _breadcrumbScrollController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    final prefixVal = int.tryParse(_prefixController.text.trim()) ?? 64;
    widget.onSaved({
      'config': _configType,
      'ipAddress': _ipController.text.trim(),
      'gateway': _routerController.text.trim(),
      'prefix': prefixVal,
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasChanged = _configType != widget.currentConfig ||
        (_configType == IPv6ConfigType.manual &&
            (_ipController.text.trim() != widget.ipAddress ||
                _prefixController.text.trim() !=
                    (widget.network.ipv6Prefix == 0 ? '' : widget.network.ipv6Prefix.toString()) ||
                _routerController.text.trim() != widget.gateway));

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
              label: l10n.wireless,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(
              label: widget.network.name,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            BreadcrumbItem(label: l10n.ipv6Address),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: CustomDivider(verticalPadding: 0),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<IPv6ConfigType>(
              groupValue: _configType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _configType = value);
                }
              },
              child: Column(
                children: IPv6ConfigType.values
                    .map(
                      (type) => RadioListTile<IPv6ConfigType>(
                        value: type,
                        minTileHeight: 58,
                        activeColor: AppColors.onSurface,
                        title: Text(
                          type.label(l10n),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const CustomDivider(verticalPadding: 16),

            if (_configType == IPv6ConfigType.manual) ...[
              SettingsSectionHeader(title: l10n.configureIpv6),

              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _ipController,
                      hintText: l10n.ipv6AddressLabel,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _prefixController,
                      hintText: l10n.ipv6PrefixLabel,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _routerController,
                      hintText: l10n.ipv6GatewayLabel,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ],
          ],
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
          CustomIconButton.asset(
            assetPath: SettingIcons.check,
            enabled: hasChanged,
            onPressed: hasChanged
                ? () {
                    if (_configType == IPv6ConfigType.manual) {
                      final error = IpValidationUtils.validateManualIpv6Config(
                        ip: _ipController.text.trim(),
                        prefixStr: _prefixController.text.trim(),
                        gateway: _routerController.text.trim(),
                        l10n: l10n,
                      );

                      if (error != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                        return;
                      }
                    }

                    connectToNetwork(context, widget.network);
                    _saveAndPop();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
