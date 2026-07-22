import 'dart:ui';

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
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: SingleChildScrollView(
        child: BlocSelector<WirelessBloc, WirelessState, List<WifiNetwork>>(
          selector: (state) => state.savedNetworks,
          builder: (context, networks) {
            if (networks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noSavedNetwork,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: networks.length,
              itemBuilder: (context, index) {
                return SavedNetworkTile(network: networks[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
