import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/wireless/data/models/access_points.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/saved_networks.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/utils/enterprise_connection_builder.dart';
import 'package:mechanix_settings/features/wireless/data/utils/network_connection_builder.dart';
import 'package:mechanix_settings/features/wireless/data/utils/network_manager_utils.dart';
import 'package:mechanix_settings/features/wireless/data/utils/wifi_parser.dart';
import 'package:nm/nm.dart';

import 'wireless_repository.dart';

class WirelessRepositoryImpl implements WirelessRepository {
  bool _connected = false;
  late NetworkManagerClient _client;

  /// Creates a wireless repository instance.
  ///
  /// The optional [NetworkManagerClient] is primarily used for unit tests
  /// to inject a mock client instead of establishing a real NetworkManager
  /// connection.
  WirelessRepositoryImpl({NetworkManagerClient? client}) {
    if (client != null) {
      _client = client;
      _connected = true;
    }
  }

  @override
  Future<void> requestScan() async {
    final wireless = getWifiDevice()?.wireless;

    if (wireless == null) {
      return;
    }

    await wireless.requestScan();
  }

  @override
  Future<void> init() async {
    if (_connected) return;
    try {
      _client = NetworkManagerClient();
      await _client.connect();
      _connected = true;
      AppLogger.i(
        'NetworkManagerClient connected. Wireless enabled: ${_client.wirelessEnabled}',
      );
    } catch (e) {
      AppLogger.e('Failed to connect to NetworkManagerClient: $e');
    }
  }

  @override
  bool isWirelessEnabled() {
    if (_connected) {
      return _client.wirelessEnabled;
    }
    return false;
  }

  @override
  Future<void> setWifiEnabled(bool enable) async {
    try {
      if (_connected) {
        await _client.setWirelessEnabled(enable);
      }
    } catch (e) {
      AppLogger.e('Failed to set Wireless Enabled: $enable, error: $e');
    }
  }

  /// Retrieves the active Wi-Fi device configured in the NetworkManager client.
  @override
  NetworkManagerDevice? getWifiDevice() {
    if (!_connected) return null;
    final devices = _client.devices;
    return devices.firstWhereOrNull(
      (d) => d.deviceType == NetworkManagerDeviceType.wifi,
    );
  }

  /// Gets all saved Wi-Fi connections from NetworkManager settings,
  /// maps them to [WifiNetwork], and sorts them (connected first, then signal strength).
  @override
  Future<List<WifiNetwork>> getSavedNetworks() async {
    if (!_connected) return [];

    try {
      final connections = _client.settings.connections;
      final wifiDevice = getWifiDevice();
      final scannedAps = wifiDevice?.wireless?.accessPoints ?? [];

      final Map<String, WifiNetwork> networks = {};

      for (final connection in connections) {
        try {
          // Ignore temporary/unsaved connections created during activation.
          if (connection.unsaved) {
            continue;
          }

          final settings = await connection.getSettings();

          final wireless = settings['802-11-wireless'];
          if (wireless == null) {
            continue;
          }

          final ssidValue = wireless['ssid'];
          if (ssidValue is! DBusArray) {
            continue;
          }

          final ssid = String.fromCharCodes(
            ssidValue.children.whereType<DBusByte>().map((e) => e.value),
          );

          if (ssid.isEmpty) {
            continue;
          }

          final ap = scannedAps.firstWhereOrNull(
            (a) => utf8.decode(a.ssid) == ssid,
          );

          final network = await _mapToWifiNetwork(
            name: ssid,
            ap: ap,
            connection: connection,
            connectionSettings: settings,
          );

          // Prefer the currently active/connected network profile in case of duplicate SSIDs
          if (!networks.containsKey(ssid)) {
            networks[ssid] = network;
          } else {
            if (network.isConnected) {
              networks[ssid] = network;
            }
          }
        } catch (e) {
          AppLogger.e("Error reading connection: $e");
        }
      }

      final saved = networks.values.toList();

      saved.sort((a, b) {
        if (a.isConnected && !b.isConnected) return -1;
        if (!a.isConnected && b.isConnected) return 1;

        final aInRange = a.signalLevel > 0;
        final bInRange = b.signalLevel > 0;

        if (aInRange && !bInRange) return -1;
        if (!aInRange && bInRange) return 1;

        return a.name.compareTo(b.name);
      });

      return saved;
    } catch (e, stack) {
      AppLogger.e('Error in getSavedNetworks: $e', stack: stack);
      return [];
    }
  }

  /// Scans for Wi-Fi access points in range and filters out those already saved.
  @override
  Future<List<WifiNetwork>> getAvailableNetworks({
    bool requestScan = true,
    List<WifiNetwork>? savedNetworks,
  }) async {
    if (!_connected) return [];
    try {
      final wifiDevice = getWifiDevice();
      if (wifiDevice == null ||
          wifiDevice.state == NetworkManagerDeviceState.unavailable) {
        return [];
      }

      // Avoid initiating scans during active state transitions to prevent connection failures.
      if (requestScan &&
          wifiDevice.wireless != null &&
          !const {
            NetworkManagerDeviceState.prepare,
            NetworkManagerDeviceState.config,
            NetworkManagerDeviceState.needAuth,
            NetworkManagerDeviceState.ipConfig,
            NetworkManagerDeviceState.ipCheck,
            NetworkManagerDeviceState.secondaries,
          }.contains(wifiDevice.state)) {
        try {
          await wifiDevice.wireless!.requestScan();
        } catch (e, stack) {
          AppLogger.e('Failed to request Wi-Fi scan.', error: e, stack: stack);
        }
      }
      final scannedAps = wifiDevice.wireless?.accessPoints ?? [];
      final List<WifiNetwork> available = [];

      final savedSsids = savedNetworks != null
          ? savedNetworks.map((n) => n.name).toSet()
          : <String>{};

      if (savedNetworks == null) {
        final connections = _client.settings.connections;
        for (var cn in connections) {
          if (!cn.unsaved) {
            final settings = await cn.getSettings();
            final wirelessSettings = settings['802-11-wireless'];
            if (wirelessSettings != null) {
              final ssidVal = wirelessSettings['ssid'];
              if (ssidVal != null && ssidVal is DBusArray) {
                final ssid = String.fromCharCodes(
                  ssidVal.children.map((e) => (e as DBusByte).value),
                );
                savedSsids.add(ssid);
              }
            }
          }
        }
      }

      final seenSsids = <String>{};
      for (var ap in scannedAps) {
        final ssid = utf8.decode(ap.ssid);
        if (ssid.isNotEmpty &&
            !savedSsids.contains(ssid) &&
            !seenSsids.contains(ssid)) {
          seenSsids.add(ssid);
          final mapped = await _mapToWifiNetwork(name: ssid, ap: ap);
          available.add(mapped);
        }
      }
      return available;
    } catch (e) {
      AppLogger.e('Error in getAvailableNetworks: $e');
      return [];
    }
  }

  /// Connects to a wireless network.
  /// - If the connection is already saved, activates it.
  /// - If new, builds the D-Bus connection settings map, enables autoconnect,
  ///   delegates password acquisition to the agent, and triggers activation.
  @override
  Future<void> connectToNetwork(
    String name,
    String? password, {
    EnterpriseConfig? enterpriseConfig,
  }) async {
    if (!_connected) return;
    final wifiDevice = getWifiDevice();
    if (wifiDevice == null ||
        wifiDevice.state == NetworkManagerDeviceState.unavailable) {
      throw Exception('No WiFi device found');
    }

    final scannedAps = wifiDevice.wireless?.accessPoints ?? [];
    final ap = scannedAps.firstWhereOrNull((a) => utf8.decode(a.ssid) == name);

    // Search for an existing saved NetworkManager connection settings profile.
    final existingConnection = await _findExistingConnection(
      accessPoint: ap,
      ssid: name,
    );

    // If a saved profile is found, activate it. This will prompt the system agent
    // (e.g. GNOME agent) to request secrets if necessary or connect automatically using
    // cached secrets, without manually re-creating/replacing the profile.
    if (existingConnection != null) {
      final settings = await existingConnection.getSettings();

      final savedKeyMgmt =
          settings['802-11-wireless-security']?['key-mgmt']?.toNative() ??
          settings['wireless-security']?['key-mgmt']?.toNative();

      final isSecured =
          ap != null && (ap.wpaFlags.isNotEmpty || ap.rsnFlags.isNotEmpty);
      final currentKeyMgmt = isSecured
          ? NetworkManagerUtils.keyMgmtFromAccessPoint(ap)
          : null;

      if (savedKeyMgmt != currentKeyMgmt) {
        AppLogger.i(
          'Security changed ($savedKeyMgmt → $currentKeyMgmt). Recreating profile.',
        );

        await existingConnection.delete();
      } else {
        await _client.activateConnection(
          connection: existingConnection,
          device: wifiDevice,
          accessPoint: ap,
        );
        return;
      }
    }

    if (ap != null) {
      final isSecured = ap.wpaFlags.isNotEmpty || ap.rsnFlags.isNotEmpty;
      if (isSecured) {
        final keyMgmt = NetworkManagerUtils.keyMgmtFromAccessPoint(ap);
        final connection = <String, Map<String, DBusValue>>{
          'connection': {
            'id': DBusString(name),
            'type': const DBusString('802-11-wireless'),
            'autoconnect': const DBusBoolean(true),
          },
          '802-11-wireless': {
            'ssid': DBusArray(
              DBusSignature.byte,
              utf8.encode(name).map((b) => DBusByte(b)).toList(),
            ),
            'mode': const DBusString('infrastructure'),
          },
          'ipv4': {'method': const DBusString('auto')},
          'ipv6': {'method': const DBusString('auto')},
        };

        if (keyMgmt == 'sae') {
          connection['802-11-wireless-security'] = {
            'key-mgmt': const DBusString('sae'),
            'psk-flags': const DBusUint32(1),
          };
        } else if (keyMgmt == 'wpa-eap') {
          final isLeap = enterpriseConfig?.method == EnterpriseEapMethod.leap;
          connection['802-11-wireless-security'] = {
            'key-mgmt': DBusString(isLeap ? 'ieee8021x' : 'wpa-eap'),
          };
          connection['802-1x'] = EnterpriseConnectionBuilder.build8021xSettings(
            enterpriseConfig ??
                const EnterpriseConfig(method: EnterpriseEapMethod.peap),
          );
        } else if (keyMgmt == 'none') {
          connection['802-11-wireless-security'] = {
            'key-mgmt': const DBusString('none'),
            'wep-key-flags': const DBusUint32(1),
          };
        } else {
          connection['802-11-wireless-security'] = {
            'key-mgmt': const DBusString('wpa-psk'),
            'psk-flags': const DBusUint32(1),
          };
        }

        await _client.addAndActivateConnection(
          device: wifiDevice,
          accessPoint: ap,
          connection: connection,
        );

        // Give NetworkManager secret-agent time to open the GNOME password dialog
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await _client.addAndActivateConnection(
          device: wifiDevice,
          accessPoint: ap,
        );
      }
    }
  }

  /// Creates and immediately activates a hidden Wi-Fi network profile.
  ///
  /// If a saved profile with the same SSID already exists, it is reused instead
  /// of creating a duplicate connection.
  ///
  /// For enterprise networks, [enterpriseConfig] must contain the required
  /// 802.1X/EAP configuration.
  @override
  Future<void> addNetwork(
    String name,
    WirelessSecurity security,
    EnterpriseConfig? enterpriseConfig,
  ) async {
    final wifiDevice = await getWifiDevice();

    if (wifiDevice == null) {
      throw Exception('No Wi-Fi device found');
    }

    // Reuse an existing connection profile for this hidden network if one
    // already exists. This avoids creating duplicate saved connections.
    final existingConnection = await _findExistingConnection(ssid: name);
    if (existingConnection != null) {
      AppLogger.i(
        'Hidden network profile for $name already exists. Activating it.',
      );

      await _client.activateConnection(
        connection: existingConnection,
        device: wifiDevice,
      );
      return;
    }

    AppLogger.i(
      'Creating hidden network profile for $name with security $security',
    );

    // Base NetworkManager connection settings.
    //
    // Security-specific configuration (WEP/WPA/WPA3/Enterprise) is applied
    // separately by NetworkConnectionBuilder.
    final connection = <String, Map<String, DBusValue>>{
      'connection': {
        'id': DBusString(name),
        'type': const DBusString('802-11-wireless'),
        'autoconnect': const DBusBoolean(true),
      },
      '802-11-wireless': {
        'ssid': DBusArray(
          DBusSignature.byte,
          utf8.encode(name).map(DBusByte.new).toList(),
        ),
        'mode': const DBusString('infrastructure'),
        'hidden': const DBusBoolean(true),
      },
      'ipv4': {'method': const DBusString('auto')},
      'ipv6': {'method': const DBusString('ignore')},
    };

    // Apply security configuration, including 802.1X settings for
    // enterprise networks when required.
    NetworkConnectionBuilder.applySecuritySettings(
      connection: connection,
      security: security,
      enterpriseConfig: enterpriseConfig,
    );

    // Save the connection profile and immediately activate it.
    await _client.addAndActivateConnection(
      device: wifiDevice,
      connection: connection,
    );
  }

  /// Updates autoconnect and Low Data Mode for a saved profile.
  @override
  Future<void> updateNetwork(WifiNetwork updatedNetwork) async {
    if (!_connected) return;

    try {
      final connections = _client.settings.connections;

      for (final cn in connections) {
        if (cn.unsaved) continue;

        final settings = await cn.getSettings();
        final connectionSettings = settings['connection'];

        if (connectionSettings == null) continue;

        final connectionId = connectionSettings['id']?.toNative();

        if (connectionId != updatedNetwork.name) continue;

        final updatedSettings = Map<String, Map<String, DBusValue>>.from(
          settings,
        );

        final connMap = Map<String, DBusValue>.from(
          settings['connection'] ?? {},
        );

        // Auto Join
        connMap['autoconnect'] = DBusBoolean(updatedNetwork.autoJoin);

        // Low Data Mode (Metered)
        connMap['metered'] = DBusInt32(updatedNetwork.lowDataMode ? 1 : 2);

        updatedSettings['connection'] = connMap;

        await cn.update(updatedSettings);
        return;
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update network settings: $e\n$stackTrace');
    }
  }

  /// Updates IP settings (Static vs Dynamic/Automatic) for a saved profile.
  @override
  Future<void> updateIPSettings(
    WifiNetwork network,
    IPv4ConfigType ipConfigType,
    String ipAddress,
    String subnetMask,
    String router,
  ) async {
    if (!_connected) return;

    try {
      final wifiDevice = getWifiDevice();
      if (wifiDevice == null) return;

      final connections = _client.settings.connections;

      for (final cn in connections) {
        if (cn.unsaved) continue;

        final settings = await cn.getSettings();

        final connectionId = settings["connection"]?["id"]?.toNative();

        if (connectionId != network.name) {
          continue;
        }

        final updatedSettings = Map<String, Map<String, DBusValue>>.from(
          settings,
        );

        final ipv4 = Map<String, DBusValue>.from(settings["ipv4"] ?? {});

        if (ipConfigType == IPv4ConfigType.manual) {
          ipv4["method"] = const DBusString("manual");

          final prefix = NetworkManagerUtils.subnetMaskToPrefix(subnetMask);
          if (prefix == null) {
            throw ArgumentError('Invalid subnet mask: $subnetMask');
          }

          ipv4["address-data"] = DBusArray(DBusSignature("a{sv}"), [
            DBusDict.stringVariant({
              "address": DBusString(ipAddress),
              "prefix": DBusUint32(prefix),
            }),
          ]);

          ipv4["gateway"] = DBusString(router);

          ipv4.remove("addresses");
        } else {
          ipv4["method"] = const DBusString("auto");
          ipv4.remove("address-data");
          ipv4.remove("gateway");
          ipv4.remove("addresses");
        }

        updatedSettings["ipv4"] = ipv4;

        final oldIpv4Settings = settings["ipv4"] ?? {};

        if (!_hasIpv4SettingsChanged(oldIpv4Settings, ipv4)) {
          AppLogger.i("IP settings did not change. Skipping update.");
          break;
        }

        await cn.update(updatedSettings);

        try {
          await _client.deactivateConnection(wifiDevice.activeConnection!);
        } catch (e, stack) {
          AppLogger.e(
            'Failed to deactivate current Wi-Fi connection before applying IP settings.',
            error: e,
            stack: stack,
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));

        await _client.activateConnection(connection: cn, device: wifiDevice);

        break;
      }
    } catch (e) {
      AppLogger.e("Failed to update IP settings: $e");
    }
  }

  /// Updates manual DNS servers and domains inside the ipv4 settings profile.
  @override
  Future<void> updateDNSSettings(
    WifiNetwork network,
    DNSConfigType dnsConfigType,
    List<String> dnsServers,
    List<String> dnsSearchDomains,
  ) async {
    if (!_connected) return;
    try {
      final connections = _client.settings.connections;
      for (var cn in connections) {
        if (!cn.unsaved) {
          final settings = await cn.getSettings();
          final connectionSettings = settings['connection'];
          if (connectionSettings != null) {
            final connectionId = connectionSettings['id']?.toNative();
            if (connectionId == network.name) {
              final updatedSettings = Map<String, Map<String, DBusValue>>.from(
                settings,
              );
              final ipv4Map = Map<String, DBusValue>.from(
                settings['ipv4'] ?? {},
              );

              if (dnsConfigType == DNSConfigType.manual) {
                ipv4Map['ignore-auto-dns'] = const DBusBoolean(true);
                final dnsList = dnsServers
                    .where((s) => s.contains('.')) // Only IPv4 addresses
                    .map((s) => DBusUint32(NetworkManagerUtils.ipv4ToUint32(s)))
                    .toList();
                ipv4Map['dns'] = DBusArray(DBusSignature('u'), dnsList);

                final searchList = dnsSearchDomains
                    .map((s) => DBusString(s))
                    .toList();
                ipv4Map['dns-search'] = DBusArray(
                  DBusSignature('s'),
                  searchList,
                );
              } else {
                ipv4Map.remove('dns');
                ipv4Map.remove('dns-search');
                ipv4Map['ignore-auto-dns'] = const DBusBoolean(false);
                ipv4Map.remove('dns-options');
              }

              updatedSettings['ipv4'] = ipv4Map;

              final oldIpv4 = settings["ipv4"] ?? {};

              if (!_hasDnsSettingsChanged(oldIpv4, ipv4Map, dnsConfigType)) {
                AppLogger.i("DNS settings did not change. Skipping update.");
                break;
              }

              await cn.update(updatedSettings);

              final wifiDevice = getWifiDevice();

              if (wifiDevice == null) {
                return;
              }

              if (wifiDevice.activeConnection != null) {
                try {
                  await _client.deactivateConnection(
                    wifiDevice.activeConnection!,
                  );
                } catch (e, stack) {
                  AppLogger.e(
                    'Failed to deactivate current Wi-Fi connection before applying DNS settings.',
                    error: e,
                    stack: stack,
                  );
                }

                await Future.delayed(const Duration(milliseconds: 500));

                await _client.activateConnection(
                  connection: cn,
                  device: wifiDevice,
                  accessPoint: wifiDevice.wireless?.activeAccessPoint,
                );
              }

              final verify = await cn.getSettings();

              AppLogger.i("IPv4 settings after update:");
              verify['ipv4']?.forEach((key, value) {
                AppLogger.i("$key = ${value.toNative()}");
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.e('Failed to update DNS settings: $e');
    }
  }

  /// Deletes a connection profile (Forget Network).
  @override
  Future<void> forgetNetwork(WifiNetwork network) async {
    if (!_connected) return;
    final connections = _client.settings.connections;
    for (var cn in connections) {
      if (!cn.unsaved) {
        var connectionSettings = await cn.getSettings();
        final connectionId = connectionSettings["connection"]?["id"]
            ?.toNative();
        if (connectionId == network.name) {
          try {
            await cn.delete();
          } catch (e) {
            AppLogger.e('Failed to delete saved network: $e');
          }
          return;
        }
      }
    }
  }

  /// Maps NetworkManager D-Bus property data into [WifiNetwork] data class.
  Future<WifiNetwork> _mapToWifiNetwork({
    required String name,
    NetworkManagerAccessPoint? ap,
    NetworkManagerSettingsConnection? connection,
    Map<String, Map<String, DBusValue>>? connectionSettings,
  }) async {
    final settings =
        connectionSettings ??
        (connection != null ? await connection.getSettings() : null);

    final isSecured = await WifiParser.parseSecurity(
      name: name,
      ap: ap,
      connection: connection,
      settings: settings,
    );

    final security = WifiParser.parseSecurityType(
      name: name,
      ap: ap,
      connection: connection,
      settings: settings,
    );

    final eapMethod = WifiParser.parseEapMethod(settings);

    final signalLevel = WifiParser.parseSignalLevel(ap);

    final connectionState = await _getConnectionState(name: name, ap: ap);

    final isConnected = connectionState.isConnected;
    final wifiDevice = connectionState.device;

    final password = await _getPassword(
      name: name,
      ap: ap,
      connection: connection,
      isConnected: isConnected,
      isSecured: isSecured,
      wifiDevice: wifiDevice,
    );

    final ipSettings = WifiParser.parseIPv4Settings(settings);

    var ipAddress = ipSettings.ipAddress;
    var subnetMask = ipSettings.subnetMask;
    var router = ipSettings.router;
    var ipConfigType = ipSettings.ipConfigType;

    var dnsConfigType = ipSettings.dnsConfigType;
    var dnsServers = ipSettings.dnsServers;
    var dnsSearchDomains = ipSettings.dnsSearchDomains;

    if (isConnected && wifiDevice != null) {
      final ip4Config = wifiDevice.ip4Config;

      if (ipConfigType == IPv4ConfigType.automatic &&
          ip4Config != null &&
          ip4Config.addressData.isNotEmpty) {
        final addr = ip4Config.addressData.first;

        ipAddress = addr["address"] ?? ipAddress;

        final prefix = addr["prefix"] as int?;
        if (prefix != null) {
          subnetMask = NetworkManagerUtils.prefixToSubnetMask(prefix);
        }

        if (ip4Config.gateway.isNotEmpty) {
          router = ip4Config.gateway;
        }
      }
    }

    final autoJoin = WifiParser.parseAutoConnect(settings);
    final lowDataMode = WifiParser.parseLowDataMode(settings);

    final speedMbps = isConnected ? WifiParser.parseSpeedMbps(wifiDevice) : 0;

    return WifiNetwork(
      name: name,
      password: password,
      security: security,
      eapMethod: eapMethod,
      signalLevel: signalLevel,
      rawSignalStrength: ap?.strength ?? 0,
      speedMbps: speedMbps,
      frequency: ap?.frequency ?? 0,
      isSecured: isSecured,
      isConnected: isConnected,
      isConnecting: false,
      autoJoin: autoJoin,
      lowDataMode: lowDataMode,
      ipConfigType: ipConfigType,
      ipAddress: ipAddress,
      subnetMask: subnetMask,
      router: router,
      dnsConfigType: dnsConfigType,
      dnsServers: dnsServers,
      dnsSearchDomains: dnsSearchDomains,
      wirelessAddress: wifiDevice?.hwAddress ?? "",
    );
  }

  /// Searches for an existing NetworkManager connection settings profile with matching SSID.
  Future<NetworkManagerSettingsConnection?> _findExistingConnection({
    NetworkManagerAccessPoint? accessPoint,
    String? ssid,
  }) async {
    try {
      final targetSsid = accessPoint != null
          ? utf8.decode(accessPoint.ssid)
          : ssid;

      for (final connection in _client.settings.connections) {
        if (connection.unsaved) {
          continue;
        }
        final settings = await connection.getSettings();
        final wireless = settings['802-11-wireless'];
        if (wireless == null) continue;

        final ssidValue = wireless['ssid'];
        if (ssidValue is! DBusArray) continue;

        final connectionSsid = String.fromCharCodes(
          ssidValue.children.map((e) => (e as DBusByte).value),
        );

        if (connectionSsid == targetSsid) {
          return connection;
        }
      }
    } catch (e) {
      AppLogger.e("Error finding connection: $e");
    }

    return null;
  }

  /// Retrives connection settings based on the access point SSID.
  @override
  Future<NetworkManagerSettingsConnection?> getAccessPointConnectionSettings(
    NetworkManagerDevice device,
    NetworkManagerAccessPoint accessPoint,
  ) async {
    var ssid = utf8.decode(accessPoint.ssid);

    var settings = await Future.wait(
      device.availableConnections.map(
        (e) async => {'settings': await e.getSettings(), 'connection': e},
      ),
    );
    NetworkManagerSettingsConnection? accessPointSettings;
    for (var element in settings) {
      var s = element['settings'] as dynamic;
      if (s != null) {
        var connection = s['connection'] as Map<String, DBusValue>?;
        if (connection != null) {
          var id = connection['id'];
          if (id != null) {
            if (id.toNative() == ssid) {
              accessPointSettings =
                  element['connection'] as NetworkManagerSettingsConnection;
              break;
            }
          }
        }
      }
    }
    return accessPointSettings;
  }

  /// Retrieves the saved Wi-Fi password (PSK) for a specific device and access point.
  @override
  Future<String?> getSavedWifiPsk(
    NetworkManagerDevice device,
    NetworkManagerAccessPoint accessPoint,
  ) async {
    var settingsConnection = await getAccessPointConnectionSettings(
      device,
      accessPoint,
    );
    if (settingsConnection != null) {
      var secrets = await settingsConnection.getSecrets(
        '802-11-wireless-security',
      );
      if (secrets.isNotEmpty) {
        var security = secrets['802-11-wireless-security'];
        if (security != null) {
          var psk = security['psk'] ?? security['wep-key0'];
          if (psk != null) {
            return psk.toNative();
          }
        }
      }
    }
    return null;
  }

  @override
  Stream<List<String>> getWifiEventsStream() {
    if (!_connected) return const Stream.empty();
    return _client.propertiesChanged;
  }

  @override
  Stream<List<String>> getWirelessDeviceEventsStream() {
    final wifiDevice = getWifiDevice();
    if (wifiDevice == null || wifiDevice.wireless == null) {
      return const Stream.empty();
    }
    return wifiDevice.wireless!.propertiesChanged;
  }

  @override
  Stream<List<String>> getDeviceEventsStream() {
    final wifiDevice = getWifiDevice();
    if (wifiDevice == null) return const Stream.empty();
    return wifiDevice.propertiesChanged;
  }

  /// Refreshes and returns the active and available access points.
  @override
  Future<({AccessPoints? active, List<AccessPoints> available})>
  availableAccessPoints({bool requestScan = true}) async {
    try {
      final wifiDevice = getWifiDevice();
      if (wifiDevice == null ||
          wifiDevice.state == NetworkManagerDeviceState.unavailable) {
        AppLogger.e('No WiFi device found');
        return (active: null, available: <AccessPoints>[]);
      }

      if (requestScan && wifiDevice.wireless != null) {
        try {
          await wifiDevice.wireless!.requestScan();
        } catch (e, stack) {
          AppLogger.e('Failed to request Wi-Fi scan.', error: e, stack: stack);
        }
      }

      final allSavedNetworks = await getSavedWirelessNetworks();
      final List<AccessPoints> accessPoints = [];
      final seenSsids = <String>{};
      final activeAccessPoint = wifiDevice.wireless?.activeAccessPoint;
      final nmAccessPoints = wifiDevice.wireless?.accessPoints ?? [];
      AccessPoints? connectedAccessPoint;

      final ip4Config = wifiDevice.ip4Config;
      final ip6Config = wifiDevice.ip6Config;

      for (final nmAccessPoint in nmAccessPoints) {
        final ssid = utf8.decode(nmAccessPoint.ssid);

        if (ssid.isNotEmpty && !seenSsids.contains(ssid)) {
          seenSsids.add(ssid);
          final isActive =
              listEquals(activeAccessPoint?.ssid, nmAccessPoint.ssid) &&
              wifiDevice.state == NetworkManagerDeviceState.activated;
          final isSaved = allSavedNetworks.any((sn) => sn.ssid == ssid);
          final isSecure =
              nmAccessPoint.wpaFlags.isNotEmpty ||
              nmAccessPoint.rsnFlags.isNotEmpty;

          if (isActive) {
            connectedAccessPoint = AccessPoints(
              isActive: isActive,
              isSaved: isSaved,
              isSecure: isSecure,
              nmAccessPoint: nmAccessPoint,
              ip4Config: ip4Config,
              ip6Config: ip6Config,
            );
          } else {
            final accessPoint = AccessPoints(
              nmAccessPoint: nmAccessPoint,
              isActive: isActive,
              isSaved: isSaved,
              isSecure: isSecure,
              ip4Config: ip4Config,
              ip6Config: ip6Config,
            );
            accessPoints.add(accessPoint);
          }
        }
      }
      return (active: connectedAccessPoint, available: accessPoints);
    } catch (e) {
      AppLogger.e('Error in availableAccessPoints: $e');
      return (active: null, available: <AccessPoints>[]);
    }
  }

  /// Retrieves SavedWirelessNetwork model representations of stored profiles.
  @override
  Future<List<SavedWirelessNetwork>> getSavedWirelessNetworks() async {
    if (!_connected) return [];
    try {
      final connections = _client.settings.connections;
      final List<SavedWirelessNetwork> savedNetworks = [];
      final seenBssids = <String>{};

      for (var cn in connections) {
        if (!cn.unsaved) {
          final connectionSettings = await cn.getSettings();
          final flatSettings = NetworkManagerUtils.flattenConnectionSettings(
            connectionSettings,
          );
          final String bssid =
              connectionSettings["802-11-wireless"]?["seen-bssids"]
                  ?.toString() ??
              '';

          if (!seenBssids.contains(bssid)) {
            seenBssids.add(bssid);

            final macAddress =
                flatSettings["802-11-wireless.seen-bssids"].toString() == 'null'
                ? ''
                : flatSettings["802-11-wireless.seen-bssids"].toString();

            final savedNetwork = SavedWirelessNetwork(
              ssid: flatSettings["connection.id"]?.toString(),
              macAddress: macAddress.replaceAll(RegExp(r'[\[\]]'), ''),
              security: flatSettings["802-11-wireless-security.key-mgmt"]
                  ?.toString(),
              ipv4Method: flatSettings["ipv4.method"]?.toString(),
              autoConnect: flatSettings["connection.autoconnect"] as bool?,
            );
            savedNetworks.add(savedNetwork);
          }
        }
      }
      return savedNetworks;
    } catch (e) {
      AppLogger.e('Error in getSavedWirelessNetworks: $e');
      return [];
    }
  }

  @override
  NetworkManagerDeviceState? getWifiDeviceState() {
    final device = getWifiDevice();
    return device?.state;
  }

  @override
  Future<List<WifiNetwork>> getMyNetworks({
    List<WifiNetwork>? savedNetworks,
  }) async {
    if (!_connected) return [];

    final saved = savedNetworks ?? await getSavedNetworks();
    final wifiDevice = getWifiDevice();

    if (wifiDevice == null) {
      return [];
    }

    final scannedAps = wifiDevice.wireless?.accessPoints ?? [];

    final visibleSsids = scannedAps
        .map((ap) => utf8.decode(ap.ssid))
        .where((ssid) => ssid.isNotEmpty)
        .toSet();

    // Always include currently connected network
    final connected = saved.firstWhereOrNull((n) => n.isConnected);
    if (connected != null) {
      visibleSsids.add(connected.name);
    }

    final myNetworks = saved
        .where((network) => visibleSsids.contains(network.name))
        .toList();

    myNetworks.sort((a, b) {
      if (a.isConnected && !b.isConnected) return -1;
      if (!a.isConnected && b.isConnected) return 1;

      return b.signalLevel.compareTo(a.signalLevel);
    });

    return myNetworks;
  }

  Future<({bool isConnected, NetworkManagerDevice? device})>
  _getConnectionState({
    required String name,
    NetworkManagerAccessPoint? ap,
  }) async {
    try {
      final device = await getWifiDevice();

      if (device?.state != NetworkManagerDeviceState.activated) {
        return (isConnected: false, device: device);
      }

      if (ap != null) {
        final activeAp = device?.wireless?.activeAccessPoint;

        return (
          isConnected: activeAp != null && listEquals(activeAp.ssid, ap.ssid),
          device: device,
        );
      }

      final activeConnection = device?.activeConnection;

      return (
        isConnected: activeConnection != null && activeConnection.id == name,
        device: device,
      );
    } catch (e, stack) {
      AppLogger.e(
        'Failed to determine connection state for "$name"',
        error: e,
        stack: stack,
      );

      return (isConnected: false, device: null);
    }
  }

  Future<String> _getPassword({
    required String name,
    required bool isConnected,
    required bool isSecured,
    NetworkManagerAccessPoint? ap,
    NetworkManagerSettingsConnection? connection,
    NetworkManagerDevice? wifiDevice,
  }) async {
    if (!isConnected || !isSecured) {
      return "";
    }

    try {
      final conn =
          connection ??
          await _findExistingConnection(accessPoint: ap, ssid: name);
      if (conn != null) {
        final secrets = await conn.getSecrets('802-11-wireless-security');
        final security = secrets['802-11-wireless-security'];
        final psk = security?['psk'] ?? security?['wep-key0'];
        if (psk != null) {
          final val = psk.toNative();
          if (val != null && val.toString().isNotEmpty) {
            return val.toString();
          }
        }
      }
    } catch (e, stack) {
      AppLogger.e('Failed to retrieve PSK for "$name"', error: e, stack: stack);
    }

    try {
      if (ap != null && wifiDevice != null) {
        return await getSavedWifiPsk(wifiDevice, ap) ?? "";
      }
    } catch (e) {
      AppLogger.e('Failed to get saved PSK', error: e);
    }

    return "";
  }

  /// Returns true if both IPv4 address-data entries contain
  /// identical address and prefix values.
  bool _hasMatchingIpv4AddressData(
    dynamic existingAddressData,
    dynamic updatedAddressData,
  ) {
    if (existingAddressData == null && updatedAddressData == null) {
      return true;
    }

    if (existingAddressData == null || updatedAddressData == null) {
      return false;
    }

    if (existingAddressData is! List || updatedAddressData is! List) {
      return false;
    }

    if (existingAddressData.length != updatedAddressData.length) {
      return false;
    }

    if (existingAddressData.isEmpty) {
      return true;
    }

    final existingAddress = existingAddressData.first;
    final updatedAddress = updatedAddressData.first;

    if (existingAddress is! Map || updatedAddress is! Map) {
      return false;
    }

    return existingAddress["address"] == updatedAddress["address"] &&
        existingAddress["prefix"] == updatedAddress["prefix"];
  }

  /// Returns true if the IPv4 configuration has changed.
  bool _hasIpv4SettingsChanged(
    Map<String, DBusValue> existingIpv4,
    Map<String, DBusValue> updatedIpv4,
  ) {
    final existingMethod = existingIpv4["method"]?.toNative();
    final updatedMethod = updatedIpv4["method"]?.toNative();

    if (existingMethod != updatedMethod) {
      return true;
    }

    if (updatedMethod == "manual") {
      if (existingIpv4["gateway"]?.toNative() !=
          updatedIpv4["gateway"]?.toNative()) {
        return true;
      }

      if (!_hasMatchingIpv4AddressData(
        existingIpv4["address-data"]?.toNative(),
        updatedIpv4["address-data"]?.toNative(),
      )) {
        return true;
      }
    }

    return existingIpv4.containsKey("addresses") !=
        updatedIpv4.containsKey("addresses");
  }

  /// Returns true if DNS server or search domain lists differ.
  bool _hasListChanged(dynamic existingList, dynamic updatedList) {
    if (existingList == null && updatedList == null) {
      return false;
    }

    if (existingList == null || updatedList == null) {
      return true;
    }

    if (existingList is! List || updatedList is! List) {
      return true;
    }

    if (existingList.length != updatedList.length) {
      return true;
    }

    for (var index = 0; index < existingList.length; index++) {
      if (existingList[index] != updatedList[index]) {
        return true;
      }
    }

    return false;
  }

  /// Returns true if DNS configuration has changed.
  bool _hasDnsSettingsChanged(
    Map<String, DBusValue> existingIpv4,
    Map<String, DBusValue> updatedIpv4,
    DNSConfigType dnsConfigType,
  ) {
    if (existingIpv4["ignore-auto-dns"]?.toNative() !=
        updatedIpv4["ignore-auto-dns"]?.toNative()) {
      return true;
    }

    if (dnsConfigType == DNSConfigType.manual) {
      if (_hasListChanged(
        existingIpv4["dns"]?.toNative(),
        updatedIpv4["dns"]?.toNative(),
      )) {
        return true;
      }

      if (_hasListChanged(
        existingIpv4["dns-search"]?.toNative(),
        updatedIpv4["dns-search"]?.toNative(),
      )) {
        return true;
      }
    } else {
      return existingIpv4.containsKey("dns") ||
          existingIpv4.containsKey("dns-search");
    }

    return false;
  }
}
