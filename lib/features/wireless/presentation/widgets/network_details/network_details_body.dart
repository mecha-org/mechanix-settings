import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/dns.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv4_address.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/ipv6_address.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_config_row.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_info_row.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_section_header.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_toggle_row.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class NetworkDetailsBody extends StatelessWidget {
  final WifiNetwork network;
  final String networkName;

  const NetworkDetailsBody({
    super.key,
    required this.network,
    required this.networkName,
  });

  /// Converts a Wi-Fi frequency in MHz to a user-friendly string.
  /// Displays GHz for values >= 1000 MHz (e.g. 2412 → 2.4 GHz),
  /// otherwise falls back to MHz.
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
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<WirelessBloc>();
    final ipv4ConfigType = network.ipConfigType;
    final ipv6ConfigType = network.ipv6ConfigType;
    final dnsConfigType = network.dnsConfigType;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsToggleRow(
              title: l10n.autoJoin,
              value: network.autoJoin,
              onChanged: (val) {
                bloc.add(
                  UpdateNetworkSettingsEvent(network.copyWith(autoJoin: val)),
                );
              },
            ),

            if (network.password.isNotEmpty) ...[
              SettingsInfoRow(
                title: l10n.password,
                value: network.password,
                obscureValue: network.password.isNotEmpty,
              ),
              const CustomDivider(verticalPadding: 0),
            ],

            if (network.speedMbps > 0) ...[
              SettingsInfoRow(
                title: l10n.speed,
                value: network.frequency > 0
                    ? l10n.wifiSpeedWithBand(
                        network.speedMbps,
                        _formatFrequency(context, network.frequency),
                      )
                    : l10n.wifiSpeed(network.speedMbps),
              ),
              const CustomDivider(verticalPadding: 0),
            ],

            if (network.rawSignalStrength > 0) ...[
              SettingsInfoRow(
                title: l10n.signalStrength,
                value: l10n.wifiSignalStrengthWithDbm(
                  network.rawSignalStrength,
                  network.signalDbm,
                ),
              ),
              const CustomDivider(verticalPadding: 0),
            ],

            SettingsInfoRow(
              title: "Security",
              value: network.security.label(l10n),
            ),
            const CustomDivider(verticalPadding: 0),

            SettingsToggleRow(
              title: l10n.lowDataMode,
              value: network.lowDataMode,
              onChanged: (val) {
                bloc.add(
                  UpdateNetworkSettingsEvent(
                    network.copyWith(lowDataMode: val),
                  ),
                );
              },
            ),
            const CustomDivider(verticalPadding: 0),

            // Wireless Address
            SettingsInfoRow(
              title: l10n.wirelessAddress,
              value: network.wirelessAddress,
            ),
            const CustomDivider(verticalPadding: 0),

            if (!network.isConnected) ...[
              SettingsSectionHeader(title: l10n.advanced),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  l10n.advancedMessage(networkName),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],

            if (network.isConnected) ...[
              SettingsSectionHeader(title: l10n.ipv4Address),

              // Configure IP Navigation Row
              SettingsConfigRow(
                title: l10n.configureIp,
                value: ipv4ConfigType.label(l10n),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IPv4AddressScreen(
                        network: network,
                        currentConfig: ipv4ConfigType,
                        ipAddress: network.ipAddress,
                        gateway: network.router,
                        onSaved: (data) {
                          bloc.add(
                            UpdateIPSettingsEvent(
                              network: network,
                              ipConfigType: data['config'] as IPv4ConfigType,
                              ipAddress: data['ipAddress'] as String,
                              subnetMask: data['subnetMask'] as String,
                              router: data['gateway'] as String,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              if (network.isConnected &&
                  (network.ipConfigType == IPv4ConfigType.automatic ||
                      network.ipConfigType == IPv4ConfigType.manual)) ...[
                SettingsInfoRow(
                  title: l10n.ipAddressLabel,
                  value: network.ipAddress,
                ),
                SettingsInfoRow(
                  title: l10n.subnetMaskLabel,
                  value: network.subnetMask,
                ),
                SettingsInfoRow(title: l10n.routerLabel, value: network.router),
                const CustomDivider(verticalPadding: 0),
              ],

              SettingsSectionHeader(title: l10n.ipv6Address),

              // Configure IPv6 Navigation Row
              SettingsConfigRow(
                title: l10n.configureIpv6,
                value: ipv6ConfigType.label(l10n),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IPv6AddressScreen(
                        network: network,
                        currentConfig: ipv6ConfigType,
                        ipAddress: network.ipv6Address,
                        prefix: network.ipv6Prefix,
                        gateway: network.ipv6Gateway,
                        onSaved: (data) {
                          bloc.add(
                            UpdateIPv6SettingsEvent(
                              network: network,
                              ipv6ConfigType: data['config'] as IPv6ConfigType,
                              ipv6Address: data['ipAddress'] as String,
                              ipv6Prefix: data['prefix'] as int,
                              ipv6Gateway: data['gateway'] as String,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              if (network.isConnected &&
                  (network.ipv6ConfigType == IPv6ConfigType.automatic ||
                      network.ipv6ConfigType == IPv6ConfigType.manual)) ...[
                if (network.ipv6Address.isNotEmpty)
                  SettingsInfoRow(
                    title: l10n.ipv6AddressLabel,
                    value: network.ipv6Address,
                  ),
                if (network.ipv6Address.isNotEmpty)
                  SettingsInfoRow(
                    title: l10n.ipv6PrefixLabel,
                    value: network.ipv6Prefix == 0
                        ? ''
                        : network.ipv6Prefix.toString(),
                  ),
                if (network.ipv6Gateway.isNotEmpty)
                  SettingsInfoRow(
                    title: l10n.ipv6GatewayLabel,
                    value: network.ipv6Gateway,
                  ),
                const CustomDivider(verticalPadding: 0),
              ],

              SettingsSectionHeader(title: l10n.dns),

              // Configure DNS Navigation Row
              SettingsConfigRow(
                title: l10n.configureDns,
                value: dnsConfigType.label(l10n),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DNSScreen(
                        network: network,
                        currentConfig: dnsConfigType,
                        servers: network.dnsServers,
                        onSaved: (data) {
                          bloc.add(
                            UpdateDNSSettingsEvent(
                              network: network,
                              dnsConfigType: data['config'] as DNSConfigType,
                              dnsServers: List<String>.from(
                                data['servers'] as List,
                              ),
                              dnsSearchDomains: List<String>.from(
                                data['searchDomains'] as List,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
