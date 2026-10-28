import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';

void main() {
  group('WifiNetwork.hasSecurityChanged', () {
    test('is true when a saved open network now advertises WPA', () {
      const network = WifiNetwork(
        name: 'Cafe',
        savedSecurity: WirelessSecurity.none,
        scannedSecurity: WirelessSecurity.wpaWpa2Personal,
      );
      expect(network.hasSecurityChanged, isTrue);
    });

    test('is true when a saved WPA2 network moved to WPA3', () {
      const network = WifiNetwork(
        name: 'Home',
        savedSecurity: WirelessSecurity.wpaWpa2Personal,
        scannedSecurity: WirelessSecurity.wpa3Personal,
      );
      expect(network.hasSecurityChanged, isTrue);
    });

    test('is false when saved and scanned security match', () {
      const network = WifiNetwork(
        name: 'Home',
        savedSecurity: WirelessSecurity.wpaWpa2Personal,
        scannedSecurity: WirelessSecurity.wpaWpa2Personal,
      );
      expect(network.hasSecurityChanged, isFalse);
    });

    test('is false when the network is not saved', () {
      const network = WifiNetwork(
        name: 'New',
        scannedSecurity: WirelessSecurity.wpaWpa2Personal,
      );
      expect(network.hasSecurityChanged, isFalse);
    });

    test('is false when the network is not in range', () {
      const network = WifiNetwork(
        name: 'Away',
        savedSecurity: WirelessSecurity.none,
      );
      expect(network.hasSecurityChanged, isFalse);
    });
  });

  group('WifiNetwork.effectiveSecurity', () {
    test('prefers the security advertised by the access point', () {
      const network = WifiNetwork(
        name: 'Home',
        security: WirelessSecurity.wpaWpa2Personal,
        scannedSecurity: WirelessSecurity.wpa3Personal,
      );
      expect(network.effectiveSecurity, WirelessSecurity.wpa3Personal);
    });

    test('falls back to security when not in range', () {
      const network = WifiNetwork(
        name: 'Home',
        security: WirelessSecurity.wep,
      );
      expect(network.effectiveSecurity, WirelessSecurity.wep);
    });
  });

  test('copyWith and equality include saved and scanned security', () {
    const base = WifiNetwork(name: 'Home');
    final updated = base.copyWith(
      savedSecurity: WirelessSecurity.none,
      scannedSecurity: WirelessSecurity.wpaWpa2Personal,
    );

    expect(updated.savedSecurity, WirelessSecurity.none);
    expect(updated.scannedSecurity, WirelessSecurity.wpaWpa2Personal);
    expect(updated, isNot(base));
  });
}
