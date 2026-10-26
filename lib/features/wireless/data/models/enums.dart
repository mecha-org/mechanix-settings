import 'package:mechanix_settings/core/constants/icons.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

enum WirelessSecurity {
  none,
  wep,

  /// WPA/WPA2-PSK
  wpaWpa2Personal,

  /// WPA3-Personal (SAE)
  wpa3Personal,

  /// OWE
  enhancedOpen,
}

extension WirelessSecurityX on WirelessSecurity {
  String label(AppLocalizations l10n) {
    switch (this) {
      case WirelessSecurity.none:
        return l10n.none;

      case WirelessSecurity.wep:
        return l10n.wep;

      case WirelessSecurity.wpaWpa2Personal:
        return l10n.wpa2Personal;

      case WirelessSecurity.wpa3Personal:
        return l10n.wpa3Personal;

      case WirelessSecurity.enhancedOpen:
        return l10n.enhancedOpen;
    }
  }

  bool get requiresPassword {
    switch (this) {
      case WirelessSecurity.none:
      case WirelessSecurity.enhancedOpen:
        return false;

      default:
        return true;
    }
  }
}

enum PrivateAddressType { off, staticAddress, rotating }

extension PrivateAddressTypeX on PrivateAddressType {
  String label(AppLocalizations l10n) {
    switch (this) {
      case PrivateAddressType.off:
        return l10n.off;
      case PrivateAddressType.staticAddress:
        return l10n.staticOption;
      case PrivateAddressType.rotating:
        return l10n.rotating;
    }
  }
}

extension PrivateAddressTypeParsing on String {
  PrivateAddressType toPrivateAddressType() {
    return PrivateAddressType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => PrivateAddressType.off,
    );
  }
}

enum IPv4ConfigType { automatic, manual }

extension IPv4ConfigTypeX on IPv4ConfigType {
  String label(AppLocalizations l10n) {
    switch (this) {
      case IPv4ConfigType.automatic:
        return l10n.automatic;
      case IPv4ConfigType.manual:
        return l10n.manual;
    }
  }
}

extension IPv4ConfigTypeParsing on String {
  IPv4ConfigType toIPv4ConfigType() {
    return IPv4ConfigType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => IPv4ConfigType.automatic,
    );
  }
}

enum IPv6ConfigType { automatic, manual }

extension IPv6ConfigTypeX on IPv6ConfigType {
  String label(AppLocalizations l10n) {
    switch (this) {
      case IPv6ConfigType.automatic:
        return l10n.automatic;
      case IPv6ConfigType.manual:
        return l10n.manual;
    }
  }
}

extension IPv6ConfigTypeParsing on String {
  IPv6ConfigType toIPv6ConfigType() {
    return IPv6ConfigType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => IPv6ConfigType.automatic,
    );
  }
}

enum DNSConfigType { automatic, manual }

extension DNSConfigTypeX on DNSConfigType {
  String label(AppLocalizations l10n) {
    switch (this) {
      case DNSConfigType.automatic:
        return l10n.automatic;
      case DNSConfigType.manual:
        return l10n.manual;
    }
  }
}

extension DNSConfigTypeParsing on String {
  DNSConfigType toDNSConfigType() {
    return DNSConfigType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => DNSConfigType.automatic,
    );
  }
}

enum WifiSignalType {
  none,
  lowOpen,
  lowLocked,
  mediumOpen,
  mediumLocked,
  highOpen,
  highLocked,
  notFound;

  static WifiSignalType from({required int level, required bool secured}) {
    // Clamp to the supported range (0-3)
    switch (level.clamp(0, 3)) {
      case 0:
        return WifiSignalType.none;

      case 1:
        return secured ? WifiSignalType.lowLocked : WifiSignalType.lowOpen;

      case 2:
        return secured
            ? WifiSignalType.mediumLocked
            : WifiSignalType.mediumOpen;

      case 3:
      default:
        return secured ? WifiSignalType.highLocked : WifiSignalType.highOpen;
    }
  }
}

extension WifiSignalTypeIcon on WifiSignalType {
  String get asset {
    switch (this) {
      case WifiSignalType.none:
        return SettingIcons.wifiNone;

      case WifiSignalType.lowOpen:
        return SettingIcons.wifiLowOpen;

      case WifiSignalType.lowLocked:
        return SettingIcons.wifiLowLocked;

      case WifiSignalType.mediumOpen:
        return SettingIcons.wifiMediumOpen;

      case WifiSignalType.mediumLocked:
        return SettingIcons.wifiMediumLocked;

      case WifiSignalType.highOpen:
        return SettingIcons.wifiHighOpen;

      case WifiSignalType.highLocked:
        return SettingIcons.wifiHighLocked;

      case WifiSignalType.notFound:
        return SettingIcons.wifiNotFound;
    }
  }
}

enum WirelessErrorType { connectionFailed, addNetworkFailed, unknown }

enum WifiConnectionStatus {
  disconnected,
  connecting,
  authenticating,
  connected,
  connectedNoInternet,
  disconnecting,
  failed,
  timeout,
  networkNotFound,
  deviceUnavailable,
}
