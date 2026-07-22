import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';

class WirelessFailure extends Equatable {
  final WirelessErrorType type;
  final String? message;
  final Map<String, dynamic>? data;

  const WirelessFailure({required this.type, this.message, this.data});

  @override
  List<Object?> get props => [type, message, data];
}

class WirelessState extends Equatable {
  static const _unset = Object();

  final bool isWirelessOn;
  final bool isScanning;
  final List<WifiNetwork> savedNetworks;
  final List<WifiNetwork> availableNetworks;
  final List<WifiNetwork> myNetworks;
  final String? connectingNetworkName;
  final String? connectedNetworkName;
  final WirelessFailure? error;

  const WirelessState({
    this.isWirelessOn = false,
    this.isScanning = false,
    this.savedNetworks = const [],
    this.availableNetworks = const [],
    this.myNetworks = const [],
    this.connectingNetworkName,
    this.connectedNetworkName,
    this.error,
  });

  WirelessState copyWith({
    bool? isWirelessOn,
    bool? isScanning,
    List<WifiNetwork>? savedNetworks,
    List<WifiNetwork>? availableNetworks,
    List<WifiNetwork>? myNetworks,
    Object? connectingNetworkName = _unset,
    Object? connectedNetworkName = _unset,
    Object? error = _unset,
  }) {
    return WirelessState(
      isWirelessOn: isWirelessOn ?? this.isWirelessOn,
      isScanning: isScanning ?? this.isScanning,
      savedNetworks: savedNetworks ?? this.savedNetworks,
      availableNetworks: availableNetworks ?? this.availableNetworks,
      myNetworks: myNetworks ?? this.myNetworks,
      connectingNetworkName: connectingNetworkName == _unset
          ? this.connectingNetworkName
          : connectingNetworkName as String?,
      connectedNetworkName: connectedNetworkName == _unset
          ? this.connectedNetworkName
          : connectedNetworkName as String?,
      error: error == _unset ? this.error : error as WirelessFailure?,
    );
  }

  @override
  List<Object?> get props => [
    isWirelessOn,
    isScanning,
    savedNetworks,
    availableNetworks,
    myNetworks,
    connectingNetworkName,
    connectedNetworkName,
    error,
  ];
}
