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
    return MultiBlocListener(
      listeners: [
        BlocListener<WirelessBloc, WirelessState>(
          listenWhen: (previous, current) =>
              !previous.isCaptivePortal &&
              current.isCaptivePortal &&
              current.connectedNetworkName != null,
          listener: (context, state) {
            // Open the captive portal once after successfully connecting to a
            // network.
            context.read<WirelessBloc>().add(const OpenCaptivePortal());
          },
        ),
        BlocListener<WirelessBloc, WirelessState>(
          listenWhen: (previous, current) =>
              current.error?.type == WirelessErrorType.passwordRequired &&
              previous.error != current.error,
          listener: (context, state) {
            // The repository found that the saved credentials cannot be used
            // (e.g. the access point's security changed): ask for a password.
            final data = state.error!.data ?? const {};
            final name = data['networkName'] as String?;
            if (name == null) return;

            final security =
                data['security'] as WirelessSecurity? ??
                state.findNetwork(name).effectiveSecurity;
            _askPasswordAndConnect(context, name, security);
          },
        ),
      ],
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

/// Connects to the listed network named [name].
///
/// Rows only keep the name and signal icon (see [_NetworkRow]), so the full
/// network is looked up in the current state at tap time. This also means the
/// latest security information is used, not the one from the last rebuild.
void _connectToNetwork(BuildContext context, String name) async {
  final bloc = context.read<WirelessBloc>();
  final state = bloc.state;

  if (state.connectedNetworkName == name) {
    return;
  }

  final saved = state.myNetworks.where((n) => n.name == name).firstOrNull;
  final network =
      saved ?? state.availableNetworks.where((n) => n.name == name).firstOrNull;
  if (network == null) {
    // The network disappeared from the lists since the row was built.
    return;
  }

  if (network.isSecured) {
    // Saved network with unchanged security → reuse the saved credentials.
    // If the access point's security changed (e.g. open → WPA), the saved
    // profile cannot authenticate, so ask for a new password instead.
    if (saved != null && !saved.hasSecurityChanged) {
      bloc.add(ConnectToNetworkEvent(network.name, null));
      return;
    }

    // New network, or saved network whose security changed → password sheet.
    await _askPasswordAndConnect(
      context,
      network.name,
      (saved ?? network).effectiveSecurity,
    );
  } else {
    // Open network → connect directly.
    bloc.add(ConnectToNetworkEvent(network.name, null));
  }
}

/// Shows the password sheet for [networkName] and connects with the entered
/// password. Does nothing if the sheet is dismissed.
Future<void> _askPasswordAndConnect(
  BuildContext context,
  String networkName,
  WirelessSecurity security,
) async {
  final bloc = context.read<WirelessBloc>();
  final l10n = AppLocalizations.of(context)!;

  final passwordResult = await showPasswordBottomSheet(
    context,
    networkName,
    security: security.label(l10n),
    securityType: security,
  );

  if (passwordResult != null && context.mounted) {
    bloc.add(
      ConnectToNetworkEvent(
        networkName,
        passwordResult.password,
        autoConnect: passwordResult.connectAutomatically,
      ),
    );
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
      ({_NetworkRow? connected, bool hasNoInternet})
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
        return (
          connected: net == null ? null : _NetworkRow.of(net),
          hasNoInternet: state.hasNoInternet,
        );
      },
      builder: (context, data) {
        final connected = data.connected;
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
    return BlocSelector<WirelessBloc, WirelessState, _NetworkRow?>(
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
        return _NetworkRow.of(
          state.savedNetworks.firstWhere(
            (network) => network.name == name,
            orElse: () => WifiNetwork(
              name: name,
              isSecured: true,
              signalLevel: 0,
              isConnected: false,
              isConnecting: true,
            ),
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
      ({_NetworkRows networks, String? connected, String? connecting})
    >(
      selector: (state) => (
        networks: _NetworkRows.of(
          state.myNetworks.where((e) => e.name != state.connectedNetworkName),
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
              onTap: () => _connectToNetwork(context, network.name),
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
      ({_NetworkRows networks, String? connecting, bool isScanning})
    >(
      selector: (state) => (
        networks: _NetworkRows.of(state.availableNetworks),
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
                      // Rescan only; the list refreshes from the
                      // AccessPoints change notifications.
                      context.read<WirelessBloc>().add(const ScanNetworks());
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
              onTap: () => _connectToNetwork(context, network.name),
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
          MaterialPageRoute(builder: (_) => const AddNetworkPage()),
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

/// What a network row displays: its name and signal icon.
/// Selectors return rows instead of whole [WifiNetwork]s.
class _NetworkRow extends Equatable {
  _NetworkRow.of(WifiNetwork network)
    : name = network.name,
      signalType = network.signalType;

  final String name;
  final WifiSignalType signalType;

  @override
  List<Object?> get props => [name, signalType];
}

/// A list of [_NetworkRow]s with value equality.
class _NetworkRows extends Equatable {
  _NetworkRows.of(Iterable<WifiNetwork> networks)
    : items = networks.map(_NetworkRow.of).toList(growable: false);

  final List<_NetworkRow> items;

  @override
  List<Object?> get props => [items];
}
