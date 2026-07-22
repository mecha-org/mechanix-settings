import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm/nm.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

void main() {
  late WirelessBloc wirelessBloc;
  late MockWirelessRepository mockWirelessRepository;

  final testWifiNetwork = const WifiNetwork(
    name: 'Test_WiFi',
    isConnected: false,
    security: WirelessSecurity.wpaWpa2Personal,
  );

  final testConnectedWifiNetwork = const WifiNetwork(
    name: 'Test_WiFi_Connected',
    isConnected: true,
    security: WirelessSecurity.wpaWpa2Personal,
  );

  setUpAll(() {
    registerFallbackValue(testWifiNetwork);
    registerFallbackValue(WirelessSecurity.none);
    registerFallbackValue(IPv4ConfigType.manual);
    registerFallbackValue(DNSConfigType.manual);
    registerFallbackValue(const EnterpriseConfig());
  });

  setUp(() {
    mockWirelessRepository = MockWirelessRepository();
    
    // Default mocks to prevent crashes on initialization
    when(() => mockWirelessRepository.init()).thenAnswer((_) async {});
    when(() => mockWirelessRepository.getWifiEventsStream())
        .thenAnswer((_) async => const Stream<List<String>>.empty());
    when(() => mockWirelessRepository.getDeviceEventsStream())
        .thenAnswer((_) async => const Stream<List<String>>.empty());
    when(() => mockWirelessRepository.getWirelessDeviceEventsStream())
        .thenAnswer((_) async => const Stream<List<String>>.empty());

    wirelessBloc = WirelessBloc(wirelessRepository: mockWirelessRepository);
  });

  tearDown(() {
    wirelessBloc.close();
  });

  group('WirelessBloc Initial State', () {
    test('initial state is correct', () {
      expect(wirelessBloc.state, const WirelessState());
    });
  });

  group('InitWifi', () {
    blocTest<WirelessBloc, WirelessState>(
      'initializes repository, subscribes to streams and adds LoadWireless',
      build: () {
        when(() => mockWirelessRepository.isWirelessEnabled()).thenAnswer((_) async => true);
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => [testWifiNetwork]);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getWifiDeviceState())
            .thenAnswer((_) async => NetworkManagerDeviceState.activated);
        when(() => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => []);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(InitWifi()),
      expect: () => [
        isA<WirelessState>()
            .having((s) => s.isWirelessOn, 'isWirelessOn', true)
            .having((s) => s.savedNetworks, 'savedNetworks', [testWifiNetwork]),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.init()).called(1);
        verify(() => mockWirelessRepository.getWifiEventsStream()).called(1);
        verify(() => mockWirelessRepository.getDeviceEventsStream()).called(1);
        verify(() => mockWirelessRepository.getWirelessDeviceEventsStream()).called(1);
      },
    );
  });

  group('LoadWireless', () {
    blocTest<WirelessBloc, WirelessState>(
      'emits correct state when wireless is disabled',
      build: () {
        when(() => mockWirelessRepository.isWirelessEnabled()).thenAnswer((_) async => false);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const LoadWireless()),
      expect: () => [
        const WirelessState(
          isWirelessOn: false,
          isScanning: false,
          savedNetworks: [],
          availableNetworks: [],
          connectedNetworkName: null,
          connectingNetworkName: null,
        ),
      ],
    );

    blocTest<WirelessBloc, WirelessState>(
      'emits loaded networks when wireless is enabled',
      build: () {
        when(() => mockWirelessRepository.isWirelessEnabled()).thenAnswer((_) async => true);
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => [testWifiNetwork]);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => [testConnectedWifiNetwork]);
        when(() => mockWirelessRepository.getWifiDeviceState())
            .thenAnswer((_) async => NetworkManagerDeviceState.activated);
        when(() => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => [testWifiNetwork]);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const LoadWireless(requestScan: false)),
      expect: () => [
        WirelessState(
          isWirelessOn: true,
          savedNetworks: [testWifiNetwork],
          myNetworks: [testConnectedWifiNetwork],
          availableNetworks: [testWifiNetwork],
          connectedNetworkName: 'Test_WiFi_Connected',
        ),
      ],
    );
  });

  group('ToggleWirelessPower', () {
    blocTest<WirelessBloc, WirelessState>(
      'disables wireless and clears networks when toggled off',
      build: () {
        when(() => mockWirelessRepository.setWifiEnabled(false)).thenAnswer((_) async {});
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const ToggleWirelessPower(false)),
      expect: () => [
        const WirelessState(
          isWirelessOn: false,
          isScanning: false,
          connectingNetworkName: null,
          connectedNetworkName: null,
          savedNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.setWifiEnabled(false)).called(1);
      },
    );

    blocTest<WirelessBloc, WirelessState>(
      'enables wireless, starts scanning and loads networks when toggled on',
      build: () {
        when(() => mockWirelessRepository.setWifiEnabled(true)).thenAnswer((_) async {});
        when(() => mockWirelessRepository.isWirelessEnabled()).thenAnswer((_) async => true);
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getWifiDeviceState())
            .thenAnswer((_) async => NetworkManagerDeviceState.disconnected);
        when(() => mockWirelessRepository.getAvailableNetworks(
          requestScan: any(named: 'requestScan'),
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => []);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const ToggleWirelessPower(true)),
      expect: () => [
        const WirelessState(
          isWirelessOn: true,
          isScanning: true,
          connectingNetworkName: null,
          savedNetworks: [],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.setWifiEnabled(true)).called(1);
      },
    );
  });

  group('ScanNetworks', () {
    blocTest<WirelessBloc, WirelessState>(
      'emits isScanning: false after delay if wireless is on',
      build: () => wirelessBloc,
      seed: () => const WirelessState(isWirelessOn: true, isScanning: true),
      act: (bloc) => bloc.add(const ScanNetworks()),
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const WirelessState(isWirelessOn: true, isScanning: false),
      ],
    );
  });

  group('ConnectToNetworkEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'emits connecting state and calls repository connect',
      build: () {
        when(() => mockWirelessRepository.connectToNetwork(
          any(),
          any(),
          enterpriseConfig: any(named: 'enterpriseConfig'),
        )).thenAnswer((_) async {});
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const ConnectToNetworkEvent('Test_WiFi', 'password123')),
      expect: () => [
        const WirelessState(connectingNetworkName: 'Test_WiFi'),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.connectToNetwork('Test_WiFi', 'password123')).called(1);
      },
    );

    blocTest<WirelessBloc, WirelessState>(
      'emits error when repository connect throws',
      build: () {
        when(() => mockWirelessRepository.connectToNetwork(
          any(),
          any(),
          enterpriseConfig: any(named: 'enterpriseConfig'),
        )).thenThrow(Exception('Failed connection'));
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const ConnectToNetworkEvent('Test_WiFi', 'password123')),
      expect: () => [
        const WirelessState(connectingNetworkName: 'Test_WiFi'),
        isA<WirelessState>()
            .having((s) => s.connectingNetworkName, 'connectingNetworkName', null)
            .having((s) => s.error?.type, 'error.type', WirelessErrorType.connectionFailed)
            .having((s) => s.error?.message, 'error.message', contains('Failed connection')),
      ],
    );
  });

  group('AddNetworkEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'emits connecting state, calls addNetwork, and loads networks',
      build: () {
        when(() => mockWirelessRepository.addNetwork(
          any(),
          any(),
          any(),
        )).thenAnswer((_) async {});
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => [testWifiNetwork]);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getAvailableNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => []);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const AddNetworkEvent('New_WiFi', WirelessSecurity.wpaWpa2Personal)),
      expect: () => [
        const WirelessState(connectingNetworkName: 'New_WiFi'),
        isA<WirelessState>()
            .having((s) => s.savedNetworks, 'savedNetworks', [testWifiNetwork]),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.addNetwork('New_WiFi', WirelessSecurity.wpaWpa2Personal, null)).called(1);
      },
    );

    blocTest<WirelessBloc, WirelessState>(
      'emits error when repository addNetwork throws',
      build: () {
        when(() => mockWirelessRepository.addNetwork(
          any(),
          any(),
          any(),
        )).thenThrow(Exception('Add failed'));
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(const AddNetworkEvent('New_WiFi', WirelessSecurity.wpaWpa2Personal)),
      expect: () => [
        const WirelessState(connectingNetworkName: 'New_WiFi'),
        isA<WirelessState>()
            .having((s) => s.connectingNetworkName, 'connectingNetworkName', null)
            .having((s) => s.error?.type, 'error.type', WirelessErrorType.addNetworkFailed),
      ],
    );
  });

  group('ForgetNetworkEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls forgetNetwork and reloads networks',
      build: () {
        when(() => mockWirelessRepository.forgetNetwork(any())).thenAnswer((_) async {});
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getAvailableNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => []);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(ForgetNetworkEvent(testWifiNetwork)),
      expect: () => [
        const WirelessState(
          savedNetworks: [],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.forgetNetwork(testWifiNetwork)).called(1);
      },
    );
  });

  group('UpdateNetworkSettingsEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls updateNetwork and reloads networks',
      build: () {
        when(() => mockWirelessRepository.updateNetwork(any())).thenAnswer((_) async {});
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => [testWifiNetwork]);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getAvailableNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => []);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(UpdateNetworkSettingsEvent(testWifiNetwork)),
      expect: () => [
        WirelessState(
          savedNetworks: [testWifiNetwork],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.updateNetwork(testWifiNetwork)).called(1);
      },
    );
  });

  group('UpdateIPSettingsEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls updateIPSettings and reloads networks',
      build: () {
        when(() => mockWirelessRepository.updateIPSettings(
          any(),
          any(),
          any(),
          any(),
          any(),
        )).thenAnswer((_) async {});
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => [testWifiNetwork]);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getAvailableNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => []);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(UpdateIPSettingsEvent(
        network: testWifiNetwork,
        ipConfigType: IPv4ConfigType.manual,
        ipAddress: '192.168.1.100',
        subnetMask: '255.255.255.0',
        router: '192.168.1.1',
      )),
      expect: () => [
        WirelessState(
          savedNetworks: [testWifiNetwork],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.updateIPSettings(
          testWifiNetwork,
          IPv4ConfigType.manual,
          '192.168.1.100',
          '255.255.255.0',
          '192.168.1.1',
        )).called(1);
      },
    );
  });

  group('UpdateDNSSettingsEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls updateDNSSettings and reloads networks',
      build: () {
        when(() => mockWirelessRepository.updateDNSSettings(
          any(),
          any(),
          any(),
          any(),
        )).thenAnswer((_) async {});
        when(() => mockWirelessRepository.getSavedNetworks()).thenAnswer((_) async => [testWifiNetwork]);
        when(() => mockWirelessRepository.getMyNetworks()).thenAnswer((_) async => []);
        when(() => mockWirelessRepository.getAvailableNetworks(
          savedNetworks: any(named: 'savedNetworks'),
        )).thenAnswer((_) async => []);
        return wirelessBloc;
      },
      act: (bloc) => bloc.add(UpdateDNSSettingsEvent(
        network: testWifiNetwork,
        dnsConfigType: DNSConfigType.manual,
        dnsServers: const ['8.8.8.8'],
        dnsSearchDomains: const ['local'],
      )),
      expect: () => [
        WirelessState(
          savedNetworks: [testWifiNetwork],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.updateDNSSettings(
          testWifiNetwork,
          DNSConfigType.manual,
          const ['8.8.8.8'],
          const ['local'],
        )).called(1);
      },
    );
  });
}
