import 'dart:convert';

import 'package:dbus/dbus.dart';
import 'package:nm/nm.dart';

class NetworkManagerUtils {
  static String prefixToSubnetMask(int prefix) {
    final mask = (0xffffffff << (32 - prefix)) & 0xffffffff;

    return '${(mask >> 24) & 0xff}.'
        '${(mask >> 16) & 0xff}.'
        '${(mask >> 8) & 0xff}.'
        '${mask & 0xff}';
  }

  /// Converts a subnet mask string (e.g. 255.255.255.0) to CIDR prefix length (e.g. 24).
  static int? subnetMaskToPrefix(String mask) {
    // Allow passing a prefix directly (e.g. "24")
    final prefix = int.tryParse(mask);
    if (prefix != null) {
      return (prefix >= 0 && prefix <= 32) ? prefix : null;
    }

    final parts = mask.split('.');
    if (parts.length != 4) {
      return null;
    }

    int value = 0;

    for (final part in parts) {
      final octet = int.tryParse(part);

      if (octet == null || octet < 0 || octet > 255) {
        return null;
      }

      value = (value << 8) | octet;
    }

    int prefixLength = 0;
    bool zeroFound = false;

    for (int i = 31; i >= 0; i--) {
      final bit = (value >> i) & 1;

      if (bit == 1) {
        if (zeroFound) {
          // Invalid non-contiguous subnet mask
          return null;
        }
        prefixLength++;
      } else {
        zeroFound = true;
      }
    }

    return prefixLength;
  }

  /// Converts a uint32 integer representation of an IP address to a dot-decimal string.
  static String uint32ToIp(int val) {
    return '${val & 0xff}.'
        '${(val >> 8) & 0xff}.'
        '${(val >> 16) & 0xff}.'
        '${(val >> 24) & 0xff}';
  }

  /// Converts a dot-decimal IP address string to its uint32 integer representation.
  static int ipv4ToUint32(String ip) {
    final parts = ip.split('.').map(int.parse).toList();

    if (parts.length != 4) {
      throw ArgumentError('Invalid IPv4 address: $ip');
    }

    return parts[0] | (parts[1] << 8) | (parts[2] << 16) | (parts[3] << 24);
  }

  /// Flattens nested connection settings map into flat dot-delimited key names.
  static Map<String, dynamic> flattenConnectionSettings(
    Map<String, Map<String, DBusValue>> rawSettings,
  ) {
    final flat = <String, dynamic>{};

    rawSettings.forEach((section, entries) {
      entries.forEach((key, value) {
        flat['$section.$key'] = dbusValueToDart(value, keyName: key);
      });
    });

    return flat;
  }

  /// Converts DBusValue representation of properties to native Dart equivalents.
  static dynamic dbusValueToDart(DBusValue value, {String? keyName}) {
    if (value is DBusString ||
        value is DBusInt32 ||
        value is DBusUint32 ||
        value is DBusInt64 ||
        value is DBusUint64 ||
        value is DBusDouble ||
        value is DBusBoolean) {
      return value.toNative();
    }

    if (value is DBusArray &&
        value.signature == DBusSignature('y') &&
        (keyName == 'ssid' ||
            keyName?.toLowerCase().contains('ssid') == true)) {
      final bytes = value.children
          .whereType<DBusByte>()
          .map((e) => e.value)
          .toList();

      try {
        return utf8.decode(bytes);
      } catch (_) {
        return bytes;
      }
    }

    if (value is DBusArray) {
      return value.children.map((e) => dbusValueToDart(e)).toList();
    }

    if (value is DBusDict) {
      return value.children.map(
        (key, value) => MapEntry(dbusValueToDart(key), dbusValueToDart(value)),
      );
    }

    if (value is DBusVariant) {
      return dbusValueToDart(value.value);
    }

    if (value is DBusByte) {
      return value.value;
    }

    return value;
  }

  static String? keyMgmtFromAccessPoint(NetworkManagerAccessPoint? ap) {
    if (ap == null) return null;

    final flags = {...ap.wpaFlags, ...ap.rsnFlags};

    if (flags.contains(
      NetworkManagerWifiAccessPointSecurityFlag.keyManagementSae,
    )) {
      return 'sae';
    }

    if (flags.contains(
      NetworkManagerWifiAccessPointSecurityFlag.keyManagement802_1X,
    )) {
      return 'wpa-eap';
    }

    if (flags.contains(
      NetworkManagerWifiAccessPointSecurityFlag.keyManagementPsk,
    )) {
      return 'wpa-psk';
    }

    return 'none';
  }
}
