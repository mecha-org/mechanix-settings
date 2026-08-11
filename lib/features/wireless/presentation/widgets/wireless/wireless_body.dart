import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/core/theme/app_theme.dart';
import 'package:mechanix_settings/core/widgets/custom_divider.dart';
import 'package:mechanix_settings/core/widgets/custom_image_asset.dart';
import 'package:mechanix_settings/core/widgets/custom_toggle.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/add_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/manage_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_list_item.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless/enterprise_connection_sheet.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_settings/settings_section_header.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class WirelessBody extends StatelessWidget {
  const WirelessBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WirelessToggle(),
            CustomDivider(verticalPadding: 0),
            _WirelessContent(),
            _ManageNetworksTile(),
          ],
        ),
      ),
    );
  }
}

void _connectToNetwork(BuildContext context, WifiNetwork network) async {
  final bloc = context.read<WirelessBloc>();

  if (bloc.state.connectedNetworkName == network.name) {
    return;
  }

  if (network.isSecured) {
    // If it's already a saved network, we can connect directly (NetworkManager will use saved credentials)
    final isSaved = bloc.state.myNetworks.any((n) => n.name == network.name);
    if (isSaved) {
      bloc.add(ConnectToNetworkEvent(network.name, null));
      return;
    }

    // For unsaved secured networks:
    if (network.security == WirelessSecurity.wpawpa2Enterprise ||
        network.security == WirelessSecurity.leap) {
      final config = await showEnterpriseConnectionBottomSheet(
        context,
        network,
      );
      if (config != null && context.mounted) {
        bloc.add(
          ConnectToNetworkEvent(
            network.name,
            config.password,
            enterpriseConfig: config,
          ),
        );
      }
    } else {
      // For personal/WEP networks, delegate to GNOME agent (system dialog)
      bloc.add(ConnectToNetworkEvent(network.name, null));
    }
  } else {
    // Open network, connect directly
    bloc.add(ConnectToNetworkEvent(network.name, null));
  }
}

class _WirelessToggle extends StatelessWidget {
  const _WirelessToggle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<WirelessBloc, WirelessState, bool>(
      selector: (state) => state.isWirelessOn,
      builder: (context, isWirelessOn) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.wireless, style: Theme.of(context).textTheme.bodyLarge),
              CustomToggle(
                value: isWirelessOn,
                l10n: l10n,
                onChanged: (value) {
                  context.read<WirelessBloc>().add(ToggleWirelessPower(value));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WirelessContent extends StatelessWidget {
  const _WirelessContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<
      WirelessBloc,
      WirelessState,
      ({bool isWirelessOn, bool isScanning, bool hasNetworks})
    >(
      selector: (state) => (
        isWirelessOn: state.isWirelessOn,
        isScanning: state.isScanning,
        hasNetworks:
            state.myNetworks.isNotEmpty ||
            state.availableNetworks.isNotEmpty ||
            state.connectedNetworkName != null,
      ),
      builder: (context, state) {
        if (!state.isWirelessOn) {
          return const SizedBox.shrink();
        }

        if (state.isScanning && !state.hasNetworks) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionHeader(title: l10n.myNetworks),
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const CustomDivider(verticalPadding: 0),
              SettingsSectionHeader(title: l10n.avaialableNetworks),
              const _AddNetworkTile(),
            ],
          );
        }

        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConnectedNetworkTile(),
            _ConnectingNetworkTile(),
            _MyNetworksList(),
            _AvailableNetworksList(),
            _AddNetworkTile(),
          ],
        );
      },
    );
  }
}

class _AddNetworkTile extends StatelessWidget {
  const _AddNetworkTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const CustomDivider(verticalPadding: 16),
        ListTile(
          minTileHeight: 56,
          leading: const CustomImage(assetPath: SettingIcons.add),
          title: Text(
            l10n.addWireless,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddNetworkPage()),
            );
          },
        ),
        const CustomDivider(verticalPadding: 16),
      ],
    );
  }
}

class _ManageNetworksTile extends StatelessWidget {
  const _ManageNetworksTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        l10n.manageWireless,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.onSurfaceVariant,
        size: 30,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageNetworksScreen()),
        );
      },
    );
  }
}

class _ConnectedNetworkTile extends StatelessWidget {
  const _ConnectedNetworkTile();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WirelessBloc, WirelessState, WifiNetwork?>(
      selector: (state) {
        return state.myNetworks
                .firstWhere(
                  (n) => n.name == state.connectedNetworkName,
                  orElse: () => const WifiNetwork(name: ''),
                )
                .name
                .isEmpty
            ? null
            : state.myNetworks.firstWhere(
                (n) => n.name == state.connectedNetworkName,
              );
      },
      builder: (context, connected) {
        if (connected == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            NetworkListItem(
              name: connected.name,
              signalType: connected.signalType,
              isConnected: true,
              isConnecting: false,
              isSelected: false,
              onTap: () {},
              onSettingsTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NetworkDetailScreen(networkName: connected.name),
                  ),
                );
              },
            ),
            const CustomDivider(verticalPadding: 0),
          ],
        );
      },
    );
  }
}

class _MyNetworksList extends StatelessWidget {
  const _MyNetworksList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<
      WirelessBloc,
      WirelessState,
      ({List<WifiNetwork> networks, String? connected, String? connecting})
    >(
      selector: (state) => (
        networks: state.myNetworks,
        connected: state.connectedNetworkName,
        connecting: state.connectingNetworkName,
      ),
      builder: (context, state) {
        final myNetworks = state.networks
            .where((e) => e.name != state.connected)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(title: l10n.myNetworks),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myNetworks.length,
              itemBuilder: (context, index) {
                final network = myNetworks[index];

                return NetworkListItem(
                  name: network.name,
                  signalType: network.signalType,
                  isConnected: network.name == state.connected,
                  isConnecting: network.name == state.connecting,
                  isSelected: network.name == state.connecting,
                  onTap: () => _connectToNetwork(context, network),
                  onSettingsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NetworkDetailScreen(networkName: network.name),
                      ),
                    );
                  },
                );
              },
            ),
            const CustomDivider(verticalPadding: 16),
          ],
        );
      },
    );
  }
}

class _AvailableNetworksList extends StatelessWidget {
  const _AvailableNetworksList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<
      WirelessBloc,
      WirelessState,
      ({List<WifiNetwork> networks, String? connecting, bool isScanning})
    >(
      selector: (state) => (
        networks: state.availableNetworks,
        connecting: state.connectingNetworkName,
        isScanning: state.isScanning,
      ),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(
              title: l10n.avaialableNetworks,
              trailing: state.isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.networks.length,
              itemBuilder: (context, index) {
                final network = state.networks[index];

                return Column(
                  children: [
                    NetworkListItem(
                      name: network.name,
                      signalType: network.signalType,
                      isConnected: false,
                      isConnecting: network.name == state.connecting,
                      isSelected: network.name == state.connecting,
                      onTap: () => _connectToNetwork(context, network),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ConnectingNetworkTile extends StatelessWidget {
  const _ConnectingNetworkTile();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WirelessBloc, WirelessState, WifiNetwork?>(
      selector: (state) {
        final name = state.connectingNetworkName;

        if (name == null || name == state.connectedNetworkName) {
          return null;
        }

        // Do not show separately if the network already exists in UI lists (My networks and available networks).
        final isVisibleNetwork =
            state.myNetworks.any((network) => network.name == name) ||
            state.availableNetworks.any((network) => network.name == name);

        if (isVisibleNetwork) {
          return null;
        }

        // Hidden network: show connection progress separately.
        return state.savedNetworks.firstWhere(
          (network) => network.name == name,
          orElse: () => WifiNetwork(
            name: name,
            isSecured: true,
            signalLevel: 0,
            isConnected: false,
            isConnecting: true,
          ),
        );
      },
      builder: (context, network) {
        if (network == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            NetworkListItem(
              name: network.name,
              signalType: network.signalType,
              isConnected: false,
              isConnecting: true,
              isSelected: true,
              onTap: () {},
            ),
            const CustomDivider(verticalPadding: 0),
          ],
        );
      },
    );
  }
}
