import 'dart:convert';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/models/wireless_exceptions.dart';
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
      expect(repository.isWirelessEnabled(), true);

      when(() => mockClient.wirelessEnabled).thenReturn(false);
      expect(repository.isWirelessEnabled(), false);
    });

    test(
      'isWirelessEnabled returns false when not connected/initialized',
      () async {
        final uninitializedRepo = WirelessRepositoryImpl();
        expect(uninitializedRepo.isWirelessEnabled(), false);
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
      final device = repository.getWifiDevice();
      expect(device, mockWifiDevice);
    });

    test('getWifiDevice returns null when no wifi device is present', () async {
      final mockEthernetDevice = MockNetworkManagerDevice();
      when(
        () => mockEthernetDevice.deviceType,
      ).thenReturn(NetworkManagerDeviceType.ethernet);
      when(() => mockClient.devices).thenReturn([mockEthernetDevice]);

      final device = repository.getWifiDevice();
      expect(device, null);
    });

    test('getWifiDeviceState returns state', () async {
      when(
        () => mockWifiDevice.state,
      ).thenReturn(NetworkManagerDeviceState.disconnected);
      final state = repository.getWifiDeviceState();
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

  group('saved profile index', () {
    MockNetworkManagerSettingsConnection savedConnection(String ssid) {
      final connection = MockNetworkManagerSettingsConnection();
      when(() => connection.unsaved).thenReturn(false);
      when(() => connection.getSettings()).thenAnswer(
        (_) async => {
          'connection': {'id': DBusString(ssid)},
          '802-11-wireless': {
            'ssid': DBusArray(
              DBusSignature.byte,
              utf8.encode(ssid).map((b) => DBusByte(b)).toList(),
            ),
          },
        },
      );
      return connection;
    }

    test(
      'secured access points that are not saved skip the password lookup',
      () async {
        final saved = savedConnection('Saved_WiFi');
        final ap = MockNetworkManagerAccessPoint();
        when(() => ap.ssid).thenReturn(utf8.encode('Cafe_WiFi'));
        when(() => ap.strength).thenReturn(70);
        when(() => ap.frequency).thenReturn(5180);
        when(
          () => ap.wpaFlags,
        ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);
        when(() => ap.rsnFlags).thenReturn([
          NetworkManagerWifiAccessPointSecurityFlag.keyManagementPsk,
        ]);
        when(() => mockSettings.connections).thenReturn([saved]);
        when(() => mockWireless.accessPoints).thenReturn([ap]);

        // Reading all saved networks builds the SSID → profile index.
        final savedNetworks = await repository.getSavedNetworks();
        clearInteractions(saved);

        final available = await repository.getAvailableNetworks(
          requestScan: false,
          savedNetworks: savedNetworks,
        );

        expect(available.single.name, 'Cafe_WiFi');
        expect(available.single.isSecured, isTrue);
        expect(available.single.password, isEmpty);
        // No GetSettings/GetSecrets round trips for a network with no profile.
        verifyNever(() => saved.getSettings());
        verifyNever(() => saved.getSecrets(any()));
      },
    );
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

    await repository.addNetwork('HiddenWifi', WirelessSecurity.wpaWpa2Personal);

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
        accessPoint: any(named: 'accessPoint'),
      ),
    ).thenAnswer((_) async => MockNetworkManagerActiveConnection());

    await repository.connectToNetwork('Office', null);

    verify(
      () => mockClient.activateConnection(
        connection: connection,
        device: mockWifiDevice,
        accessPoint: any(named: 'accessPoint'),
      ),
    ).called(1);
  });

  group('connectToNetwork', () {
    MockNetworkManagerAccessPoint ap(
      String ssid, {
      List<NetworkManagerWifiAccessPointSecurityFlag> rsn = const [],
    }) {
      final mock = MockNetworkManagerAccessPoint();
      when(() => mock.ssid).thenReturn(utf8.encode(ssid));
      when(
        () => mock.wpaFlags,
      ).thenReturn(<NetworkManagerWifiAccessPointSecurityFlag>[]);
      when(() => mock.rsnFlags).thenReturn(rsn);
      return mock;
    }

    MockNetworkManagerSettingsConnection profile(
      String ssid, {
      Map<String, DBusValue>? security,
    }) {
      final connection = MockNetworkManagerSettingsConnection();
      when(() => connection.unsaved).thenReturn(false);
      when(() => connection.getSettings()).thenAnswer(
        (_) async => {
          'connection': {'id': DBusString(ssid)},
          '802-11-wireless': {
            'ssid': DBusArray(
              DBusSignature.byte,
              utf8.encode(ssid).map(DBusByte.new).toList(),
            ),
            if (security != null)
              'security': const DBusString('802-11-wireless-security'),
          },
          'ipv4': {'method': const DBusString('manual')},
          '802-11-wireless-security': ?security,
        },
      );
      when(() => connection.update(any())).thenAnswer((_) async {});
      when(() => connection.delete()).thenAnswer((_) async {});
      return connection;
    }

    // Concrete device/connection values avoid needing mocktail fallbacks.
    void stubActivate(MockNetworkManagerSettingsConnection connection) {
      when(
        () => mockClient.activateConnection(
          connection: connection,
          device: mockWifiDevice,
          accessPoint: any(named: 'accessPoint'),
        ),
      ).thenAnswer((_) async => MockNetworkManagerActiveConnection());
    }

    void stubAddAndActivate() {
      when(
        () => mockClient.addAndActivateConnection(
          device: mockWifiDevice,
          accessPoint: any(named: 'accessPoint'),
          connection: any(named: 'connection'),
        ),
      ).thenAnswer((_) async => MockNetworkManagerActiveConnection());
    }

    const pskFlag = NetworkManagerWifiAccessPointSecurityFlag.keyManagementPsk;
    const wpaPsk = {'key-mgmt': DBusString('wpa-psk')};

    test(
      'saved open network that now uses WPA requires a password and is '
      'left untouched',
      () async {
        final cafeAp = ap('Cafe', rsn: [pskFlag]);
        final connection = profile('Cafe');
        when(() => mockWireless.accessPoints).thenReturn([cafeAp]);
        when(() => mockSettings.connections).thenReturn([connection]);
        stubActivate(connection);

        await expectLater(
          repository.connectToNetwork('Cafe', null),
          throwsA(
            isA<WifiPasswordRequiredException>()
                .having((e) => e.networkName, 'networkName', 'Cafe')
                .having(
                  (e) => e.security,
                  'security',
                  WirelessSecurity.wpaWpa2Personal,
                ),
          ),
        );

        verifyNever(() => connection.delete());
        verifyNever(() => connection.update(any()));
        verifyNever(
          () => mockClient.activateConnection(
            connection: connection,
            device: mockWifiDevice,
            accessPoint: any(named: 'accessPoint'),
          ),
        );
      },
    );

    test(
      'saved open network that now uses WPA is updated in place with the '
      'new password',
      () async {
        final cafeAp = ap('Cafe', rsn: [pskFlag]);
        final connection = profile('Cafe');
        when(() => mockWireless.accessPoints).thenReturn([cafeAp]);
        when(() => mockSettings.connections).thenReturn([connection]);
        stubActivate(connection);

        await repository.connectToNetwork('Cafe', 'newpass123');

        final updated =
            verify(() => connection.update(captureAny())).captured.single
                as Map<String, Map<String, DBusValue>>;
        final security = updated['802-11-wireless-security']!;
        expect(security['key-mgmt'], const DBusString('wpa-psk'));
        expect(security['psk'], const DBusString('newpass123'));
        // IP configuration is preserved.
        expect(updated['ipv4']!['method'], const DBusString('manual'));

        verifyNever(() => connection.delete());
        verify(
          () => mockClient.activateConnection(
            connection: connection,
            device: mockWifiDevice,
            accessPoint: any(named: 'accessPoint'),
          ),
        ).called(1);
      },
    );

    test('saved WPA network that is now open drops its security', () async {
      final openAp = ap('Cafe');
      final connection = profile('Cafe', security: wpaPsk);
      when(() => mockWireless.accessPoints).thenReturn([openAp]);
      when(() => mockSettings.connections).thenReturn([connection]);
      stubActivate(connection);

      await repository.connectToNetwork('Cafe', null);

      final updated =
          verify(() => connection.update(captureAny())).captured.single
              as Map<String, Map<String, DBusValue>>;
      expect(updated.containsKey('802-11-wireless-security'), isFalse);
      expect(updated['802-11-wireless']!.containsKey('security'), isFalse);
      verify(
        () => mockClient.activateConnection(
          connection: connection,
          device: mockWifiDevice,
          accessPoint: any(named: 'accessPoint'),
        ),
      ).called(1);
    });

    test('saved WPA network without a stored password requires one', () async {
      final homeAp = ap('Home', rsn: [pskFlag]);
      final connection = profile('Home', security: wpaPsk);
      when(
        () => connection.getSecrets(any()),
      ).thenAnswer((_) async => <String, Map<String, DBusValue>>{});
      when(() => mockWireless.accessPoints).thenReturn([homeAp]);
      when(() => mockSettings.connections).thenReturn([connection]);
      stubActivate(connection);

      await expectLater(
        repository.connectToNetwork('Home', null),
        throwsA(isA<WifiPasswordRequiredException>()),
      );
      verifyNever(() => connection.update(any()));
    });

    test('saved WPA network with a stored password activates directly', () async {
      final homeAp = ap('Home', rsn: [pskFlag]);
      final connection = profile('Home', security: wpaPsk);
      when(() => connection.getSecrets(any())).thenAnswer(
        (_) async => {
          '802-11-wireless-security': {'psk': const DBusString('secret123')},
        },
      );
      when(() => mockWireless.accessPoints).thenReturn([homeAp]);
      when(() => mockSettings.connections).thenReturn([connection]);
      stubActivate(connection);

      await repository.connectToNetwork('Home', null);

      verifyNever(() => connection.update(any()));
      verify(
        () => mockClient.activateConnection(
          connection: connection,
          device: mockWifiDevice,
          accessPoint: any(named: 'accessPoint'),
        ),
      ).called(1);
    });

    test(
      'agent-owned secret available in this session activates directly',
      () async {
        final homeAp = ap('Home', rsn: [pskFlag]);
        final connection = profile(
          'Home',
          security: {
            'key-mgmt': const DBusString('wpa-psk'),
            'psk-flags': const DBusUint32(1),
          },
        );
        when(() => connection.getSecrets(any())).thenAnswer(
          (_) async => {
            '802-11-wireless-security': {'psk': const DBusString('secret123')},
          },
        );
        when(() => mockWireless.accessPoints).thenReturn([homeAp]);
        when(() => mockSettings.connections).thenReturn([connection]);
        stubActivate(connection);

        await repository.connectToNetwork('Home', null);

        verify(
          () => mockClient.activateConnection(
            connection: connection,
            device: mockWifiDevice,
            accessPoint: any(named: 'accessPoint'),
          ),
        ).called(1);
      },
    );

    test(
      'agent-owned secret that is not available asks the app for a password '
      'instead of activating (which would open the GNOME dialog)',
      () async {
        final homeAp = ap('Home', rsn: [pskFlag]);
        final connection = profile(
          'Home',
          security: {
            'key-mgmt': const DBusString('wpa-psk'),
            'psk-flags': const DBusUint32(1),
          },
        );
        when(
          () => connection.getSecrets(any()),
        ).thenAnswer((_) async => <String, Map<String, DBusValue>>{});
        when(() => mockWireless.accessPoints).thenReturn([homeAp]);
        when(() => mockSettings.connections).thenReturn([connection]);
        stubActivate(connection);

        await expectLater(
          repository.connectToNetwork('Home', null),
          throwsA(isA<WifiPasswordRequiredException>()),
        );
        verifyNever(
          () => mockClient.activateConnection(
            connection: connection,
            device: mockWifiDevice,
            accessPoint: any(named: 'accessPoint'),
          ),
        );
      },
    );

    test('entered password is stored by NetworkManager, not an agent', () async {
      final homeAp = ap('Home', rsn: [pskFlag]);
      final connection = profile(
        'Home',
        security: {
          'key-mgmt': const DBusString('wpa-psk'),
          'psk-flags': const DBusUint32(1),
        },
      );
      when(() => mockWireless.accessPoints).thenReturn([homeAp]);
      when(() => mockSettings.connections).thenReturn([connection]);
      stubActivate(connection);

      await repository.connectToNetwork('Home', 'newpass123');

      final updated =
          verify(() => connection.update(captureAny())).captured.single
              as Map<String, Map<String, DBusValue>>;
      expect(updated['802-11-wireless-security'], {
        'key-mgmt': const DBusString('wpa-psk'),
        'psk': const DBusString('newpass123'),
        'psk-flags': const DBusUint32(0),
      });
    });

    test('new secured network without a password requires one', () async {
      // Build the mock first: calling when() inside thenReturn() is not
      // allowed by mocktail.
      final cafeAp = ap('Cafe', rsn: [pskFlag]);
      when(() => mockWireless.accessPoints).thenReturn([cafeAp]);
      stubAddAndActivate();

      await expectLater(
        repository.connectToNetwork('Cafe', null),
        throwsA(isA<WifiPasswordRequiredException>()),
      );
      verifyNever(
        () => mockClient.addAndActivateConnection(
          device: mockWifiDevice,
          accessPoint: any(named: 'accessPoint'),
          connection: any(named: 'connection'),
        ),
      );
    });

    test('new WPA network is created with the password', () async {
      final cafeAp = ap('Cafe', rsn: [pskFlag]);
      when(() => mockWireless.accessPoints).thenReturn([cafeAp]);
      stubAddAndActivate();

      await repository.connectToNetwork('Cafe', 'password123');

      final connection =
          verify(
                () => mockClient.addAndActivateConnection(
                  device: mockWifiDevice,
                  accessPoint: cafeAp,
                  connection: captureAny(named: 'connection'),
                ),
              ).captured.single
              as Map<String, Map<String, DBusValue>>;
      expect(connection['802-11-wireless-security'], {
        'key-mgmt': const DBusString('wpa-psk'),
        'psk': const DBusString('password123'),
        'psk-flags': const DBusUint32(0),
      });
    });

    test('new WEP network stores the key in wep-key0', () async {
      // Secured AP without PSK/SAE key management maps to WEP.
      final wepAp = ap(
        'OldRouter',
        rsn: [NetworkManagerWifiAccessPointSecurityFlag.pairWep40],
      );
      when(() => mockWireless.accessPoints).thenReturn([wepAp]);
      stubAddAndActivate();

      await repository.connectToNetwork('OldRouter', 'abcde');

      final connection =
          verify(
                () => mockClient.addAndActivateConnection(
                  device: mockWifiDevice,
                  accessPoint: wepAp,
                  connection: captureAny(named: 'connection'),
                ),
              ).captured.single
              as Map<String, Map<String, DBusValue>>;
      final security = connection['802-11-wireless-security']!;
      expect(security['key-mgmt'], const DBusString('none'));
      expect(security['wep-key0'], const DBusString('abcde'));
      expect(security.containsKey('psk'), isFalse);
    });
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

  test('updateIPv6Settings updates manual configuration', () async {
    final connection = MockNetworkManagerSettingsConnection();
    final active = MockNetworkManagerActiveConnection();

    when(() => mockWifiDevice.activeConnection).thenReturn(active);

    when(() => connection.unsaved).thenReturn(false);

    when(() => connection.getSettings()).thenAnswer(
      (_) async => {
        'connection': {'id': const DBusString('Home')},
        'ipv6': {},
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

    await repository.updateIPv6Settings(
      const WifiNetwork(name: 'Home'),
      IPv6ConfigType.manual,
      '2001:db8::1',
      64,
      '2001:db8::fe',
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

  group('Captive Portal', () {
    test(
      'isCaptivePortal returns false if connectivity state is not portal',
      () async {
        when(
          () => mockClient.connectivity,
        ).thenReturn(NetworkManagerConnectivityState.limited);
        final result = await repository.isCaptivePortal();
        expect(result, false);
      },
    );

    test(
      'isCaptivePortal returns true if connectivity state is portal',
      () async {
        when(
          () => mockClient.connectivity,
        ).thenReturn(NetworkManagerConnectivityState.portal);
        final result = await repository.isCaptivePortal();
        expect(result, true);
      },
    );

    test(
      'isCaptivePortal returns false when not connected/initialized',
      () async {
        final uninitializedRepo = WirelessRepositoryImpl();
        expect(await uninitializedRepo.isCaptivePortal(), false);
      },
    );

    test('openCaptivePortal opens client check uri if present', () async {
      when(() => mockClient.connectivityCheckUri).thenReturn('http://check.me');
      await repository.openCaptivePortal();
    });
  });

  group('Lifecycle & Close', () {
    test('close calls client close when connected', () async {
      when(() => mockClient.close()).thenAnswer((_) async {});
      await repository.close();
      verify(() => mockClient.close()).called(1);
    });

    test('close does nothing when uninitialized', () async {
      final uninitializedRepo = WirelessRepositoryImpl();
      await expectLater(uninitializedRepo.close(), completes);
    });
  });
}
