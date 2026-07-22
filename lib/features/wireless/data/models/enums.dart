import 'package:mechanix_settings/l10n/app_localizations.dart';
import 'package:mechanix_settings/core/constants/icons.dart';

enum WirelessSecurity {
  none,
  wep,

  /// WPA/WPA2-PSK
  wpaWpa2Personal,

  /// WPA3-Personal (SAE)
  wpa3Personal,

  /// WPA/WPA2 Enterprise (802.1X)
  wpawpa2Enterprise,

  /// LEAP
  leap,

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

      case WirelessSecurity.wpawpa2Enterprise:
        return l10n.wpaEnterprise;

      case WirelessSecurity.leap:
        return l10n.leap;

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

/// Enterprise wireless security
enum EnterpriseEapMethod { peap, tls, ttls, pwd, leap }

extension EnterpriseEapMethodX on EnterpriseEapMethod {
  String label(AppLocalizations l10n) {
    switch (this) {
      case EnterpriseEapMethod.peap:
        return l10n.peap;
      case EnterpriseEapMethod.tls:
        return l10n.tls;
      case EnterpriseEapMethod.ttls:
        return l10n.ttls;
      case EnterpriseEapMethod.pwd:
        return l10n.pwd;
      case EnterpriseEapMethod.leap:
        return l10n.leap;
    }
  }

  String get nmValue {
    switch (this) {
      case EnterpriseEapMethod.peap:
        return "peap";
      case EnterpriseEapMethod.tls:
        return "tls";
      case EnterpriseEapMethod.ttls:
        return "ttls";
      case EnterpriseEapMethod.pwd:
        return "pwd";
      case EnterpriseEapMethod.leap:
        return "leap";
    }
  }

  List<EnterprisePhase2Auth> get supportedPhase2 {
    switch (this) {
      case EnterpriseEapMethod.peap:
        return const [
          EnterprisePhase2Auth.mschapv2,
          EnterprisePhase2Auth.md5,
          EnterprisePhase2Auth.gtc,
        ];

      case EnterpriseEapMethod.ttls:
        return const [
          EnterprisePhase2Auth.pap,
          EnterprisePhase2Auth.chap,
          EnterprisePhase2Auth.mschap,
          EnterprisePhase2Auth.mschapv2,
          EnterprisePhase2Auth.mschapv2NoEap,
          EnterprisePhase2Auth.md5,
          EnterprisePhase2Auth.gtc,
        ];

      case EnterpriseEapMethod.tls:
      case EnterpriseEapMethod.pwd:
      case EnterpriseEapMethod.leap:
        return const [];
    }
  }
}

enum PeapVersion { automatic, version0, version1 }

extension PeapVersionX on PeapVersion {
  /// Value expected by NetworkManager
  String? get nmValue {
    switch (this) {
      case PeapVersion.automatic:
        return null;
      case PeapVersion.version0:
        return '0';
      case PeapVersion.version1:
        return '1';
    }
  }

  /// UI only
  String Function(AppLocalizations) get label {
    switch (this) {
      case PeapVersion.automatic:
        return (l10n) => l10n.automatic;

      case PeapVersion.version0:
        return (l10n) => l10n.version0;

      case PeapVersion.version1:
        return (l10n) => l10n.version1;
    }
  }
}

enum EnterprisePhase2Auth {
  pap,
  chap,

  mschap,
  mschapv2,
  mschapv2NoEap,

  md5,
  gtc,
}

extension EnterprisePhase2AuthX on EnterprisePhase2Auth {
  /// Display text
  String label(AppLocalizations l10n) {
    switch (this) {
      case EnterprisePhase2Auth.pap:
        return l10n.pap;

      case EnterprisePhase2Auth.chap:
        return l10n.chap;

      case EnterprisePhase2Auth.mschap:
        return l10n.mschap;

      case EnterprisePhase2Auth.mschapv2:
        return l10n.mschapv2;

      case EnterprisePhase2Auth.mschapv2NoEap:
        return l10n.mschapv2NoEap;

      case EnterprisePhase2Auth.md5:
        return l10n.md5;

      case EnterprisePhase2Auth.gtc:
        return l10n.gtc;
    }
  }

  /// Value expected by NetworkManager
  String get nmValue {
    switch (this) {
      case EnterprisePhase2Auth.pap:
        return 'pap';

      case EnterprisePhase2Auth.chap:
        return 'chap';

      case EnterprisePhase2Auth.mschap:
        return 'mschap';

      case EnterprisePhase2Auth.mschapv2:
      case EnterprisePhase2Auth.mschapv2NoEap:
        return 'mschapv2';

      case EnterprisePhase2Auth.md5:
        return 'md5';

      case EnterprisePhase2Auth.gtc:
        return 'gtc';
    }
  }

  /// Whether this authentication method should use
  /// `phase2-autheap` instead of `phase2-auth`.
  bool get usesAutoHeap => this == EnterprisePhase2Auth.mschapv2NoEap;
}

enum CertificateType { none, file }

enum WirelessErrorType { connectionFailed, addNetworkFailed, unknown }
