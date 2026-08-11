import 'dart:async';

import 'package:mechanix_settings/features/wireless/data/models/access_points.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/saved_networks.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:nm/nm.dart';

abstract class WirelessRepository {
  Future<void> init();

  bool isWirelessEnabled();

  Future<void> setWifiEnabled(bool enable);

  Future<void> requestScan();

  NetworkManagerDevice? getWifiDevice();

  Future<List<WifiNetwork>> getSavedNetworks();

  Future<List<WifiNetwork>> getAvailableNetworks({
    bool requestScan = true,
    List<WifiNetwork>? savedNetworks,
  });

  Future<void> connectToNetwork(
    String name,
    String? password, {
    EnterpriseConfig? enterpriseConfig,
  });
  Future<void> addNetwork(
    String name,
    WirelessSecurity security,
    EnterpriseConfig? enterpriseConfig,
  );
  Future<void> updateNetwork(WifiNetwork updatedNetwork);

  Future<void> updateIPSettings(
    WifiNetwork network,
    IPv4ConfigType ipConfigType,
    String ipAddress,
    String subnetMask,
    String router,
  );

  Future<void> updateDNSSettings(
    WifiNetwork network,
    DNSConfigType dnsConfigType,
    List<String> dnsServers,
    List<String> dnsSearchDomains,
  );

  Future<void> forgetNetwork(WifiNetwork network);

  Future<NetworkManagerSettingsConnection?> getAccessPointConnectionSettings(
    NetworkManagerDevice device,
    NetworkManagerAccessPoint accessPoint,
  );

  Future<String?> getSavedWifiPsk(
    NetworkManagerDevice device,
    NetworkManagerAccessPoint accessPoint,
  );

  Stream<List<String>> getWifiEventsStream();

  Stream<List<String>> getWirelessDeviceEventsStream();

  Stream<List<String>> getDeviceEventsStream();

  Future<({AccessPoints? active, List<AccessPoints> available})>
  availableAccessPoints({bool requestScan = true});

  Future<List<SavedWirelessNetwork>> getSavedWirelessNetworks();

  NetworkManagerDeviceState? getWifiDeviceState();

  Future<List<WifiNetwork>> getMyNetworks({List<WifiNetwork>? savedNetworks});
}
