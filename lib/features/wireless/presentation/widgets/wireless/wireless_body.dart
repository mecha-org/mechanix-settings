import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/add_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/manage_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/screens/network_detail.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_list_item.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/wireless_password.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';

class WirelessBody extends StatelessWidget {
  const WirelessBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WirelessBloc, WirelessState>(
      listenWhen: (previous, current) =>
          !previous.isCaptivePortal &&
          current.isCaptivePortal &&
          current.connectedNetworkName != null,
      listener: (context, state) {
        // Open the captive portal once after successfully connecting to a network.
        context.read<WirelessBloc>().add(const OpenCaptivePortal());
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_WirelessToggle(), _WirelessContent()],
          ),
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
    // Already saved network → connect directly.
    final isSaved = bloc.state.myNetworks.any((n) => n.name == network.name);

    if (isSaved) {
      bloc.add(ConnectToNetworkEvent(network.name, null));
      return;
    }

    // Personal/WEP networks → show password sheet.
    final l10n = AppLocalizations.of(context)!;
    final securityLabel = network.security.label(l10n);

    final passwordResult = await showPasswordBottomSheet(
      context,
      network.name,
      security: securityLabel,
    );

    if (passwordResult != null && context.mounted) {
      bloc.add(
        ConnectToNetworkEvent(
          network.name,
          passwordResult.password,
          autoConnect: passwordResult.connectAutomatically,
        ),
      );
    }
  } else {
    // Open network → connect directly.
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
        return MechanixListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 24,
          ),
          label: Text(
            l10n.wifi.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          trailingWidgets: [
            MechanixSwitch(
              value: isWirelessOn,
              onChanged: (value) {
                context.read<WirelessBloc>().add(ToggleWirelessPower(value));
              },
            ),
          ],
        );
      },
    );
  }
}

class _WirelessContent extends StatelessWidget {
  const _WirelessContent();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WirelessBloc, WirelessState, bool>(
      selector: (state) => state.isWirelessOn,
      builder: (context, isWirelessOn) {
        if (!isWirelessOn) {
          return const SizedBox.shrink();
        }

        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConnectedNetworkTile(),
            SizedBox(height: 12),

            _ConnectingNetworkTile(),
            SizedBox(height: 12),

            _MyNetworksList(),
            SizedBox(height: 20),

            _AvailableNetworksList(),
            SizedBox(height: 20),

            MechanixDivider(indent: 24, endIndent: 24, space: 0),
            SizedBox(height: 20),

            _JoinNetworkTile(),

            _ManageNetworksTile(),
            SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _ConnectedNetworkTile extends StatelessWidget {
  const _ConnectedNetworkTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<
      WirelessBloc,
      WirelessState,
      ({WifiNetwork? connected, bool hasNoInternet})
    >(
      selector: (state) {
        if (state.connectedNetworkName == null) {
          return (connected: null, hasNoInternet: false);
        }
        final net =
            state.myNetworks
                .where((n) => n.name == state.connectedNetworkName)
                .firstOrNull ??
            state.savedNetworks
                .where((n) => n.name == state.connectedNetworkName)
                .firstOrNull ??
            state.availableNetworks
                .where((n) => n.name == state.connectedNetworkName)
                .firstOrNull;
        return (connected: net, hasNoInternet: state.hasNoInternet);
      },
      builder: (context, data) {
        final connected = data.connected?.copyWith(
          hasNoInternet: data.hasNoInternet,
        );
        if (connected == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            NetworkListItem(
              key: ValueKey('connected_${connected.name}'),
              name: connected.name,
              subtitle: data.hasNoInternet ? l10n.noInternetConnection : null,
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
              key: ValueKey('connecting_${network.name}'),
              name: network.name,
              signalType: network.signalType,
              isConnected: false,
              isConnecting: true,
              isSelected: true,
              onTap: () {},
            ),
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
    final theme = Theme.of(context);

    return BlocSelector<
      WirelessBloc,
      WirelessState,
      ({_Networks networks, String? connected, String? connecting})
    >(
      selector: (state) => (
        networks: _Networks(
          state.myNetworks
              .where((e) => e.name != state.connectedNetworkName)
              .toList(),
        ),
        connected: state.connectedNetworkName,
        connecting: state.connectingNetworkName,
      ),
      builder: (context, state) {
        final myNetworks = state.networks.items;
        final countStr = myNetworks.length.toString().padLeft(2, '0');

        return MechanixExpandableListTile(
          key: const ValueKey('my_networks'),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 24,
          ),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myNetworks,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colorScheme.onSecondaryFixed,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Text(
                    '[$countStr]',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSecondaryFixed,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          showTopBorder: true,
          showBottomBorder: true,
          showAccordionButton: false,
          backgroundColor: context.colorScheme.surfaceContainerLowest,
          initiallyExpanded: true,
          children: myNetworks.map((network) {
            return NetworkListItem(
              key: ValueKey(network.name),
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
          }).toList(),
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
    final theme = Theme.of(context);

    return BlocSelector<
      WirelessBloc,
      WirelessState,
      ({_Networks networks, String? connecting, bool isScanning})
    >(
      selector: (state) => (
        networks: _Networks(state.availableNetworks),
        connecting: state.connectingNetworkName,
        isScanning: state.isScanning,
      ),
      builder: (context, state) {
        final networks = state.networks.items;
        final countStr = networks.length.toString().padLeft(2, '0');

        return MechanixExpandableListTile(
          key: const ValueKey('available_networks'),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 24,
          ),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.avaialableNetworks,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: context.colorScheme.onSecondaryFixed,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Text(
                    '[$countStr]',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSecondaryFixed,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          showTopBorder: true,
          showBottomBorder: true,
          trailingWidgets: [
            state.isScanning
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                    ),
                  )
                : MechanixIconButton.standard(
                    type: IconButtonType.rounded,
                    size: IconButtonSize.small,
                    icon: ImageIcon(
                      const AssetImage(SettingIcons.refresh),
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () {
                      context.read<WirelessBloc>().add(
                        const ToggleWirelessPower(true),
                      );
                    },
                  ),
          ],
          showAccordionButton: false,
          backgroundColor: context.colorScheme.surfaceContainerLowest,
          initiallyExpanded: true,
          children: networks.map((network) {
            return NetworkListItem(
              key: ValueKey(network.name),
              name: network.name,
              signalType: network.signalType,
              isConnected: false,
              isConnecting: network.name == state.connecting,
              isSelected: network.name == state.connecting,
              onTap: () => _connectToNetwork(context, network),
            );
          }).toList(),
        );
      },
    );
  }
}

class _JoinNetworkTile extends StatelessWidget {
  const _JoinNetworkTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return MechanixListTile(
      key: const ValueKey('join_network_tile'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      leadingWidgets: [
        ImageIcon(
          const AssetImage(SettingIcons.add),
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
      ],
      label: Text(l10n.joinNetworkTitle, style: theme.textTheme.titleLarge),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddNetworkPage()),
        );
      },
    );
  }
}

class _ManageNetworksTile extends StatelessWidget {
  const _ManageNetworksTile();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return MechanixListTile(
      key: const ValueKey('manage_network_tile'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      label: Text(l10n.manageNetworks, style: theme.textTheme.titleLarge),
      leadingWidgets: [
        ImageIcon(
          const AssetImage(SettingIcons.manageNetwork),
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
      ],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageNetworksScreen()),
        );
      },
    );
  }
}

/// Wraps network lists with value equality to prevent unnecessary rebuilds.
class _Networks extends Equatable {
  const _Networks(this.items);
  final List<WifiNetwork> items;

  @override
  List<Object?> get props => [items];
}
