import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

class WifiNetwork extends Equatable {
  final String name;
  final String password;

  final int signalLevel;
  final bool isSecured;
  final WirelessSecurity security;
  final EnterpriseEapMethod? eapMethod;
  final bool isConnected;
  final bool isConnecting;
  final bool autoJoin;
  final bool lowDataMode;
  final bool limitIpAddressTracking;

  final PrivateAddressType privateAddressType;

  final IPv4ConfigType ipConfigType;
  final String ipAddress;
  final String subnetMask;
  final String router;

  final DNSConfigType dnsConfigType;
  final List<String> dnsServers;
  final List<String> dnsSearchDomains;

  final String wirelessAddress;

  const WifiNetwork({
    required this.name,
    this.password = '',
    this.signalLevel = 3,
    this.isSecured = true,
    this.security = WirelessSecurity.none,
    this.eapMethod,
    this.isConnected = false,
    this.isConnecting = false,
    this.autoJoin = true,
    this.lowDataMode = false,
    this.limitIpAddressTracking = true,
    this.privateAddressType = PrivateAddressType.staticAddress,
    this.ipConfigType = IPv4ConfigType.automatic,
    this.ipAddress = "",
    this.subnetMask = "",
    this.router = "",
    this.dnsConfigType = DNSConfigType.automatic,
    this.dnsServers = const [],
    this.dnsSearchDomains = const [],
    this.wirelessAddress = "",
  });

  // Computed signal type
  WifiSignalType get signalType =>
      WifiSignalType.from(level: signalLevel, secured: isSecured);

  WifiNetwork copyWith({
    String? name,
    String? password,
    int? signalLevel,
    bool? isSecured,
    WirelessSecurity? security,
    EnterpriseEapMethod? eapMethod,
    bool? isConnected,
    bool? isConnecting,
    bool? autoJoin,
    bool? lowDataMode,
    bool? limitIpAddressTracking,
    PrivateAddressType? privateAddressType,
    String? wirelessAddressType,
    IPv4ConfigType? ipConfigType,
    String? ipAddress,
    String? subnetMask,
    String? router,
    DNSConfigType? dnsConfigType,
    List<String>? dnsServers,
    List<String>? dnsSearchDomains,
    String? wirelessAddress,
  }) {
    return WifiNetwork(
      name: name ?? this.name,
      password: password ?? this.password,

      signalLevel: signalLevel ?? this.signalLevel,
      isSecured: isSecured ?? this.isSecured,
      security: security ?? this.security,
      eapMethod: eapMethod ?? this.eapMethod,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      autoJoin: autoJoin ?? this.autoJoin,
      lowDataMode: lowDataMode ?? this.lowDataMode,
      limitIpAddressTracking:
          limitIpAddressTracking ?? this.limitIpAddressTracking,
      privateAddressType: privateAddressType ?? this.privateAddressType,
      ipConfigType: ipConfigType ?? this.ipConfigType,
      ipAddress: ipAddress ?? this.ipAddress,
      subnetMask: subnetMask ?? this.subnetMask,
      router: router ?? this.router,
      dnsConfigType: dnsConfigType ?? this.dnsConfigType,
      dnsServers: dnsServers ?? this.dnsServers,
      dnsSearchDomains: dnsSearchDomains ?? this.dnsSearchDomains,
      wirelessAddress: wirelessAddress ?? this.wirelessAddress,
    );
  }

  @override
  List<Object?> get props => [
    name,
    password,
    signalLevel,
    isSecured,
    security,
    eapMethod,
    isConnected,
    isConnecting,
    autoJoin,
    lowDataMode,
    limitIpAddressTracking,
    privateAddressType,
    ipConfigType,
    ipAddress,
    subnetMask,
    router,
    dnsConfigType,
    dnsServers,
    dnsSearchDomains,
    wirelessAddress,
  ];
}
