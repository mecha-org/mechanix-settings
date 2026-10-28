import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
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

/// Body of the network details page.
///
/// Each row/section is its own widget that selects only the [WifiNetwork]
/// fields it renders from [WirelessBloc]. Periodic scans that change e.g. the
/// signal strength rebuild just the signal row instead of the whole page.
class NetworkDetailsBody extends StatelessWidget {
  final String networkName;

  const NetworkDetailsBody({super.key, required this.networkName});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Password
            _PasswordTile(networkName: networkName),
            // 2. Wireless address
            _WirelessAddressTile(networkName: networkName),
            const MechanixDivider(indent: 24, endIndent: 24),
            // 3. Signal strength
            _SignalStrengthTile(networkName: networkName),
            // 4. Link speed
            _LinkSpeedTile(networkName: networkName),
            // 5. Security
            _SecurityTile(networkName: networkName),
            const MechanixDivider(indent: 24, endIndent: 24),
            // 6. Connect automatically
            _AutoJoinTile(networkName: networkName),
            const MechanixDivider(indent: 24, endIndent: 24),
            // 7. Low Data Mode
            _LowDataModeTile(networkName: networkName),
            const SizedBox(height: 8),
            _DisconnectedNotice(networkName: networkName),
            // 8. IPv4 Address (Expandable)
            _IPv4Section(networkName: networkName),
            // 9. IPv6 Address (Expandable)
            _IPv6Section(networkName: networkName),
            // 10. DNS (Expandable)
            _DnsSection(networkName: networkName),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Rebuilds [builder] only when the value selected from the network named
/// [networkName] changes.
class _NetworkSelector<T> extends StatelessWidget {
  final String networkName;
  final T Function(WifiNetwork network) select;
  final Widget Function(BuildContext context, T value) builder;

  const _NetworkSelector({
    required this.networkName,
    required this.select,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WirelessBloc, WirelessState, T>(
      selector: (state) => select(state.findNetwork(networkName)),
      builder: builder,
    );
  }
}

/// Latest network from the bloc, read on demand (e.g. when a row is tapped)
/// so callbacks never act on a stale copy.
WifiNetwork _currentNetwork(BuildContext context, String networkName) {
  return context.read<WirelessBloc>().state.findNetwork(networkName);
}

class _DetailStyles {
  final TextStyle? title;
  final TextStyle? disabledTitle;
  final TextStyle? value;
  final TextStyle? numericValue;
  final TextStyle? sectionLabel;

  _DetailStyles._({
    required this.title,
    required this.disabledTitle,
    required this.value,
    required this.numericValue,
    required this.sectionLabel,
  });

  factory _DetailStyles.of(BuildContext context) {
    final theme = Theme.of(context);
    return _DetailStyles._(
      title: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSecondaryFixed,
      ),
      disabledTitle: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      value: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onPrimaryFixed,
      ),
      numericValue: theme.textTheme.titleMedium?.copyWith(
        fontFamily: MechanixFontFamily.geistMono,
        fontSize: 20,
      ),
      sectionLabel: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onPrimaryFixed,
      ),
    );
  }
}

const _rowPadding = EdgeInsets.symmetric(vertical: 18, horizontal: 24);
const _childRowPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 24);

/// Expand/collapse button for the IPv4/IPv6/DNS sections. Disabled while the
/// network is not connected.
AccordionButtonBuilder _accordionButtonBuilder(bool isConnected) {
  return (context, isExpanded, toggleExpansion) {
    final theme = Theme.of(context);

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
  };
}

/// Header row inside an expandable section ("Configure IP  AUTOMATIC  >").
class _ConfigureRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ConfigureRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = _DetailStyles.of(context);

    return MechanixListTile(
      contentPadding: _childRowPadding,
      label: Text(label, style: styles.title),
      trailingWidgets: [
        Text(value.toUpperCase(), style: styles.value),
        ImageIcon(
          const AssetImage(SettingIcons.caretRight),
          size: 24,
          color: theme.colorScheme.onSurface,
        ),
      ],
      onTap: onTap,
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _ValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final styles = _DetailStyles.of(context);

    return MechanixListTile(
      contentPadding: _childRowPadding,
      label: Text(label, style: styles.title),
      trailingWidgets: [Text(value, style: styles.numericValue)],
    );
  }
}

/// Label/value row for long values (IPv6) that scroll horizontally.
class _ScrollableValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _ScrollableValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final styles = _DetailStyles.of(context);

    return Padding(
      padding: _childRowPadding,
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: styles.title)),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(value, style: styles.numericValue, maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordTile extends StatefulWidget {
  final String networkName;

  const _PasswordTile({required this.networkName});

  @override
  State<_PasswordTile> createState() => _PasswordTileState();
}

class _PasswordTileState extends State<_PasswordTile> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final styles = _DetailStyles.of(context);

    return _NetworkSelector<String>(
      networkName: widget.networkName,
      select: (network) => network.password,
      builder: (context, password) {
        if (password.isEmpty) return const SizedBox.shrink();

        return MechanixListTile(
          contentPadding: _rowPadding,
          label: Text(l10n.password, style: styles.title),
          trailingWidgets: [
            Text(
              _obscurePassword ? '••••••••' : password,
              style: styles.value?.copyWith(
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
        );
      },
    );
  }
}

class _WirelessAddressTile extends StatefulWidget {
  final String networkName;

  const _WirelessAddressTile({required this.networkName});

  @override
  State<_WirelessAddressTile> createState() => _WirelessAddressTileState();
}

class _WirelessAddressTileState extends State<_WirelessAddressTile> {
  bool _isAddressCopied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyAddress(String address) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final styles = _DetailStyles.of(context);

    return _NetworkSelector<String>(
      networkName: widget.networkName,
      select: (network) => network.wirelessAddress,
      builder: (context, address) {
        if (address.isEmpty) return const SizedBox.shrink();

        return MechanixListTile(
          contentPadding: _rowPadding,
          label: Text(l10n.wirelessAddress, style: styles.title),
          trailingWidgets: [
            if (_isAddressCopied)
              MechanixIconButton.tonal(
                type: IconButtonType.rounded,
                onPressed: () => _copyAddress(address),
                icon: ImageIcon(
                  const AssetImage(SettingIcons.copy),
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            GestureDetector(
              onLongPress: () => _copyAddress(address),
              onSecondaryTap: () => _copyAddress(address),
              child: Text(address, style: styles.numericValue),
            ),
          ],
        );
      },
    );
  }
}

class _SignalStrengthTile extends StatelessWidget {
  final String networkName;

  const _SignalStrengthTile({required this.networkName});

  static String _label(AppLocalizations l10n, int strength) {
    if (strength >= 80) return l10n.signalStrengthExcellent;
    if (strength >= 60) return l10n.signalStrengthGood;
    if (strength >= 40) return l10n.signalStrengthFair;
    if (strength > 0) return l10n.signalStrengthWeak;
    return l10n.signalStrengthNone;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final styles = _DetailStyles.of(context);

    return _NetworkSelector<({int strength, int level})>(
      networkName: networkName,
      select: (network) =>
          (strength: network.rawSignalStrength, level: network.signalLevel),
      builder: (context, signal) {
        if (signal.strength <= 0 && signal.level <= 0) {
          return const SizedBox.shrink();
        }

        return MechanixListTile(
          contentPadding: _rowPadding,
          label: Text(l10n.signalStrength, style: styles.title),
          trailingWidgets: [
            Text(_label(l10n, signal.strength), style: styles.value),
          ],
        );
      },
    );
  }
}

class _LinkSpeedTile extends StatelessWidget {
  final String networkName;

  const _LinkSpeedTile({required this.networkName});

  static String _formatFrequency(AppLocalizations l10n, int frequency) {
    if (frequency >= 1000) {
      final ghz = (frequency / 1000).toStringAsFixed(1);
      return l10n.wifiFrequencyGHz(ghz);
    }
    return l10n.wifiFrequencyMHz(frequency);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final styles = _DetailStyles.of(context);

    return _NetworkSelector<({int speed, int frequency})>(
      networkName: networkName,
      select: (network) =>
          (speed: network.speedMbps, frequency: network.frequency),
      builder: (context, link) {
        if (link.speed <= 0) return const SizedBox.shrink();

        return MechanixListTile(
          contentPadding: _rowPadding,
          label: Text(l10n.linkSpeed, style: styles.title),
          trailingWidgets: [
            Text(
              link.frequency > 0
                  ? '${link.speed}Mb/s (${_formatFrequency(l10n, link.frequency)})'
                  : '${link.speed}Mb/s',
              style: styles.value,
            ),
          ],
        );
      },
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final String networkName;

  const _SecurityTile({required this.networkName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final styles = _DetailStyles.of(context);

    return _NetworkSelector<WirelessSecurity>(
      networkName: networkName,
      select: (network) => network.security,
      builder: (context, security) {
        return MechanixListTile(
          contentPadding: _rowPadding,
          label: Text(l10n.security, style: styles.title),
          trailingWidgets: [Text(security.label(l10n), style: styles.value)],
        );
      },
    );
  }
}

/// Switch row that is only interactive while the network is connected.
class _ConnectedSwitchTile extends StatelessWidget {
  final String label;
  final bool isConnected;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConnectedSwitchTile({
    required this.label,
    required this.isConnected,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final styles = _DetailStyles.of(context);

    return MechanixListTile(
      contentPadding: _rowPadding,
      label: Text(
        label,
        style: isConnected ? styles.title : styles.disabledTitle,
      ),
      trailingWidgets: [
        IgnorePointer(
          ignoring: !isConnected,
          child: MechanixSwitch(value: value, onChanged: onChanged),
        ),
      ],
      enabled: isConnected,
    );
  }
}

class _AutoJoinTile extends StatelessWidget {
  final String networkName;

  const _AutoJoinTile({required this.networkName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _NetworkSelector<({bool isConnected, bool autoJoin})>(
      networkName: networkName,
      select: (network) =>
          (isConnected: network.isConnected, autoJoin: network.autoJoin),
      builder: (context, data) {
        return _ConnectedSwitchTile(
          label: l10n.connectAutomatically,
          isConnected: data.isConnected,
          value: data.autoJoin,
          onChanged: (val) {
            final network = _currentNetwork(context, networkName);
            context.read<WirelessBloc>().add(
              UpdateNetworkSettingsEvent(network.copyWith(autoJoin: val)),
            );
          },
        );
      },
    );
  }
}

class _LowDataModeTile extends StatelessWidget {
  final String networkName;

  const _LowDataModeTile({required this.networkName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _NetworkSelector<({bool isConnected, bool lowDataMode})>(
      networkName: networkName,
      select: (network) =>
          (isConnected: network.isConnected, lowDataMode: network.lowDataMode),
      builder: (context, data) {
        return _ConnectedSwitchTile(
          label: l10n.lowDataMode,
          isConnected: data.isConnected,
          value: data.lowDataMode,
          onChanged: (val) {
            final network = _currentNetwork(context, networkName);
            context.read<WirelessBloc>().add(
              UpdateNetworkSettingsEvent(network.copyWith(lowDataMode: val)),
            );
          },
        );
      },
    );
  }
}

class _DisconnectedNotice extends StatelessWidget {
  final String networkName;

  const _DisconnectedNotice({required this.networkName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _NetworkSelector<bool>(
      networkName: networkName,
      select: (network) => network.isConnected,
      builder: (context, isConnected) {
        if (isConnected) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MechanixDivider(indent: 24, endIndent: 24, space: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                l10n.advanceSettingsNotice,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Common shell for the IPv4/IPv6/DNS expandable sections.
class _ExpandableSection extends StatelessWidget {
  final Key tileKey;
  final String label;
  final bool isConnected;
  final List<Widget> Function() childrenBuilder;

  const _ExpandableSection({
    required this.tileKey,
    required this.label,
    required this.isConnected,
    required this.childrenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = _DetailStyles.of(context);

    return MechanixExpandableListTile(
      key: tileKey,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      label: Text(label, style: styles.sectionLabel),
      showTopBorder: true,
      showBottomBorder: true,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      initiallyExpanded: false,
      accordionButtonBuilder: _accordionButtonBuilder(isConnected),
      enabled: isConnected,
      children: isConnected ? childrenBuilder() : const [],
    );
  }
}

class _IPv4Section extends StatelessWidget {
  final String networkName;

  const _IPv4Section({required this.networkName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _NetworkSelector<
      ({
        bool isConnected,
        IPv4ConfigType configType,
        String ipAddress,
        String subnetMask,
        String router,
      })
    >(
      networkName: networkName,
      select: (network) => (
        isConnected: network.isConnected,
        configType: network.ipConfigType,
        ipAddress: network.ipAddress,
        subnetMask: network.subnetMask,
        router: network.router,
      ),
      builder: (context, data) {
        String orDash(String value) => value.isNotEmpty ? value : '-';

        return _ExpandableSection(
          tileKey: const ValueKey('ipv4_address_tile'),
          label: l10n.ipv4Address,
          isConnected: data.isConnected,
          childrenBuilder: () => [
            _ConfigureRow(
              label: l10n.configureIp,
              value: data.configType.label(l10n),
              onTap: () {
                final bloc = context.read<WirelessBloc>();
                final network = _currentNetwork(context, networkName);

                IPv4AddressBottomSheet.show(
                  context: context,
                  network: network,
                  currentConfig: network.ipConfigType,
                  ipAddress: network.ipAddress,
                  gateway: network.router,
                  subnetMask: network.subnetMask,
                  onSaved: (result) {
                    bloc.add(
                      UpdateIPSettingsEvent(
                        network: network,
                        ipConfigType: result.configType,
                        ipAddress: result.ipAddress,
                        subnetMask: result.subnetMask,
                        router: result.gateway,
                      ),
                    );
                  },
                );
              },
            ),
            // Sections are only populated while connected, so every manual
            // row is shown, with '-' for missing values.
            if (data.configType == IPv4ConfigType.manual) ...[
              _ValueRow(
                label: l10n.ipAddressLabel,
                value: orDash(data.ipAddress),
              ),
              _ValueRow(
                label: l10n.subnetMaskLabel,
                value: orDash(data.subnetMask),
              ),
              _ValueRow(label: l10n.routerLabel, value: orDash(data.router)),
            ],
          ],
        );
      },
    );
  }
}

class _IPv6Section extends StatelessWidget {
  final String networkName;

  const _IPv6Section({required this.networkName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _NetworkSelector<
      ({
        bool isConnected,
        IPv6ConfigType configType,
        String address,
        int prefix,
        String gateway,
      })
    >(
      networkName: networkName,
      select: (network) => (
        isConnected: network.isConnected,
        configType: network.ipv6ConfigType,
        address: network.ipv6Address,
        prefix: network.ipv6Prefix,
        gateway: network.ipv6Gateway,
      ),
      builder: (context, data) {
        return _ExpandableSection(
          tileKey: const ValueKey('ipv6_address_tile'),
          label: l10n.ipv6Address,
          isConnected: data.isConnected,
          childrenBuilder: () => [
            _ConfigureRow(
              label: l10n.configureIpv6,
              value: data.configType.label(l10n),
              onTap: () {
                final bloc = context.read<WirelessBloc>();
                final network = _currentNetwork(context, networkName);

                IPv6AddressBottomSheet.show(
                  context: context,
                  network: network,
                  currentConfig: network.ipv6ConfigType,
                  ipAddress: network.ipv6Address,
                  prefix: network.ipv6Prefix,
                  gateway: network.ipv6Gateway,
                  onSaved: (result) {
                    bloc.add(
                      UpdateIPv6SettingsEvent(
                        network: network,
                        ipv6ConfigType: result.configType,
                        ipv6Address: result.ipAddress,
                        ipv6Prefix: result.prefix,
                        ipv6Gateway: result.gateway,
                      ),
                    );
                  },
                );
              },
            ),
            if (data.configType == IPv6ConfigType.manual) ...[
              if (data.address.isNotEmpty)
                _ScrollableValueRow(
                  label: l10n.ipv6AddressLabel,
                  value: data.address,
                ),
              if (data.prefix != 0)
                _ValueRow(
                  label: l10n.ipv6PrefixLabel,
                  value: data.prefix.toString(),
                ),
              if (data.gateway.isNotEmpty)
                _ScrollableValueRow(
                  label: l10n.ipv6GatewayLabel,
                  value: data.gateway,
                ),
            ],
          ],
        );
      },
    );
  }
}

/// Selected DNS data. Equatable so a new-but-equal server list coming from
/// a reload does not trigger a rebuild.
class _DnsData extends Equatable {
  final bool isConnected;
  final DNSConfigType configType;
  final List<String> servers;

  const _DnsData({
    required this.isConnected,
    required this.configType,
    required this.servers,
  });

  @override
  List<Object?> get props => [isConnected, configType, servers];
}

class _DnsSection extends StatelessWidget {
  final String networkName;

  const _DnsSection({required this.networkName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _NetworkSelector<_DnsData>(
      networkName: networkName,
      select: (network) => _DnsData(
        isConnected: network.isConnected,
        configType: network.dnsConfigType,
        servers: network.dnsServers,
      ),
      builder: (context, data) {
        return _ExpandableSection(
          tileKey: const ValueKey('dns_tile'),
          label: l10n.dns,
          isConnected: data.isConnected,
          childrenBuilder: () => [
            _ConfigureRow(
              label: l10n.configureDns,
              value: data.configType.label(l10n),
              onTap: () {
                final bloc = context.read<WirelessBloc>();
                final network = _currentNetwork(context, networkName);

                DNSBottomSheet.show(
                  context: context,
                  network: network,
                  currentConfig: network.dnsConfigType,
                  servers: network.dnsServers,
                  onSaved: (result) {
                    bloc.add(
                      UpdateDNSSettingsEvent(
                        network: network,
                        dnsConfigType: result.configType,
                        dnsServers: result.servers,
                        dnsSearchDomains: result.searchDomains,
                      ),
                    );
                  },
                );
              },
            ),
            if (data.configType == DNSConfigType.manual)
              for (var i = 0; i < data.servers.length; i++)
                _ValueRow(
                  label: l10n.serverNumber(i + 1),
                  value: data.servers[i],
                ),
          ],
        );
      },
    );
  }
}
