import 'package:mechanix_settings/features/wireless/data/utils/network_manager_utils.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class IpValidationUtils {
  const IpValidationUtils._();

  static int _toUint32(String ip) {
    try {
      return ip
          .split('.')
          .map(int.parse)
          .fold(0, (acc, octet) => (acc << 8) | octet);
    } catch (_) {
      return 0;
    }
  }

  static bool isValidIPv4(String ip) {
    return RegExp(
      r'^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$',
    ).hasMatch(ip);
  }

  static bool isUnspecifiedAddress(String ip) => ip == '0.0.0.0';

  static bool isLoopbackAddress(String ip) => ip.startsWith('127.');

  static bool isMulticastAddress(String ip) {
    final value = _toUint32(ip);

    return value >= _toUint32('224.0.0.0') &&
        value <= _toUint32('239.255.255.255');
  }

  static bool isValidPrefix(int prefix) => prefix >= 1 && prefix <= 30;

  static bool isNetworkAddress(String ip, int prefix) {
    final ipValue = _toUint32(ip);
    final mask = (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;

    return (ipValue & ~mask) == 0;
  }

  static bool isBroadcastAddress(String ip, int prefix) {
    final ipValue = _toUint32(ip);
    final mask = (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;

    return (ipValue | mask) == 0xFFFFFFFF;
  }

  static bool isGatewayInSubnet(String address, String gateway, int prefix) {
    final mask = (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;

    return (_toUint32(address) & mask) == (_toUint32(gateway) & mask);
  }

  static bool isGatewayNotSelf(String address, String gateway) {
    return address != gateway;
  }

  /// Returns null when valid, otherwise the localized error message.
  static String? validateManualIpConfig({
    required String ip,
    required String subnetMask,
    required String gateway,
    required AppLocalizations l10n,
  }) {
    // IP Address
    if (!isValidIPv4(ip)) {
      return l10n.invalidIpAddress;
    }

    if (isUnspecifiedAddress(ip)) {
      return l10n.unspecifiedIpAddress;
    }

    if (isLoopbackAddress(ip)) {
      return l10n.loopbackIpAddress;
    }

    if (isMulticastAddress(ip)) {
      return l10n.multicastIpAddress;
    }

    // Subnet Mask / Prefix
    if (subnetMask.isEmpty) {
      return l10n.invalidSubnetMask;
    }

    int? prefix;

    if (subnetMask.contains('.')) {
      if (!isValidIPv4(subnetMask)) {
        return l10n.invalidSubnetMask;
      }

      prefix = NetworkManagerUtils.subnetMaskToPrefix(subnetMask);

      if (prefix == null) {
        return l10n.invalidSubnetMask;
      }
    } else {
      prefix = int.tryParse(subnetMask);

      if (prefix == null) {
        return l10n.invalidSubnetPrefix;
      }
    }

    if (!isValidPrefix(prefix)) {
      return l10n.invalidSubnetPrefixRange;
    }

    if (isNetworkAddress(ip, prefix)) {
      return l10n.networkAddressNotAllowed;
    }

    if (isBroadcastAddress(ip, prefix)) {
      return l10n.broadcastAddressNotAllowed;
    }

    // Gateway
    if (!isValidIPv4(gateway)) {
      return l10n.invalidGateway;
    }

    if (!isGatewayInSubnet(ip, gateway, prefix)) {
      return l10n.gatewayDifferentSubnet;
    }

    if (!isGatewayNotSelf(ip, gateway)) {
      return l10n.gatewaySameAsIp;
    }

    return null;
  }

  static bool isValidDnsList(List<String> dns) =>
      dns.every(IpValidationUtils.isValidIPv4) &&
      dns.every((ip) => !ip.startsWith('127.') && ip != '0.0.0.0') &&
      dns.toSet().length == dns.length;
}
