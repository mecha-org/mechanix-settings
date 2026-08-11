import 'dart:convert';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm/nm.dart';

class MockNetworkManagerClient extends Mock implements NetworkManagerClient {}

class MockNetworkManagerDevice extends Mock implements NetworkManagerDevice {}

class MockNetworkManagerDeviceWireless extends Mock
    implements NetworkManagerDeviceWireless {}

class MockNetworkManagerSettings extends Mock
    implements NetworkManagerSettings {}

class MockNetworkManagerSettingsConnection extends Mock
    implements NetworkManagerSettingsConnection {}

class MockNetworkManagerAccessPoint extends Mock
    implements NetworkManagerAccessPoint {
  @override
  int get strength {
    try {
      return super.noSuchMethod(Invocation.getter(#strength)) as int;
    } catch (_) {
      return 0;
    }
  }

  @override
  int get frequency {
    try {
      return super.noSuchMethod(Invocation.getter(#frequency)) as int;
    } catch (_) {
      return 0;
    }
  }
}

class MockNetworkManagerActiveConnection extends Mock
    implements NetworkManagerActiveConnection {}

class MockNetworkManagerIP4Config extends Mock
    implements NetworkManagerIP4Config {}

void main() {
  late WirelessRepositoryImpl repository;
  late MockNetworkManagerClient mockClient;
  late MockNetworkManagerDevice mockWifiDevice;
  late MockNetworkManagerDeviceWireless mockWireless;
  late MockNetworkManagerSettings mockSettings;

  setUp(() {
    mockClient = MockNetworkManagerClient();
    mockWifiDevice = MockNetworkManagerDevice();
    mockWireless = MockNetworkManagerDeviceWireless();
    mockSettings = MockNetworkManagerSettings();

    // Default setups
    when(() => mockClient.devices).thenReturn([mockWifiDevice]);
    when(() => mockClient.settings).thenReturn(mockSettings);
    when(
      () => mockWifiDevice.deviceType,
    ).thenReturn(NetworkManagerDeviceType.wifi);
    when(() => mockWifiDevice.wireless).thenReturn(mockWireless);
    when(
      () => mockWifiDevice.state,
    ).thenReturn(NetworkManagerDeviceState.activated);
    when(() => mockWifiDevice.hwAddress).thenReturn('00:11:22:33:44:55');
    when(() => mockWifiDevice.activeConnection).thenReturn(null);
    when(() => mockWireless.accessPoints).thenReturn([]);
    when(() => mockWireless.activeAccessPoint).thenReturn(null);
    when(() => mockSettings.connections).thenReturn([]);

    repository = WirelessRepositoryImpl(client: mockClient);
  });

  group('WirelessRepositoryImpl initialization & basic checks', () {
    test('isWirelessEnabled returns client value', () async {
      when(() => mockClient.wirelessEnabled).thenReturn(true);
      expect(await repository.isWirelessEnabled(), true);

      when(() => mockClient.wirelessEnabled).thenReturn(false);
      expect(await repository.isWirelessEnabled(), false);
    });

    test(
      'isWirelessEnabled returns false when not connected/initialized',
      () async {
        final uninitializedRepo = WirelessRepositoryImpl();
        expect(await uninitializedRepo.isWirelessEnabled(), false);
      },
    );

    test('setWifiEnabled calls setWirelessEnabled on client', () async {
      when(() => mockClient.setWirelessEnabled(any())).thenAnswer((_) async {});
      await repository.setWifiEnabled(true);
      verify(() => mockClient.setWirelessEnabled(true)).called(1);

      await repository.setWifiEnabled(false);
      verify(() => mockClient.setWirelessEnabled(false)).called(1);
    });

    test('getWifiDevice returns wifi device', () async {
      final device = await repository.getWifiDevice();
      expect(device, mockWifiDevice);
    });

    test('getWifiDevice returns null when no wifi device is present', () async {
      final mockEthernetDevice = MockNetworkManagerDevice();
      when(
        () => mockEthernetDevice.deviceType,
      ).thenReturn(NetworkManagerDeviceType.ethernet);
      when(() => mockClient.devices).thenReturn([mockEthernetDevice]);

      final device = await repository.getWifiDevice();
      expect(device, null);
    });

    test('getWifiDeviceState returns state', () async {
      when(
        () => mockWifiDevice.state,
      ).thenReturn(NetworkManagerDeviceState.disconnected);
      final state = await repository.getWifiDeviceState();
      expect(state, NetworkManagerDeviceState.disconnected);
    });
  });

  group('getSavedNetworks', () {
    test('returns mapped WifiNetwork objects', () async {
      final mockConnection = MockNetworkManagerSettingsConnection();
      when(() => mockConnection.unsaved).thenReturn(false);

      final dbusSsid = DBusArray(
        DBusSignature.byte,
        utf8.encode('Saved_WiFi').map((b) => DBusByte(b)).toList(),
      );

      final settingsMap = {
        'connection': {'id': const DBusString('Saved_WiFi')},
        '802-11-wireless': {'ssid': dbusSsid},
      };

      when(
        () => mockConnection.getSettings(),
      ).thenAnswer((_) async => settingsMap);
      when(() => mockSettings.connections).thenReturn([mockConnection]);

      final networks = await repository.getSavedNetworks();
      expect(networks.length, 1);
      expect(networks.first.name, 'Saved_WiFi');
      expect(networks.first.isConnected, false);
    });

    test('populates rawSignalStrength and speedMbps when connected', () async {
      final mockConnection = MockNetworkManagerSettingsConnection();
      when(() => mockConnection.unsaved).thenReturn(false);

      final dbusSsid = DBusArray(
        DBusSignature.byte,
        utf8.encode('Saved_WiFi').map((b) => DBusByte(b)).toList(),
      );

      final settingsMap = {
        'connection': {'id': const DBusString('Saved_WiFi')},
        '802-11-wireless': {'ssid': dbusSsid},
      };

      when(
        () => mockConnection.getSettings(),
      ).thenAnswer((_) async => settingsMap);
      when(() => mockSettings.connections).thenReturn([mockConnection]);

      final mockActiveConnection = MockNetworkManagerActiveConnection();
      when(
        () => mockWifiDevice.activeConnection,
      ).thenReturn(mockActiveConnection);
      when(
        () => mockWifiDevice.state,
      ).thenReturn(NetworkManagerDeviceState.activated);

      when(() => mockActiveConnection.devices).thenReturn([mockWifiDevice]);
      when(() => mockWireless.bitrate).thenReturn(130000);

      final mockAp = MockNetworkManagerAccessPoint();
      when(() => mockAp.ssid).thenReturn(utf8.encode('Saved_WiFi'));
      when(() => mockAp.strength).thenReturn(78);
      when(() => mockAp.frequency).thenReturn(2412);
      when(() => mockAp.wpaFlags).thenReturn([]);
      when(() => mockAp.rsnFlags).thenReturn([]);
      when(() => mockWireless.activeAccessPoint).thenReturn(mockAp);
      when(() => mockWireless.accessPoints).thenReturn([mockAp]);

      final networks = await repository.getSavedNetworks();
      expect(networks.length, 1);
      expect(networks.first.name, 'Saved_WiFi');
      expect(networks.first.isConnected, true);
      expect(networks.first.rawSignalStrength, 78);
      expect(networks.first.speedMbps, 130);
      expect(networks.first.frequency, 2412);
    });
  });

  group('getAvailableNetworks', () {
    test('returns scan results filtering out saved ones', () async {
      final mockAp = MockNetworkManagerAccessPoint();
      when(() => mockAp.ssid).thenReturn(utf8.encode('Available_WiFi'));
      when(() => mockAp.strength).thenReturn(80);
      when(
        () => mockAp.wpaFlags,
      ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);
      when(
        () => mockAp.rsnFlags,
      ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);

      when(() => mockWireless.accessPoints).thenReturn([mockAp]);
      when(() => mockWireless.requestScan()).thenAnswer((_) async {});

      final networks = await repository.getAvailableNetworks(
        requestScan: true,
        savedNetworks: [const WifiNetwork(name: 'Saved_WiFi')],
      );

      expect(networks.length, 1);
      expect(networks.first.name, 'Available_WiFi');
    });
  });

  group('forgetNetwork', () {
    test('calls delete on connection with matching SSID', () async {
      final mockConnection = MockNetworkManagerSettingsConnection();
      when(() => mockConnection.unsaved).thenReturn(false);
      when(() => mockConnection.delete()).thenAnswer((_) async {});

      final settingsMap = {
        'connection': {'id': const DBusString('Saved_WiFi')},
      };
      when(
        () => mockConnection.getSettings(),
      ).thenAnswer((_) async => settingsMap);
      when(() => mockSettings.connections).thenReturn([mockConnection]);

      await repository.forgetNetwork(const WifiNetwork(name: 'Saved_WiFi'));

      verify(() => mockConnection.delete()).called(1);
    });
  });

  group('getMyNetworks', () {
    test('returns sorted visible saved networks', () async {
      final mockConnection1 = MockNetworkManagerSettingsConnection();
      when(() => mockConnection1.unsaved).thenReturn(false);
      when(() => mockConnection1.getSettings()).thenAnswer(
        (_) async => {
          'connection': {'id': const DBusString('My_WiFi_1')},
          '802-11-wireless': {
            'ssid': DBusArray(
              DBusSignature.byte,
              utf8.encode('My_WiFi_1').map((b) => DBusByte(b)).toList(),
            ),
          },
        },
      );

      final mockConnection2 = MockNetworkManagerSettingsConnection();
      when(() => mockConnection2.unsaved).thenReturn(false);
      when(() => mockConnection2.getSettings()).thenAnswer(
        (_) async => {
          'connection': {'id': const DBusString('My_WiFi_2')},
          '802-11-wireless': {
            'ssid': DBusArray(
              DBusSignature.byte,
              utf8.encode('My_WiFi_2').map((b) => DBusByte(b)).toList(),
            ),
          },
        },
      );

      when(
        () => mockSettings.connections,
      ).thenReturn([mockConnection1, mockConnection2]);

      final mockAp1 = MockNetworkManagerAccessPoint();
      when(() => mockAp1.ssid).thenReturn(utf8.encode('My_WiFi_1'));
      when(() => mockAp1.strength).thenReturn(50);
      when(
        () => mockAp1.wpaFlags,
      ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);
      when(
        () => mockAp1.rsnFlags,
      ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);

      when(() => mockWireless.accessPoints).thenReturn([mockAp1]);

      final myNetworks = await repository.getMyNetworks();

      // Only My_WiFi_1 is in range/visible, so getMyNetworks only returns My_WiFi_1
      expect(myNetworks.length, 1);
      expect(myNetworks.first.name, 'My_WiFi_1');
    });
  });

  group('Event Streams', () {
    test(
      'getWifiEventsStream returns client propertiesChanged stream',
      () async {
        final expectedStream = const Stream<List<String>>.empty();
        when(
          () => mockClient.propertiesChanged,
        ).thenAnswer((_) => expectedStream);

        final stream = await repository.getWifiEventsStream();
        expect(stream, expectedStream);
      },
    );

    test(
      'getWirelessDeviceEventsStream returns wireless propertiesChanged stream',
      () async {
        final expectedStream = const Stream<List<String>>.empty();
        when(
          () => mockWireless.propertiesChanged,
        ).thenAnswer((_) => expectedStream);

        final stream = await repository.getWirelessDeviceEventsStream();
        expect(stream, expectedStream);
      },
    );

    test(
      'getDeviceEventsStream returns device propertiesChanged stream',
      () async {
        final expectedStream = const Stream<List<String>>.empty();
        when(
          () => mockWifiDevice.propertiesChanged,
        ).thenAnswer((_) => expectedStream);

        final stream = await repository.getDeviceEventsStream();
        expect(stream, expectedStream);
      },
    );
  });

  test('updateNetwork updates autoJoin and lowDataMode', () async {
    final connection = MockNetworkManagerSettingsConnection();

    when(() => connection.unsaved).thenReturn(false);

    when(() => connection.getSettings()).thenAnswer(
      (_) async => {
        'connection': {
          'id': const DBusString('Home'),
          'autoconnect': const DBusBoolean(false),
        },
      },
    );

    when(() => connection.update(any())).thenAnswer((_) async {});

    when(() => mockSettings.connections).thenReturn([connection]);

    await repository.updateNetwork(
      const WifiNetwork(name: 'Home', autoJoin: true, lowDataMode: true),
    );

    verify(() => connection.update(any())).called(1);
  });

  test('addNetwork creates hidden network', () async {
    when(() => mockSettings.connections).thenReturn([]);

    when(
      () => mockClient.addAndActivateConnection(
        device: mockWifiDevice,
        connection: any(named: 'connection'),
      ),
    ).thenAnswer((_) async => MockNetworkManagerActiveConnection());

    await repository.addNetwork(
      'HiddenWifi',
      WirelessSecurity.wpaWpa2Personal,
      null,
    );

    verify(
      () => mockClient.addAndActivateConnection(
        device: mockWifiDevice,
        connection: any(named: 'connection'),
      ),
    ).called(1);
  });

  test('connectToNetwork activates existing connection', () async {
    final connection = MockNetworkManagerSettingsConnection();

    final ap = MockNetworkManagerAccessPoint();

    when(() => ap.ssid).thenReturn(utf8.encode('Office'));

    when(
      () => ap.wpaFlags,
    ).thenReturn([NetworkManagerWifiAccessPointSecurityFlag.keyManagementPsk]);

    when(
      () => ap.rsnFlags,
    ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);

    when(() => mockWireless.accessPoints).thenReturn([ap]);

    when(() => connection.unsaved).thenReturn(false);

    when(() => connection.getSettings()).thenAnswer(
      (_) async => {
        '802-11-wireless': {
          'ssid': DBusArray(
            DBusSignature.byte,
            utf8.encode('Office').map(DBusByte.new).toList(),
          ),
        },
        '802-11-wireless-security': {'key-mgmt': const DBusString('wpa-psk')},
      },
    );

    when(() => mockSettings.connections).thenReturn([connection]);

    when(
      () => mockClient.activateConnection(
        connection: connection,
        device: mockWifiDevice,
        accessPoint: ap,
      ),
    ).thenAnswer((_) async => MockNetworkManagerActiveConnection());

    await repository.connectToNetwork('Office', null);

    verify(
      () => mockClient.activateConnection(
        connection: connection,
        device: mockWifiDevice,
        accessPoint: ap,
      ),
    ).called(1);
  });

  test('connectToNetwork creates new profile when none exists', () async {
    final ap = MockNetworkManagerAccessPoint();

    when(() => ap.ssid).thenReturn(utf8.encode('Cafe'));

    when(
      () => ap.wpaFlags,
    ).thenReturn([NetworkManagerWifiAccessPointSecurityFlag.keyManagementPsk]);

    when(
      () => ap.rsnFlags,
    ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);

    when(() => mockWireless.accessPoints).thenReturn([ap]);

    when(() => mockSettings.connections).thenReturn([]);

    when(
      () => mockClient.addAndActivateConnection(
        device: mockWifiDevice,
        accessPoint: ap,
        connection: any(named: 'connection'),
      ),
    ).thenAnswer((_) async => MockNetworkManagerActiveConnection());

    await repository.connectToNetwork('Cafe', null);

    verify(
      () => mockClient.addAndActivateConnection(
        device: mockWifiDevice,
        accessPoint: ap,
        connection: any(named: 'connection'),
      ),
    ).called(1);
  });

  test('updateIPSettings updates manual configuration', () async {
    final connection = MockNetworkManagerSettingsConnection();
    final active = MockNetworkManagerActiveConnection();

    when(() => mockWifiDevice.activeConnection).thenReturn(active);

    when(() => connection.unsaved).thenReturn(false);

    when(() => connection.getSettings()).thenAnswer(
      (_) async => {
        'connection': {'id': const DBusString('Home')},
        'ipv4': {},
      },
    );

    when(() => connection.update(any())).thenAnswer((_) async {});

    when(() => mockSettings.connections).thenReturn([connection]);

    when(
      () => mockClient.deactivateConnection(active),
    ).thenAnswer((_) async {});

    when(
      () => mockClient.activateConnection(
        connection: connection,
        device: mockWifiDevice,
      ),
    ).thenAnswer((_) async => active);

    await repository.updateIPSettings(
      const WifiNetwork(name: 'Home'),
      IPv4ConfigType.manual,
      '192.168.1.20',
      '255.255.255.0',
      '192.168.1.1',
    );

    verify(() => connection.update(any())).called(1);
  });

  test('updateDNSSettings updates DNS', () async {
    final connection = MockNetworkManagerSettingsConnection();
    final active = MockNetworkManagerActiveConnection();

    when(() => mockWifiDevice.activeConnection).thenReturn(active);

    when(() => connection.unsaved).thenReturn(false);

    when(() => connection.getSettings()).thenAnswer(
      (_) async => {
        'connection': {'id': const DBusString('Home')},
        'ipv4': {},
      },
    );

    when(() => connection.update(any())).thenAnswer((_) async {});

    when(() => mockSettings.connections).thenReturn([connection]);

    when(
      () => mockClient.deactivateConnection(active),
    ).thenAnswer((_) async {});

    when(
      () => mockClient.activateConnection(
        connection: connection,
        device: mockWifiDevice,
        accessPoint: any(named: 'accessPoint'),
      ),
    ).thenAnswer((_) async => active);

    await repository.updateDNSSettings(
      const WifiNetwork(name: 'Home'),
      DNSConfigType.manual,
      ['8.8.8.8'],
      ['local'],
    );

    verify(() => connection.update(any())).called(1);
  });

  test('getSavedWifiPsk returns psk', () async {
    final connection = MockNetworkManagerSettingsConnection();

    when(() => mockWifiDevice.availableConnections).thenReturn([connection]);

    final ap = MockNetworkManagerAccessPoint();

    when(() => ap.ssid).thenReturn(utf8.encode('Home'));

    when(() => connection.getSettings()).thenAnswer(
      (_) async => {
        'connection': {'id': const DBusString('Home')},
      },
    );

    when(() => connection.getSecrets(any())).thenAnswer(
      (_) async => {
        '802-11-wireless-security': {'psk': const DBusString('password123')},
      },
    );

    final result = await repository.getSavedWifiPsk(mockWifiDevice, ap);

    expect(result, 'password123');
  });

  test('getSavedWirelessNetworks returns saved networks', () async {
    final connection = MockNetworkManagerSettingsConnection();

    when(() => connection.unsaved).thenReturn(false);

    when(() => connection.getSettings()).thenAnswer(
      (_) async => {
        'connection': {
          'id': const DBusString('HomeWifi'),
          'autoconnect': const DBusBoolean(true),
        },
        '802-11-wireless': {
          'seen-bssids': DBusArray(DBusSignature.string, [
            const DBusString('AA:BB:CC:DD:EE:FF'),
          ]),
        },
        '802-11-wireless-security': {'key-mgmt': const DBusString('wpa-psk')},
        'ipv4': {'method': const DBusString('auto')},
      },
    );

    when(() => mockSettings.connections).thenReturn([connection]);

    final result = await repository.getSavedWirelessNetworks();

    expect(result.length, 1);
    expect(result.first.ssid, 'HomeWifi');
    expect(result.first.security, 'wpa-psk');
    expect(result.first.ipv4Method, 'auto');
    expect(result.first.autoConnect, true);
  });

  test('getSavedWirelessNetworks ignores duplicate BSSID', () async {
    final c1 = MockNetworkManagerSettingsConnection();
    final c2 = MockNetworkManagerSettingsConnection();

    when(() => c1.unsaved).thenReturn(false);
    when(() => c2.unsaved).thenReturn(false);

    Future<Map<String, Map<String, DBusValue>>> settings(String id) async => {
      'connection': {
        'id': DBusString(id),
        'autoconnect': const DBusBoolean(true),
      },
      '802-11-wireless': {
        'seen-bssids': DBusArray(DBusSignature.string, [
          const DBusString('AA:BB'),
        ]),
      },
      'ipv4': {'method': const DBusString('auto')},
    };

    when(() => c1.getSettings()).thenAnswer((_) => settings('Wifi1'));
    when(() => c2.getSettings()).thenAnswer((_) => settings('Wifi2'));

    when(() => mockSettings.connections).thenReturn([c1, c2]);

    final result = await repository.getSavedWirelessNetworks();

    expect(result.length, 1);
  });

  test('availableAccessPoints returns active and available APs', () async {
    final savedConnection = MockNetworkManagerSettingsConnection();

    when(() => savedConnection.unsaved).thenReturn(false);

    when(() => savedConnection.getSettings()).thenAnswer(
      (_) async => {
        'connection': {
          'id': const DBusString('HomeWifi'),
          'autoconnect': const DBusBoolean(true),
        },
        '802-11-wireless': {
          'seen-bssids': DBusArray(DBusSignature.string, [
            const DBusString('AA'),
          ]),
        },
        'ipv4': {'method': const DBusString('auto')},
      },
    );

    when(() => mockSettings.connections).thenReturn([savedConnection]);

    final activeAp = MockNetworkManagerAccessPoint();
    final otherAp = MockNetworkManagerAccessPoint();

    when(() => activeAp.ssid).thenReturn(utf8.encode('HomeWifi'));
    when(() => activeAp.wpaFlags).thenReturn([]);
    when(() => activeAp.rsnFlags).thenReturn([]);

    when(() => otherAp.ssid).thenReturn(utf8.encode('OfficeWifi'));
    when(() => otherAp.wpaFlags).thenReturn([]);
    when(() => otherAp.rsnFlags).thenReturn([]);

    when(() => mockWireless.requestScan()).thenAnswer((_) async {});

    when(() => mockWireless.activeAccessPoint).thenReturn(activeAp);

    when(() => mockWireless.accessPoints).thenReturn([activeAp, otherAp]);

    when(
      () => mockWifiDevice.state,
    ).thenReturn(NetworkManagerDeviceState.activated);

    when(() => mockWifiDevice.ip4Config).thenReturn(null);
    when(() => mockWifiDevice.ip6Config).thenReturn(null);

    final result = await repository.availableAccessPoints();

    expect(result.active, isNotNull);
    expect(result.active!.isActive, true);

    expect(result.available.length, 1);
    expect(
      utf8.decode(result.available.first.nmAccessPoint.ssid),
      'OfficeWifi',
    );
  });

  test('availableAccessPoints returns empty when wifi unavailable', () async {
    when(
      () => mockWifiDevice.state,
    ).thenReturn(NetworkManagerDeviceState.unavailable);

    final result = await repository.availableAccessPoints();

    expect(result.active, isNull);
    expect(result.available, isEmpty);
  });
}
