import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/dns.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv4_address.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv6_address.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class NetworkDetailsBody extends StatefulWidget {
  final WifiNetwork network;
  final String networkName;

  const NetworkDetailsBody({
    super.key,
    required this.network,
    required this.networkName,
  });

  @override
  State<NetworkDetailsBody> createState() => _NetworkDetailsBodyState();
}

class _NetworkDetailsBodyState extends State<NetworkDetailsBody> {
  bool _obscurePassword = true;
  bool _isAddressCopied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyAddress(BuildContext context, String address) {
    if (address.isEmpty) return;
    Clipboard.setData(ClipboardData(text: address));
    final l10n = AppLocalizations.of(context)!;

    MechanixSnackbar.text(
      position: MechanixSnackbarPosition.top,
      text: l10n.copiedToClipboard,
    ).show(context);

    setState(() {
      _isAddressCopied = true;
    });
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAddressCopied = false;
        });
      }
    });
  }

  // String _formatWirelessAddress(String address) {
  //   if (address.isEmpty) return '';
  //   if (address.contains(':')) {
  //     return address.toUpperCase().split(':').join(' : ');
  //   }
  //   return address.toUpperCase();
  // }

  String _getSignalStrengthText(WifiNetwork network) {
    final strength = network.rawSignalStrength;

    if (strength >= 80) return 'EXCELLENT';
    if (strength >= 60) return 'GOOD';
    if (strength >= 40) return 'FAIR';
    if (strength > 0) return 'WEAK';
    return 'NONE';
  }

  String _formatFrequency(BuildContext context, int frequency) {
    final l10n = AppLocalizations.of(context)!;

    if (frequency >= 1000) {
      final ghz = (frequency / 1000).toStringAsFixed(1);
      return l10n.wifiFrequencyGHz(ghz);
    }

    return l10n.wifiFrequencyMHz(frequency);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<WirelessBloc>();
    final network = widget.network;
    final isConnected = network.isConnected;
    final ipv4ConfigType = network.ipConfigType;
    final ipv6ConfigType = network.ipv6ConfigType;
    final dnsConfigType = network.dnsConfigType;

    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSecondaryFixed,
    );
    final disabledTitleStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onPrimaryFixed,
    );

    final numericValueStyle = theme.textTheme.titleMedium?.copyWith(
      fontFamily: MechanixFontFamily.geistMono,
      fontSize: 20,
    );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Password
            if (network.password.isNotEmpty)
              MechanixListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                label: Text(l10n.password, style: titleStyle),
                trailingWidgets: [
                  Text(
                    _obscurePassword ? '••••••••' : network.password,
                    style: valueStyle?.copyWith(
                      letterSpacing: _obscurePassword ? 2 : null,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

            // 2. Wireless address
            if (network.wirelessAddress.isNotEmpty)
              MechanixListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                label: Text(l10n.wirelessAddress, style: titleStyle),
                trailingWidgets: [
                  if (_isAddressCopied) ...[
                    MechanixIconButton.tonal(
                      type: IconButtonType.rounded,
                      onPressed: () =>
                          _copyAddress(context, network.wirelessAddress),
                      icon: ImageIcon(
                        const AssetImage(SettingIcons.copy),
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  GestureDetector(
                    onLongPress: () {
                      _copyAddress(context, network.wirelessAddress);
                    },
                    onSecondaryTap: () {
                      _copyAddress(context, network.wirelessAddress);
                    },
                    child: Text(
                      network.wirelessAddress,
                      style: numericValueStyle,
                    ),
                  ),
                ],
              ),

            const MechanixDivider(indent: 24, endIndent: 24),

            // 3. Signal strength
            if (network.rawSignalStrength > 0 || network.signalLevel > 0)
              MechanixListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                label: Text(l10n.signalStrength, style: titleStyle),
                trailingWidgets: [
                  Text(_getSignalStrengthText(network), style: valueStyle),
                ],
              ),

            // 4. Link speed
            if (network.speedMbps > 0)
              MechanixListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                label: Text(l10n.linkSpeed, style: titleStyle),
                trailingWidgets: [
                  Text(
                    network.frequency > 0
                        ? '${network.speedMbps}Mb/s (${_formatFrequency(context, network.frequency)})'
                        : '${network.speedMbps}Mb/s',
                    style: valueStyle,
                  ),
                ],
              ),

            // 5. Security
            MechanixListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 24,
              ),
              label: Text(l10n.security, style: titleStyle),
              trailingWidgets: [
                Text(network.security.label(l10n), style: valueStyle),
              ],
            ),

            const MechanixDivider(indent: 24, endIndent: 24),

            // 6. Connect automatically
            MechanixListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 24,
              ),
              label: Text(
                l10n.connectAutomatically,
                style: isConnected ? titleStyle : disabledTitleStyle,
              ),
              trailingWidgets: [
                IgnorePointer(
                  ignoring: !isConnected,
                  child: MechanixSwitch(
                    value: isConnected ? network.autoJoin : false,
                    onChanged: (val) {
                      bloc.add(
                        UpdateNetworkSettingsEvent(
                          network.copyWith(autoJoin: val),
                        ),
                      );
                    },
                  ),
                ),
              ],
              enabled: isConnected,
            ),
            const MechanixDivider(indent: 24, endIndent: 24),

            // 7. Low Data Mode
            MechanixListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 24,
              ),
              label: Text(
                l10n.lowDataMode,
                style: isConnected ? titleStyle : disabledTitleStyle,
              ),
              trailingWidgets: [
                IgnorePointer(
                  ignoring: !isConnected,
                  child: MechanixSwitch(
                    value: network.lowDataMode,
                    onChanged: (val) {
                      bloc.add(
                        UpdateNetworkSettingsEvent(
                          network.copyWith(lowDataMode: val),
                        ),
                      );
                    },
                  ),
                ),
              ],
              enabled: isConnected,
            ),

            const SizedBox(height: 8),

            if (!isConnected) ...[
              const MechanixDivider(indent: 24, endIndent: 24, space: 0),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  l10n.advanceSettingsNotice,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],

            // 8. IPV4 Address (Expandable)
            MechanixExpandableListTile(
              key: const ValueKey('ipv4_address_tile'),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 24,
              ),
              label: Text(
                l10n.ipv4Address,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryFixed,
                ),
              ),
              showTopBorder: true,
              showBottomBorder: true,
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
              initiallyExpanded: false,
              accordionButtonBuilder: accordionButtonBuilder,
              enabled: isConnected,
              children: isConnected
                  ? [
                      MechanixListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        label: Text(l10n.configureIp, style: titleStyle),
                        trailingWidgets: [
                          Text(
                            ipv4ConfigType.label(l10n).toUpperCase(),
                            style: valueStyle,
                          ),
                          ImageIcon(
                            const AssetImage(SettingIcons.caretRight),
                            size: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ],
                        onTap: () {
                          IPv4AddressBottomSheet.show(
                            context: context,
                            network: network,
                            currentConfig: ipv4ConfigType,
                            ipAddress: network.ipAddress,
                            gateway: network.router,
                            subnetMask: network.subnetMask,
                            onSaved: (data) {
                              bloc.add(
                                UpdateIPSettingsEvent(
                                  network: network,
                                  ipConfigType:
                                      data['config'] as IPv4ConfigType,
                                  ipAddress: data['ipAddress'] as String,
                                  subnetMask: data['subnetMask'] as String,
                                  router: data['gateway'] as String,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (ipv4ConfigType == IPv4ConfigType.manual) ...[
                        if (network.ipAddress.isNotEmpty || network.isConnected)
                          MechanixListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            label: Text(l10n.ipAddressLabel, style: titleStyle),
                            trailingWidgets: [
                              Text(
                                network.ipAddress.isNotEmpty
                                    ? network.ipAddress
                                    : '-',
                                style: numericValueStyle,
                              ),
                            ],
                          ),
                        if (network.subnetMask.isNotEmpty ||
                            network.isConnected)
                          MechanixListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            label: Text(
                              l10n.subnetMaskLabel,
                              style: titleStyle,
                            ),
                            trailingWidgets: [
                              Text(
                                network.subnetMask.isNotEmpty
                                    ? network.subnetMask
                                    : '-',
                                style: numericValueStyle,
                              ),
                            ],
                          ),
                        if (network.router.isNotEmpty || network.isConnected)
                          MechanixListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            label: Text(l10n.routerLabel, style: titleStyle),
                            trailingWidgets: [
                              Text(
                                network.router.isNotEmpty
                                    ? network.router
                                    : '-',
                                style: numericValueStyle,
                              ),
                            ],
                          ),
                      ],
                    ]
                  : const [],
            ),

            // 9. IPV6 Address (Expandable)
            MechanixExpandableListTile(
              key: const ValueKey('ipv6_address_tile'),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 24,
              ),
              label: Text(
                l10n.ipv6Address,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryFixed,
                ),
              ),
              showTopBorder: true,
              showBottomBorder: true,
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
              initiallyExpanded: false,
              accordionButtonBuilder: accordionButtonBuilder,
              enabled: isConnected,
              children: isConnected
                  ? [
                      MechanixListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        label: Text(l10n.configureIpv6, style: titleStyle),
                        trailingWidgets: [
                          Text(
                            ipv6ConfigType.label(l10n).toUpperCase(),
                            style: valueStyle,
                          ),
                          ImageIcon(
                            const AssetImage(SettingIcons.caretRight),
                            size: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ],
                        onTap: () {
                          IPv6AddressBottomSheet.show(
                            context: context,
                            network: network,
                            currentConfig: ipv6ConfigType,
                            ipAddress: network.ipv6Address,
                            prefix: network.ipv6Prefix,
                            gateway: network.ipv6Gateway,
                            onSaved: (data) {
                              bloc.add(
                                UpdateIPv6SettingsEvent(
                                  network: network,
                                  ipv6ConfigType:
                                      data['config'] as IPv6ConfigType,
                                  ipv6Address: data['ipAddress'] as String,
                                  ipv6Prefix: data['prefix'] as int,
                                  ipv6Gateway: data['gateway'] as String,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (ipv6ConfigType == IPv6ConfigType.manual) ...[
                        if (network.ipv6Address.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    l10n.ipv6AddressLabel,
                                    style: titleStyle,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      network.ipv6Address,
                                      style: numericValueStyle,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (network.ipv6Prefix != 0)
                          MechanixListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            label: Text(
                              l10n.ipv6PrefixLabel,
                              style: titleStyle,
                            ),
                            trailingWidgets: [
                              Text(
                                network.ipv6Prefix.toString(),
                                style: numericValueStyle,
                              ),
                            ],
                          ),
                        if (network.ipv6Gateway.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,

                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    l10n.ipv6GatewayLabel,
                                    style: titleStyle,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      network.ipv6Gateway.isNotEmpty
                                          ? network.ipv6Gateway
                                          : '-',
                                      style: numericValueStyle,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ]
                  : const [],
            ),

            // 10. DNS (Expandable)
            MechanixExpandableListTile(
              key: const ValueKey('dns_tile'),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 24,
              ),
              label: Text(
                l10n.dns,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryFixed,
                ),
              ),
              showTopBorder: true,
              showBottomBorder: true,
              backgroundColor: theme.colorScheme.surfaceContainerLowest,
              initiallyExpanded: false,
              accordionButtonBuilder: accordionButtonBuilder,
              enabled: isConnected,
              children: isConnected
                  ? [
                      MechanixListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        label: Text(l10n.configureDns, style: titleStyle),
                        trailingWidgets: [
                          Text(
                            dnsConfigType.label(l10n).toUpperCase(),
                            style: valueStyle,
                          ),
                          ImageIcon(
                            const AssetImage(SettingIcons.caretRight),
                            size: 24,
                            color: theme.colorScheme.onSurface,
                          ),
                        ],
                        onTap: () {
                          DNSBottomSheet.show(
                            context: context,
                            network: network,
                            currentConfig: dnsConfigType,
                            servers: network.dnsServers,
                            onSaved: (data) {
                              bloc.add(
                                UpdateDNSSettingsEvent(
                                  network: network,
                                  dnsConfigType:
                                      data['config'] as DNSConfigType,
                                  dnsServers: List<String>.from(
                                    data['servers'] as List,
                                  ),
                                  dnsSearchDomains: List<String>.from(
                                    data['searchDomains'] as List,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (dnsConfigType == DNSConfigType.manual) ...[
                        if (network.dnsServers.isNotEmpty)
                          for (var i = 0; i < network.dnsServers.length; i++)
                            MechanixListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                              label: Text(
                                l10n.serverNumber(i + 1),
                                style: titleStyle,
                              ),
                              trailingWidgets: [
                                Text(
                                  network.dnsServers[i],
                                  style: numericValueStyle,
                                ),
                              ],
                            ),
                      ],
                    ]
                  : const [],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget accordionButtonBuilder(
    BuildContext context,
    bool isExpanded,
    VoidCallback toggleExpansion,
  ) {
    final theme = Theme.of(context);
    final isConnected = widget.network.isConnected;

    return MechanixIconButton.standard(
      icon: ImageIcon(
        AssetImage(isExpanded ? SettingIcons.caretUp : SettingIcons.caretDown),
        size: 24,
        color: isConnected
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.38),
      ),
      size: IconButtonSize.small,
      type: IconButtonType.rounded,
      onPressed: isConnected ? toggleExpansion : null,
    );
  }
}
