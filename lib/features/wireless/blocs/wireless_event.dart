import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

abstract class WirelessEvent extends Equatable {
  const WirelessEvent();

  @override
  List<Object?> get props => [];
}

class InitWifi extends WirelessEvent {}

class LoadWireless extends WirelessEvent {
  final bool requestScan;
  const LoadWireless({this.requestScan = true});

  @override
  List<Object?> get props => [requestScan];
}

class ToggleWirelessPower extends WirelessEvent {
  final bool isEnabled;
  const ToggleWirelessPower(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

class ScanNetworks extends WirelessEvent {
  const ScanNetworks();
}

class ConnectToNetworkEvent extends WirelessEvent {
  final String name;
  final String? password;
  final EnterpriseConfig? enterpriseConfig;
  const ConnectToNetworkEvent(this.name, this.password, {this.enterpriseConfig});

  @override
  List<Object?> get props => [name, password, enterpriseConfig];
}

class AddNetworkEvent extends WirelessEvent {
  final String name;
  final WirelessSecurity security;
  final EnterpriseConfig? enterpriseConfig;

  const AddNetworkEvent(
    this.name,
    this.security, {
    this.enterpriseConfig,
  });

  @override
  List<Object?> get props => [name, security, enterpriseConfig];
}

class UpdateNetworkSettingsEvent extends WirelessEvent {
  final WifiNetwork network;
  const UpdateNetworkSettingsEvent(this.network);

  @override
  List<Object?> get props => [network];
}

class UpdateIPSettingsEvent extends WirelessEvent {
  final WifiNetwork network;
  final IPv4ConfigType ipConfigType;
  final String ipAddress;
  final String subnetMask;
  final String router;

  const UpdateIPSettingsEvent({
    required this.network,
    required this.ipConfigType,
    required this.ipAddress,
    required this.subnetMask,
    required this.router,
  });

  @override
  List<Object?> get props => [
    network,
    ipConfigType,
    ipAddress,
    subnetMask,
    router,
  ];
}

class UpdateDNSSettingsEvent extends WirelessEvent {
  final WifiNetwork network;
  final DNSConfigType dnsConfigType;
  final List<String> dnsServers;
  final List<String> dnsSearchDomains;

  const UpdateDNSSettingsEvent({
    required this.network,
    required this.dnsConfigType,
    required this.dnsServers,
    required this.dnsSearchDomains,
  });

  @override
  List<Object?> get props => [
    network,
    dnsConfigType,
    dnsServers,
    dnsSearchDomains,
  ];
}

class ForgetNetworkEvent extends WirelessEvent {
  final WifiNetwork network;

  const ForgetNetworkEvent(this.network);
}
