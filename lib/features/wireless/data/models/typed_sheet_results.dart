import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

class IPv4SettingsResult extends Equatable {
  final IPv4ConfigType configType;
  final String ipAddress;
  final String subnetMask;
  final String gateway;

  const IPv4SettingsResult({
    required this.configType,
    required this.ipAddress,
    required this.subnetMask,
    required this.gateway,
  });

  @override
  List<Object?> get props => [configType, ipAddress, subnetMask, gateway];
}

class IPv6SettingsResult extends Equatable {
  final IPv6ConfigType configType;
  final String ipAddress;
  final int prefix;
  final String gateway;

  const IPv6SettingsResult({
    required this.configType,
    required this.ipAddress,
    required this.prefix,
    required this.gateway,
  });

  @override
  List<Object?> get props => [configType, ipAddress, prefix, gateway];
}

class DNSSettingsResult extends Equatable {
  final DNSConfigType configType;
  final List<String> servers;
  final List<String> searchDomains;

  const DNSSettingsResult({
    required this.configType,
    required this.servers,
    required this.searchDomains,
  });

  @override
  List<Object?> get props => [configType, servers, searchDomains];
}

class WirelessPasswordResult extends Equatable {
  final String password;
  final bool connectAutomatically;

  const WirelessPasswordResult({
    required this.password,
    this.connectAutomatically = true,
  });

  @override
  List<Object?> get props => [password, connectAutomatically];
}
