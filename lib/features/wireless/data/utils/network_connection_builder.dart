import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

class NetworkConnectionBuilder {
  const NetworkConnectionBuilder._();

  static void applySecuritySettings({
    required Map<String, Map<String, DBusValue>> connection,
    required WirelessSecurity security,
    String? password,
  }) {
    switch (security) {
      case WirelessSecurity.none:
        break;

      case WirelessSecurity.wep:
        final wepMap = <String, DBusValue>{
          'key-mgmt': const DBusString('none'),
        };
        if (password != null && password.isNotEmpty) {
          wepMap['wep-key0'] = DBusString(password);
        } else {
          wepMap['wep-key-flags'] = const DBusUint32(1);
        }
        connection['802-11-wireless-security'] = wepMap;
        break;

      case WirelessSecurity.wpaWpa2Personal:
        final wpaMap = <String, DBusValue>{
          'key-mgmt': const DBusString('wpa-psk'),
        };
        if (password != null && password.isNotEmpty) {
          wpaMap['psk'] = DBusString(password);
        } else {
          wpaMap['psk-flags'] = const DBusUint32(1);
        }
        connection['802-11-wireless-security'] = wpaMap;
        break;

      case WirelessSecurity.wpa3Personal:
        final saeMap = <String, DBusValue>{'key-mgmt': const DBusString('sae')};
        if (password != null && password.isNotEmpty) {
          saeMap['psk'] = DBusString(password);
        } else {
          saeMap['psk-flags'] = const DBusUint32(1);
        }
        connection['802-11-wireless-security'] = saeMap;
        break;

      case WirelessSecurity.enhancedOpen:
        connection['802-11-wireless-security'] = {
          'key-mgmt': const DBusString('owe'),
        };
        break;
    }
  }
}
