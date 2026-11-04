import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/utils/wifi_parser.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm/nm.dart';

class MockAccessPoint extends Mock implements NetworkManagerAccessPoint {}

void main() {
  group('WifiParser.parseSavedSecurity', () {
    Map<String, Map<String, DBusValue>> profile({String? keyMgmt}) => {
      '802-11-wireless': {'mode': const DBusString('infrastructure')},
      if (keyMgmt != null)
        '802-11-wireless-security': {'key-mgmt': DBusString(keyMgmt)},
    };

    test('returns null when there is no saved profile', () {
      expect(WifiParser.parseSavedSecurity(null), isNull);
      expect(
        WifiParser.parseSavedSecurity({
          'connection': {'id': const DBusString('eth')},
        }),
        isNull,
      );
    });

    test('returns none for a profile without a security section', () {
      expect(WifiParser.parseSavedSecurity(profile()), WirelessSecurity.none);
    });

    test('maps supported key management values', () {
      expect(
        WifiParser.parseSavedSecurity(profile(keyMgmt: 'wpa-psk')),
        WirelessSecurity.wpaWpa2Personal,
      );
      expect(
        WifiParser.parseSavedSecurity(profile(keyMgmt: 'sae')),
        WirelessSecurity.wpa3Personal,
      );
      expect(
        WifiParser.parseSavedSecurity(profile(keyMgmt: 'owe')),
        WirelessSecurity.enhancedOpen,
      );
      expect(
        WifiParser.parseSavedSecurity(profile(keyMgmt: 'none')),
        WirelessSecurity.wep,
      );
    });

    test('returns null for unsupported key management', () {
      expect(
        WifiParser.parseSavedSecurity(profile(keyMgmt: 'wpa-eap')),
        isNull,
      );
    });
  });

  group('WifiParser.parseScannedSecurity', () {
    MockAccessPoint ap(List<NetworkManagerWifiAccessPointSecurityFlag> rsn) {
      final mock = MockAccessPoint();
      when(
        () => mock.wpaFlags,
      ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);
      when(() => mock.rsnFlags).thenReturn(rsn);
      return mock;
    }

    test('returns null when the network is not in range', () {
      expect(WifiParser.parseScannedSecurity(null), isNull);
    });

    test('returns none for an open access point', () {
      expect(WifiParser.parseScannedSecurity(ap([])), WirelessSecurity.none);
    });

    test('returns WPA/WPA2 for a PSK access point', () {
      expect(
        WifiParser.parseScannedSecurity(
          ap([NetworkManagerWifiAccessPointSecurityFlag.keyManagementPsk]),
        ),
        WirelessSecurity.wpaWpa2Personal,
      );
    });

    test('returns WPA3 for an SAE access point', () {
      expect(
        WifiParser.parseScannedSecurity(
          ap([NetworkManagerWifiAccessPointSecurityFlag.keyManagementSae]),
        ),
        WirelessSecurity.wpa3Personal,
      );
    });
  });
}
