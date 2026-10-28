import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/manage_network/saved_network_tile.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class ManageNetworksBody extends StatelessWidget {
  const ManageNetworksBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: BlocSelector<WirelessBloc, WirelessState, _SavedNetworks>(
        selector: (state) => _SavedNetworks(state.savedNetworks),
        builder: (context, saved) {
          final networks = saved.items;

          if (networks.isEmpty) {
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noSavedNetwork,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          // The list is the scrollable itself (no outer SingleChildScrollView
          // + shrinkWrap), so only the visible tiles are built and laid out.
          return ListView.builder(
            itemCount: networks.length,
            itemBuilder: (context, index) {
              final network = networks[index];
              return SavedNetworkTile(
                key: ValueKey(network.name),
                network: network,
              );
            },
          );
        },
      ),
    );
  }
}

/// Saved networks compared only by what the tiles draw.
class _SavedNetworks extends Equatable {
  const _SavedNetworks(this.items);

  final List<WifiNetwork> items;

  @override
  List<Object?> get props => [
    for (final network in items) (network.name, network.signalType),
  ];
}
