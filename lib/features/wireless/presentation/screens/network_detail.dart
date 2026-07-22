import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/widgets/bottom_bar/bottom_bar.dart';
import 'package:mechanix_settings/core/widgets/custom_icon_button.dart';
import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/network_details_app_bar.dart';
import 'package:mechanix_settings/features/wireless/presentation/widgets/network_details/network_details_body.dart';

class NetworkDetailScreen extends StatefulWidget {
  final String networkName;

  const NetworkDetailScreen({super.key, required this.networkName});

  @override
  State<NetworkDetailScreen> createState() => _NetworkDetailScreenState();
}

class _NetworkDetailScreenState extends State<NetworkDetailScreen> {
  final ScrollController _breadcrumbScrollController = ScrollController();

  @override
  void dispose() {
    _breadcrumbScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WirelessBloc, WirelessState, WifiNetwork>(
      selector: (state) {
        return state.savedNetworks.firstWhere(
          (n) => n.name == widget.networkName,
          orElse: () => state.availableNetworks.firstWhere(
            (n) => n.name == widget.networkName,
            orElse: () => WifiNetwork(name: widget.networkName),
          ),
        );
      },
      builder: (context, network) {
        return Scaffold(
          appBar: NetworkDetailsAppBar(
            networkName: widget.networkName,
            breadcrumbController: _breadcrumbScrollController,
          ),

          body: NetworkDetailsBody(
            network: network,
            networkName: widget.networkName,
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
                assetPath: network.isConnected
                    ? SettingIcons.delete
                    : SettingIcons.connect,
                enabled: true,
                onPressed: () {
                  network.isConnected
                      ? context.read<WirelessBloc>().add(
                          ForgetNetworkEvent(network),
                        )
                      : connectToNetwork(context, network);

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

void connectToNetwork(BuildContext context, WifiNetwork network) {
  final bloc = context.read<WirelessBloc>();

  if (bloc.state.connectedNetworkName == network.name) {
    return;
  }

  bloc.add(ConnectToNetworkEvent(network.name, null));
}
