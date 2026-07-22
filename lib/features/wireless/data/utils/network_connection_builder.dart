import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/utils/enterprise_connection_builder.dart';

class NetworkConnectionBuilder {
  const NetworkConnectionBuilder._();

  static void applySecuritySettings({
    required Map<String, Map<String, DBusValue>> connection,
    required WirelessSecurity security,
    EnterpriseConfig? enterpriseConfig,
  }) {
    switch (security) {
      case WirelessSecurity.none:
        break;

      case WirelessSecurity.wep:
        connection['802-11-wireless-security'] = {
          'key-mgmt': const DBusString('none'),
          'wep-key-flags': const DBusUint32(1),
        };
        break;

      case WirelessSecurity.wpaWpa2Personal:
        connection['802-11-wireless-security'] = {
          'key-mgmt': const DBusString('wpa-psk'),
          'psk-flags': const DBusUint32(1),
        };
        break;

      case WirelessSecurity.wpa3Personal:
        connection['802-11-wireless-security'] = {
          'key-mgmt': const DBusString('sae'),
          'psk-flags': const DBusUint32(1),
        };
        break;

      case WirelessSecurity.wpawpa2Enterprise:
        connection['802-11-wireless-security'] = {
          'key-mgmt': const DBusString('wpa-eap'),
        };

        connection['802-1x'] = EnterpriseConnectionBuilder.build8021xSettings(
          enterpriseConfig ??
              const EnterpriseConfig(method: EnterpriseEapMethod.peap),
        );

        break;

      case WirelessSecurity.leap:
        connection['802-11-wireless-security'] = {
          'key-mgmt': const DBusString('ieee8021x'),
        };

        connection['802-1x'] = EnterpriseConnectionBuilder.build8021xSettings(
          enterpriseConfig ??
              const EnterpriseConfig(method: EnterpriseEapMethod.leap),
        );

        break;

      case WirelessSecurity.enhancedOpen:
        connection['802-11-wireless-security'] = {
          'key-mgmt': const DBusString('owe'),
        };
        break;
    }
  }
}
