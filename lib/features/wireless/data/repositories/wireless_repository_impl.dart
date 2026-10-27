import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/wireless/data/models/access_points.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/saved_networks.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/models/wireless_exceptions.dart';
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
          final ssidBytes = ssidValue.children
              .whereType<DBusByte>()
              .map((e) => e.value)
              .toList();
          final ssid = utf8.decode(ssidBytes, allowMalformed: true);

          if (ssid.isEmpty) {
            continue;
          }

          final ap = scannedAps.firstWhereOrNull(
            (a) => utf8.decode(a.ssid, allowMalformed: true) == ssid,
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

  /// Re-reads one network by SSID without scanning.
  /// [WirelessRepository.getNetworkDetails].
  @override
  Future<WifiNetwork?> getNetworkDetails(String name) async {
    if (!_connected || name.isEmpty) return null;

    try {
      final wifiDevice = getWifiDevice();
      final scannedAps = wifiDevice?.wireless?.accessPoints ?? [];
      final ap = scannedAps.firstWhereOrNull(
        (a) => utf8.decode(a.ssid, allowMalformed: true) == name,
      );

      WifiNetwork? result;

      for (final connection in _client.settings.connections) {
        try {
          if (connection.unsaved) continue;

          final settings = await connection.getSettings();
          if (_ssidFromSettings(settings) != name) continue;

          final network = await _mapToWifiNetwork(
            name: name,
            ap: ap,
            connection: connection,
            connectionSettings: settings,
          );

          // Same rule as getSavedNetworks: the active profile wins when
          // several profiles share the SSID.
          if (result == null || network.isConnected) {
            result = network;
          }
          if (network.isConnected) break;
        } catch (e) {
          AppLogger.e('Error reading connection for $name: $e');
        }
      }

      if (result != null) return result;

      // Not saved: fall back to the access point if it is in range.
      if (ap != null) {
        return await _mapToWifiNetwork(name: name, ap: ap);
      }
      return null;
    } catch (e, stack) {
      AppLogger.e('Error in getNetworkDetails: $e', stack: stack);
      return null;
    }
  }

  /// Decodes the SSID of a saved Wi-Fi profile, or `null` when [settings] is
  /// not a Wi-Fi connection.
  String? _ssidFromSettings(Map<String, Map<String, DBusValue>> settings) {
    final ssidValue = settings['802-11-wireless']?['ssid'];
    if (ssidValue is! DBusArray) return null;

    final ssidBytes = ssidValue.children
        .whereType<DBusByte>()
        .map((e) => e.value)
        .toList();
    return utf8.decode(ssidBytes, allowMalformed: true);
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
            NetworkManagerDeviceState.deactivating,
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
                final ssidBytes = ssidVal.children
                    .whereType<DBusByte>()
                    .map((e) => e.value)
                    .toList();
                final ssid = utf8.decode(ssidBytes, allowMalformed: true);
                savedSsids.add(ssid);
              }
            }
          }
        }
      }

      final seenSsids = <String>{};
      for (var ap in scannedAps) {
        final ssid = utf8.decode(ap.ssid, allowMalformed: true);
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
  @override
  Future<void> connectToNetwork(
    String name,
    String? password, {
    bool autoConnect = true,
  }) async {
    if (!_connected) return;
    final wifiDevice = getWifiDevice();
    if (wifiDevice == null ||
        wifiDevice.state == NetworkManagerDeviceState.unavailable) {
      throw Exception('No WiFi device found');
    }

    final scannedAps = wifiDevice.wireless?.accessPoints ?? [];
    final ap = scannedAps.firstWhereOrNull(
      (a) => utf8.decode(a.ssid, allowMalformed: true) == name,
    );

    // Search for an existing saved NetworkManager connection settings profile.
    final existingConnection = await _findExistingConnection(
      accessPoint: ap,
      ssid: name,
    );

    final hasPassword = password != null && password.isNotEmpty;
    final apSecured =
        ap != null && (ap.wpaFlags.isNotEmpty || ap.rsnFlags.isNotEmpty);
    final currentKeyMgmt = apSecured
        ? NetworkManagerUtils.keyMgmtFromAccessPoint(ap)
        : null;

    if (existingConnection != null) {
      final settings = await existingConnection.getSettings();

      final savedKeyMgmt =
          (settings['802-11-wireless-security']?['key-mgmt'] ??
                  settings['wireless-security']?['key-mgmt'])
              ?.toNative()
              ?.toString();

      // Out of range (or hidden): trust the saved profile's security.
      final targetKeyMgmt = ap != null ? currentKeyMgmt : savedKeyMgmt;
      final securityChanged = ap != null && savedKeyMgmt != currentKeyMgmt;

      if (securityChanged && targetKeyMgmt != null && !hasPassword) {
        // The saved credentials cannot work with the new security. Ask the
        // user instead of replacing the profile with an empty password.
        AppLogger.i(
          'Security of "$name" changed ($savedKeyMgmt → $targetKeyMgmt). '
          'Password required.',
        );
        throw WifiPasswordRequiredException(
          networkName: name,
          security: _securityFromKeyMgmt(targetKeyMgmt),
        );
      }

      if (securityChanged || hasPassword) {
        // Update the existing profile in place so IP/DNS customisations and
        // the autoconnect choice are kept.
        AppLogger.i(
          'Updating security of "$name" ($savedKeyMgmt → $targetKeyMgmt).',
        );
        await existingConnection.update(
          _withSecurity(settings, targetKeyMgmt, password),
        );
      } else if (targetKeyMgmt != null &&
          await _isSecretMissing(existingConnection, settings)) {
        throw WifiPasswordRequiredException(
          networkName: name,
          security: _securityFromKeyMgmt(targetKeyMgmt),
        );
      }

      await _client.activateConnection(
        connection: existingConnection,
        device: wifiDevice,
      );
      return;
    }

    if (ap != null) {
      if (currentKeyMgmt != null) {
        if (!hasPassword) {
          throw WifiPasswordRequiredException(
            networkName: name,
            security: _securityFromKeyMgmt(currentKeyMgmt),
          );
        }

        final connection = <String, Map<String, DBusValue>>{
          'connection': {
            'id': DBusString(name),
            'type': const DBusString('802-11-wireless'),
            'autoconnect': DBusBoolean(autoConnect),
          },
          '802-11-wireless': {
            'ssid': DBusArray(
              DBusSignature.byte,
              utf8.encode(name).map((b) => DBusByte(b)).toList(),
            ),
            'mode': const DBusString('infrastructure'),
          },
          '802-11-wireless-security': _securitySettings(
            currentKeyMgmt,
            password,
          ),
          'ipv4': {'method': const DBusString('auto')},
          'ipv6': {'method': const DBusString('auto')},
        };

        await _client.addAndActivateConnection(
          device: wifiDevice,
          accessPoint: ap,
          connection: connection,
        );
      } else {
        await _client.addAndActivateConnection(
          device: wifiDevice,
          accessPoint: ap,
        );
      }
    }
  }

  /// `802-11-wireless-security` settings for [keyMgmt] with [password].
  static Map<String, DBusValue> _securitySettings(
    String keyMgmt,
    String password,
  ) {
    if (keyMgmt == 'none') {
      // WEP: the key goes in wep-key0, not psk.
      return {
        'key-mgmt': const DBusString('none'),
        'wep-key0': DBusString(password),
        'wep-key-type': const DBusUint32(1),
        // 0 = stored by NetworkManager itself, so no secret agent (GNOME
        // dialog) is asked for it on later connections.
        'wep-key-flags': const DBusUint32(0),
      };
    }
    return {
      'key-mgmt': DBusString(keyMgmt),
      'psk': DBusString(password),
      'psk-flags': const DBusUint32(0),
    };
  }

  /// Copy of [settings] with its security replaced for [keyMgmt]
  /// (`null` = open network).
  static Map<String, Map<String, DBusValue>> _withSecurity(
    Map<String, Map<String, DBusValue>> settings,
    String? keyMgmt,
    String? password,
  ) {
    final updated = Map<String, Map<String, DBusValue>>.from(settings)
      ..remove('802-11-wireless-security')
      ..remove('wireless-security');

    final wireless = Map<String, DBusValue>.from(
      settings['802-11-wireless'] ?? {},
    )..remove('security');

    if (keyMgmt != null) {
      updated['802-11-wireless-security'] = _securitySettings(
        keyMgmt,
        password ?? '',
      );
    }
    updated['802-11-wireless'] = wireless;
    return updated;
  }

  /// Whether a secured saved profile has no secret NetworkManager can use.
  ///
  /// When the secret is missing, activating the profile makes NetworkManager
  /// ask a registered secret agent (e.g. the GNOME password dialog). Checking
  /// first lets the app show its own password sheet instead.
  ///
  /// Agent-owned secrets are checked too: `GetSecrets` returns them when the
  /// owning agent runs in this session and has them; otherwise the agent
  /// would prompt, so they count as missing. A D-Bus error falls back to a
  /// normal activation.
  Future<bool> _isSecretMissing(
    NetworkManagerSettingsConnection connection,
    Map<String, Map<String, DBusValue>> settings,
  ) async {
    try {
      final security = settings['802-11-wireless-security'];
      final flagsValue = (security?['psk-flags'] ?? security?['wep-key-flags'])
          ?.toNative();
      final flags = flagsValue is int ? flagsValue : 0;

      const notSaved = 0x2;
      if (flags & notSaved != 0) return true;

      final secrets = await connection.getSecrets('802-11-wireless-security');
      final section = secrets['802-11-wireless-security'];
      final secret = (section?['psk'] ?? section?['wep-key0'])?.toNative();
      return secret == null || secret.toString().isEmpty;
    } catch (e) {
      AppLogger.e('Could not read stored secret: $e');
      return false;
    }
  }

  static WirelessSecurity _securityFromKeyMgmt(String keyMgmt) {
    switch (keyMgmt) {
      case 'sae':
        return WirelessSecurity.wpa3Personal;
      case 'wpa-psk':
        return WirelessSecurity.wpaWpa2Personal;
      case 'owe':
        return WirelessSecurity.enhancedOpen;
      default:
        return WirelessSecurity.wep;
    }
  }

  /// Creates and immediately activates a hidden Wi-Fi network profile.
  ///
  /// If a saved profile with the same SSID already exists, it is reused instead
  /// of creating a duplicate connection.
  @override
  Future<void> addNetwork(
    String name,
    WirelessSecurity security, {
    String? password,
  }) async {
    final wifiDevice = getWifiDevice();

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
    // Security-specific configuration (WEP/WPA/WPA3) is applied
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

    // Apply security configuration.
    NetworkConnectionBuilder.applySecuritySettings(
      connection: connection,
      security: security,
      password: password,
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

        await _client.activateConnection(connection: cn, device: wifiDevice);

        break;
      }
    } catch (e) {
      AppLogger.e("Failed to update IP settings: $e");
    }
  }

  @override
  Future<void> updateIPv6Settings(
    WifiNetwork network,
    IPv6ConfigType ipv6ConfigType,
    String ipv6Address,
    int ipv6Prefix,
    String ipv6Gateway,
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

        final ipv6 = Map<String, DBusValue>.from(settings["ipv6"] ?? {});

        if (ipv6ConfigType == IPv6ConfigType.manual) {
          ipv6["method"] = const DBusString("manual");

          ipv6["address-data"] = DBusArray(DBusSignature("a{sv}"), [
            DBusDict.stringVariant({
              "address": DBusString(ipv6Address),
              "prefix": DBusUint32(ipv6Prefix),
            }),
          ]);

          if (ipv6Gateway.isNotEmpty) {
            ipv6["gateway"] = DBusString(ipv6Gateway);
          } else {
            ipv6.remove("gateway");
          }

          ipv6.remove("addresses");
        } else {
          ipv6["method"] = const DBusString("auto");
          ipv6.remove("address-data");
          ipv6.remove("gateway");
          ipv6.remove("addresses");
        }

        updatedSettings["ipv6"] = ipv6;

        await cn.update(updatedSettings);

        if (wifiDevice.activeConnection != null) {
          try {
            await _client.deactivateConnection(wifiDevice.activeConnection!);
          } catch (e, stack) {
            AppLogger.e(
              'Failed to deactivate current Wi-Fi connection before applying IPv6 settings.',
              error: e,
              stack: stack,
            );
          }
        }

        await _client.activateConnection(connection: cn, device: wifiDevice);

        break;
      }
    } catch (e) {
      AppLogger.e("Failed to update IPv6 settings: $e");
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

    final signalLevel = WifiParser.parseSignalLevel(ap);

    final connectionState = await _getConnectionState(name: name, ap: ap);

    final isConnected = connectionState.isConnected;
    final wifiDevice = connectionState.device;

    final password = await _getPassword(
      name: name,
      ap: ap,
      connection: connection,
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

    final ipv6Settings = WifiParser.parseIPv6Settings(settings);

    var ipv6Address = ipv6Settings.ipv6Address;
    var ipv6Prefix = ipv6Settings.ipv6Prefix;
    var ipv6Gateway = ipv6Settings.ipv6Gateway;
    var ipv6ConfigType = ipv6Settings.ipv6ConfigType;

    if (isConnected && wifiDevice != null) {
      final ip6Config = wifiDevice.ip6Config;

      if (ipv6ConfigType == IPv6ConfigType.automatic &&
          ip6Config != null &&
          ip6Config.addressData.isNotEmpty) {
        final addr = ip6Config.addressData.first;

        ipv6Address = addr["address"] ?? ipv6Address;

        final prefix = addr["prefix"] as int?;
        if (prefix != null) {
          ipv6Prefix = prefix;
        }

        if (ip6Config.gateway.isNotEmpty) {
          ipv6Gateway = ip6Config.gateway;
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
      savedSecurity: WifiParser.parseSavedSecurity(settings),
      scannedSecurity: WifiParser.parseScannedSecurity(ap),
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
      ipv6ConfigType: ipv6ConfigType,
      ipv6Address: ipv6Address,
      ipv6Prefix: ipv6Prefix,
      ipv6Gateway: ipv6Gateway,
    );
  }

  /// Searches for an existing NetworkManager connection settings profile with matching SSID.
  Future<NetworkManagerSettingsConnection?> _findExistingConnection({
    NetworkManagerAccessPoint? accessPoint,
    String? ssid,
  }) async {
    try {
      final targetSsid = accessPoint != null
          ? utf8.decode(accessPoint.ssid, allowMalformed: true)
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

        final ssidBytes = ssidValue.children
            .whereType<DBusByte>()
            .map((e) => e.value)
            .toList();
        final connectionSsid = utf8.decode(ssidBytes, allowMalformed: true);

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
    var ssid = utf8.decode(accessPoint.ssid, allowMalformed: true);

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
        final ssid = utf8.decode(nmAccessPoint.ssid, allowMalformed: true);

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

            final savedSsid =
                flatSettings["802-11-wireless.ssid"]?.toString() ??
                flatSettings["connection.id"]?.toString();

            final savedNetwork = SavedWirelessNetwork(
              ssid: savedSsid,
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
        .map((ap) => utf8.decode(ap.ssid, allowMalformed: true))
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
        if (activeAp != null) {
          return (
            isConnected: listEquals(activeAp.ssid, ap.ssid),
            device: device,
          );
        }
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
    required bool isSecured,
    NetworkManagerAccessPoint? ap,
    NetworkManagerSettingsConnection? connection,
    NetworkManagerDevice? wifiDevice,
  }) async {
    if (!isSecured) {
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

  @override
  NetworkManagerConnectivityState getConnectivityState() {
    if (!_connected) return NetworkManagerConnectivityState.unknown;
    return _client.connectivity;
  }

  /// Returns whether NetworkManager has detected the current Wi-Fi connection
  /// as being behind a captive portal.
  @override
  Future<bool> isCaptivePortal() async {
    if (!_connected) return false;
    try {
      return _client.connectivity == NetworkManagerConnectivityState.portal;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to check captive portal state',
        error: e,
        stack: stack,
      );
      return false;
    }
  }

  /// Opens the captive portal login page by requesting the configured
  /// connectivity check URL and launching the redirected portal URL, if present.
  @override
  Future<void> openCaptivePortal() async {
    if (!_connected) {
      AppLogger.e('Cannot open captive portal: Wi-Fi is not connected');
      return;
    }

    final checkUri = _client.connectivityCheckUri;
    AppLogger.d('Connectivity check URI: $checkUri');

    if (checkUri.isEmpty) {
      AppLogger.e('No connectivity check URI configured');
      return;
    }

    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);

    try {
      // Request the connectivity check URL to detect the captive portal redirect.
      final request = await httpClient.getUrl(Uri.parse(checkUri));

      // Keep redirects disabled to capture the portal login URL from the response.
      request.followRedirects = false;

      final response = await request.close();

      // Captive portals usually redirect the connectivity check request to a login page.
      final portalUrl = response.headers.value(HttpHeaders.locationHeader);

      final targetUrl = portalUrl ?? checkUri;

      AppLogger.d('Opening captive portal URL: $targetUrl');

      // TODO: Implement platform-specific logic to open the URL
      // Launch the portal URL using the system's default browser.

      await Process.run('xdg-open', [targetUrl]);
    } catch (e, stack) {
      AppLogger.e('Failed to open captive portal', error: e, stack: stack);
    } finally {
      // Release HTTP resources after the connectivity check completes.
      httpClient.close();
    }
  }

  @override
  Future<void> close() async {
    try {
      if (_connected) {
        _connected = false;
        await _client.close();
      }
    } catch (e, stack) {
      AppLogger.e(
        'Failed to close NetworkManagerClient',
        error: e,
        stack: stack,
      );
    }
  }
}
