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

class IPv4AddressScreen extends StatefulWidget {
  final WifiNetwork network;
  final IPv4ConfigType currentConfig;
  final String ipAddress;
  final String gateway;
  final ValueChanged<Map<String, dynamic>> onSaved;

  const IPv4AddressScreen({
    super.key,
    required this.network,
    required this.currentConfig,
    required this.ipAddress,
    required this.gateway,
    required this.onSaved,
  });

  @override
  State<IPv4AddressScreen> createState() => _IPv4AddressScreenState();
}

class _IPv4AddressScreenState extends State<IPv4AddressScreen> {
  late IPv4ConfigType _configType;

  final ScrollController _breadcrumbScrollController = ScrollController();
  late final TextEditingController _ipController;
  late final TextEditingController _subnetController;
  late final TextEditingController _routerController;

  @override
  void initState() {
    super.initState();

    _configType = widget.currentConfig;

    _ipController = TextEditingController(text: widget.ipAddress);
    _subnetController = TextEditingController(text: widget.network.subnetMask);
    _routerController = TextEditingController(text: widget.gateway);

    _ipController.addListener(_onTextChanged);
    _subnetController.addListener(_onTextChanged);
    _routerController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _ipController.removeListener(_onTextChanged);
    _subnetController.removeListener(_onTextChanged);
    _routerController.removeListener(_onTextChanged);
    _ipController.dispose();
    _subnetController.dispose();
    _routerController.dispose();
    _breadcrumbScrollController.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    widget.onSaved({
      'config': _configType,
      'ipAddress': _ipController.text.trim(),
      'gateway': _routerController.text.trim(),
      'subnetMask': _subnetController.text.trim(),
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasChanged = _configType != widget.currentConfig ||
        (_configType == IPv4ConfigType.manual &&
            (_ipController.text.trim() != widget.ipAddress ||
                _subnetController.text.trim() !=
                    widget.network.subnetMask ||
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
            BreadcrumbItem(label: l10n.ipv4Address),
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
            RadioGroup<IPv4ConfigType>(
              groupValue: _configType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _configType = value);
                }
              },
              child: Column(
                children: IPv4ConfigType.values
                    .map(
                      (type) => RadioListTile<IPv4ConfigType>(
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

            if (_configType == IPv4ConfigType.manual) ...[
              SettingsSectionHeader(title: l10n.manualIp),

              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _ipController,
                      hintText: l10n.ipAddressLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _subnetController,
                      hintText: l10n.subnetMaskLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _routerController,
                      hintText: l10n.routerLabel,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                    if (_configType == IPv4ConfigType.manual) {
                      final error = IpValidationUtils.validateManualIpConfig(
                        ip: _ipController.text.trim(),
                        subnetMask: _subnetController.text.trim(),
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
