import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_settings/features/wireless/blocs/wireless_bloc.dart';
import 'package:mechanix_settings/features/wireless/data/models/enterprise_config.dart';
import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/features/wireless/data/models/wifi_network.dart';
import 'package:mechanix_settings/features/wireless/data/repositories/wireless_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm/nm.dart';

class MockWirelessRepository extends Mock implements WirelessRepository {}

void main() {
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

  void setupDefaultMocks(MockWirelessRepository repository) {
    when(() => repository.init()).thenAnswer((_) async {});
    when(() => repository.isWirelessEnabled()).thenReturn(false);
    when(() => repository.requestScan()).thenAnswer((_) async {});
    when(
      () => repository.getConnectivityState(),
    ).thenReturn(NetworkManagerConnectivityState.unknown);
    when(
      () => repository.getWifiEventsStream(),
    ).thenAnswer((_) => const Stream<List<String>>.empty());
    when(
      () => repository.getDeviceEventsStream(),
    ).thenAnswer((_) => const Stream<List<String>>.empty());
    when(
      () => repository.getWirelessDeviceEventsStream(),
    ).thenAnswer((_) => const Stream<List<String>>.empty());
    when(
      () => repository.addNetwork(any(), any(), any(that: anything)),
    ).thenAnswer((_) async {});
    when(() => repository.forgetNetwork(any())).thenAnswer((_) async {});
    when(() => repository.updateNetwork(any())).thenAnswer((_) async {});
    when(
      () => repository.updateIPSettings(
        any(),
        any(),
        any(that: anything),
        any(that: anything),
        any(that: anything),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.updateDNSSettings(
        any(),
        any(),
        any(that: anything),
        any(that: anything),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.isCaptivePortal()).thenAnswer((_) async => false);
    when(() => repository.openCaptivePortal()).thenAnswer((_) async {});
    when(() => repository.close()).thenAnswer((_) async {});
  }

  void stubWirelessActiveDefaults(
    MockWirelessRepository repository, {
    List<WifiNetwork>? savedNetworks,
  }) {
    when(() => repository.isWirelessEnabled()).thenReturn(true);
    when(
      () => repository.getSavedNetworks(),
    ).thenAnswer((_) async => savedNetworks ?? []);
    when(() => repository.getMyNetworks()).thenAnswer((_) async => []);
    when(
      () =>
          repository.getMyNetworks(savedNetworks: any(named: 'savedNetworks')),
    ).thenAnswer((_) async => []);
    when(
      () => repository.getAvailableNetworks(
        requestScan: any(named: 'requestScan'),
        savedNetworks: any(named: 'savedNetworks'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => repository.getWifiDeviceState(),
    ).thenReturn(NetworkManagerDeviceState.activated);
    when(() => repository.isCaptivePortal()).thenAnswer((_) async => false);
  }

  setUp(() {
    mockWirelessRepository = MockWirelessRepository();
  });

  tearDown(() async {
    await Future.delayed(Duration.zero);
  });

  group('WirelessBloc Initial State', () {
    test('initial state defaults to uninitialized repository state', () {
      setupDefaultMocks(mockWirelessRepository);
      final bloc = WirelessBloc(wirelessRepository: mockWirelessRepository);
      expect(bloc.state.isWirelessOn, false);
      expect(bloc.state.connectivityState, NetworkManagerConnectivityState.unknown);
    });

    test('initial state immediately reflects initialized repository state when wireless is enabled', () {
      setupDefaultMocks(mockWirelessRepository);
      when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
      when(
        () => mockWirelessRepository.getConnectivityState(),
      ).thenReturn(NetworkManagerConnectivityState.full);

      final bloc = WirelessBloc(wirelessRepository: mockWirelessRepository);
      expect(bloc.state.isWirelessOn, true);
      expect(bloc.state.connectivityState, NetworkManagerConnectivityState.full);
    });
  });

  group('InitWifi', () {
    blocTest<WirelessBloc, WirelessState>(
      'initializes repository, subscribes to streams and adds LoadWireless',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
        when(
          () => mockWirelessRepository.getSavedNetworks(),
        ).thenAnswer((_) async => [testWifiNetwork]);
        when(
          () => mockWirelessRepository.getMyNetworks(
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockWirelessRepository.getWifiDeviceState(),
        ).thenReturn(NetworkManagerDeviceState.activated);
        when(
          () => mockWirelessRepository.getAvailableNetworks(
            requestScan: any(named: 'requestScan'),
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer((_) async => []);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(),
      act: (bloc) => bloc.add(InitWifi()),
      expect: () => [
        isA<WirelessState>()
            .having((s) => s.isWirelessOn, 'isWirelessOn', true)
            .having((s) => s.savedNetworks, 'savedNetworks', []),
        isA<WirelessState>()
            .having((s) => s.isWirelessOn, 'isWirelessOn', true)
            .having((s) => s.savedNetworks, 'savedNetworks', [testWifiNetwork]),
      ],
      verify: (_) {
        verify(() => mockWirelessRepository.init()).called(1);
        verify(() => mockWirelessRepository.getWifiEventsStream()).called(1);
        verify(() => mockWirelessRepository.getDeviceEventsStream()).called(1);
        verify(
          () => mockWirelessRepository.getWirelessDeviceEventsStream(),
        ).called(1);
      },
    );
  });

  group('LoadWireless', () {
    blocTest<WirelessBloc, WirelessState>(
      'emits correct state when wireless is disabled',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.isWirelessEnabled(),
        ).thenReturn(false);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
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
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
        when(
          () => mockWirelessRepository.getSavedNetworks(),
        ).thenAnswer((_) async => [testWifiNetwork]);
        when(
          () => mockWirelessRepository.getMyNetworks(
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer((_) async => [testConnectedWifiNetwork]);
        when(
          () => mockWirelessRepository.getWifiDeviceState(),
        ).thenReturn(NetworkManagerDeviceState.activated);
        when(
          () => mockWirelessRepository.getAvailableNetworks(
            requestScan: any(named: 'requestScan'),
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer((_) async => [testWifiNetwork]);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
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
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.setWifiEnabled(false),
        ).thenAnswer((_) async {});
        when(
          () => mockWirelessRepository.isWirelessEnabled(),
        ).thenReturn(false);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
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
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.setWifiEnabled(true),
        ).thenAnswer((_) async {});
        when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
        when(
          () => mockWirelessRepository.getSavedNetworks(),
        ).thenAnswer((_) async => []);
        when(
          () => mockWirelessRepository.getMyNetworks(
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockWirelessRepository.getWifiDeviceState(),
        ).thenReturn(NetworkManagerDeviceState.disconnected);
        when(
          () => mockWirelessRepository.getAvailableNetworks(
            requestScan: any(named: 'requestScan'),
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer((_) async => []);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
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
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(isWirelessOn: true, isScanning: true),
      act: (bloc) => bloc.add(const ScanNetworks()),
      wait: const Duration(milliseconds: 2100),
      expect: () => [
        const WirelessState(isWirelessOn: true, isScanning: false),
      ],
    );
  });

  group('ConnectToNetworkEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'emits connecting state and calls repository connect',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.connectToNetwork(
            any(),
            any(),
            enterpriseConfig: any(named: 'enterpriseConfig', that: anything),
          ),
        ).thenAnswer((_) async {});
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      act: (bloc) =>
          bloc.add(const ConnectToNetworkEvent('Test_WiFi', 'password123')),
      expect: () => [
        isA<WirelessState>().having(
          (s) => s.connectingNetworkName,
          'connectingNetworkName',
          'Test_WiFi',
        ),
      ],
      verify: (_) {
        verify(
          () => mockWirelessRepository.connectToNetwork(
            'Test_WiFi',
            'password123',
          ),
        ).called(1);
      },
    );

    blocTest<WirelessBloc, WirelessState>(
      'emits error when repository connect throws',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.connectToNetwork(
            any(),
            any(),
            enterpriseConfig: any(named: 'enterpriseConfig', that: anything),
          ),
        ).thenThrow(Exception('Failed connection'));
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(isWirelessOn: true, savedNetworks: []),
      act: (bloc) =>
          bloc.add(const ConnectToNetworkEvent('Test_WiFi', 'password123')),
      expect: () => [
        const WirelessState(
          isWirelessOn: true,
          savedNetworks: [],
          connectingNetworkName: 'Test_WiFi',
        ),
        const WirelessState(
          isWirelessOn: true,
          savedNetworks: [],
          connectingNetworkName: null,
          error: WirelessFailure(
            type: WirelessErrorType.connectionFailed,
            message: 'Exception: Failed connection',
            data: {'networkName': 'Test_WiFi'},
          ),
        ),
      ],
    );
  });

  group('AddNetworkEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'emits connecting state, calls addNetwork, and loads networks',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(
          mockWirelessRepository,
          savedNetworks: [testWifiNetwork],
        );
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      act: (bloc) => bloc.add(
        const AddNetworkEvent('New_WiFi', WirelessSecurity.wpaWpa2Personal),
      ),
      expect: () => [
        isA<WirelessState>().having(
          (s) => s.connectingNetworkName,
          'connectingNetworkName',
          'New_WiFi',
        ),
        isA<WirelessState>().having((s) => s.savedNetworks, 'savedNetworks', [
          testWifiNetwork,
        ]),
      ],
      verify: (_) {
        verify(
          () => mockWirelessRepository.addNetwork(
            'New_WiFi',
            WirelessSecurity.wpaWpa2Personal,
            null,
          ),
        ).called(1);
      },
    );

    blocTest<WirelessBloc, WirelessState>(
      'emits error when repository addNetwork throws',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.addNetwork(
            any(),
            any(),
            any(that: anything),
          ),
        ).thenThrow(Exception('Add failed'));
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(isWirelessOn: true, savedNetworks: []),
      act: (bloc) => bloc.add(
        const AddNetworkEvent('New_WiFi', WirelessSecurity.wpaWpa2Personal),
      ),
      expect: () => [
        const WirelessState(
          isWirelessOn: true,
          savedNetworks: [],
          connectingNetworkName: 'New_WiFi',
        ),
        const WirelessState(
          isWirelessOn: true,
          savedNetworks: [],
          connectingNetworkName: null,
          error: WirelessFailure(
            type: WirelessErrorType.addNetworkFailed,
            message: 'Exception: Add failed',
            data: {'networkName': 'New_WiFi'},
          ),
        ),
      ],
    );
  });

  group('ForgetNetworkEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls forgetNetwork and reloads networks',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      act: (bloc) => bloc.add(ForgetNetworkEvent(testWifiNetwork)),
      expect: () => [
        const WirelessState(
          isWirelessOn: true,
          savedNetworks: [],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(
          () => mockWirelessRepository.forgetNetwork(testWifiNetwork),
        ).called(1);
      },
    );
  });

  group('UpdateNetworkSettingsEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls updateNetwork and reloads networks',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(
          mockWirelessRepository,
          savedNetworks: [testWifiNetwork],
        );
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(isWirelessOn: true, savedNetworks: []),
      act: (bloc) => bloc.add(UpdateNetworkSettingsEvent(testWifiNetwork)),
      expect: () => [
        WirelessState(
          isWirelessOn: true,
          savedNetworks: [testWifiNetwork],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(
          () => mockWirelessRepository.updateNetwork(testWifiNetwork),
        ).called(1);
      },
    );
  });

  group('UpdateIPSettingsEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls updateIPSettings and reloads networks',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(
          mockWirelessRepository,
          savedNetworks: [testWifiNetwork],
        );
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(isWirelessOn: true, savedNetworks: []),
      act: (bloc) => bloc.add(
        UpdateIPSettingsEvent(
          network: testWifiNetwork,
          ipConfigType: IPv4ConfigType.manual,
          ipAddress: '192.168.1.100',
          subnetMask: '255.255.255.0',
          router: '192.168.1.1',
        ),
      ),
      expect: () => [
        WirelessState(
          isWirelessOn: true,
          savedNetworks: [testWifiNetwork],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(
          () => mockWirelessRepository.updateIPSettings(
            testWifiNetwork,
            IPv4ConfigType.manual,
            '192.168.1.100',
            '255.255.255.0',
            '192.168.1.1',
          ),
        ).called(1);
      },
    );
  });

  group('UpdateDNSSettingsEvent', () {
    blocTest<WirelessBloc, WirelessState>(
      'calls updateDNSSettings and reloads networks',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(
          mockWirelessRepository,
          savedNetworks: [testWifiNetwork],
        );
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(isWirelessOn: true, savedNetworks: []),
      act: (bloc) => bloc.add(
        UpdateDNSSettingsEvent(
          network: testWifiNetwork,
          dnsConfigType: DNSConfigType.manual,
          dnsServers: const ['8.8.8.8'],
          dnsSearchDomains: const ['local'],
        ),
      ),
      expect: () => [
        WirelessState(
          isWirelessOn: true,
          savedNetworks: [testWifiNetwork],
          myNetworks: [],
          availableNetworks: [],
        ),
      ],
      verify: (_) {
        verify(
          () => mockWirelessRepository.updateDNSSettings(
            testWifiNetwork,
            DNSConfigType.manual,
            const ['8.8.8.8'],
            const ['local'],
          ),
        ).called(1);
      },
    );
  });

  group('Network Change Logging', () {
    blocTest<WirelessBloc, WirelessState>(
      'logs when network appears and when network goes away',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        when(() => mockWirelessRepository.isWirelessEnabled()).thenReturn(true);
        when(
          () => mockWirelessRepository.getSavedNetworks(),
        ).thenAnswer((_) async => []);
        when(
          () => mockWirelessRepository.getMyNetworks(
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockWirelessRepository.getWifiDeviceState(),
        ).thenReturn(NetworkManagerDeviceState.activated);
        when(
          () => mockWirelessRepository.getAvailableNetworks(
            requestScan: any(named: 'requestScan'),
            savedNetworks: any(named: 'savedNetworks'),
          ),
        ).thenAnswer(
          (_) async => [
            const WifiNetwork(name: 'New_Network_1', isConnected: false),
          ],
        );
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(
        isWirelessOn: true,
        availableNetworks: [
          WifiNetwork(name: 'Old_Network_Gone', isConnected: false),
        ],
      ),
      act: (bloc) => bloc.add(const LoadWireless(requestScan: false)),
      expect: () => [
        const WirelessState(
          isWirelessOn: true,
          savedNetworks: [],
          myNetworks: [],
          availableNetworks: [
            WifiNetwork(name: 'New_Network_1', isConnected: false),
          ],
        ),
      ],
    );
  });

  group('Saved Network Switching Flow', () {
    test('hasNoInternet is false when connectingNetworkName is set', () {
      const state = WirelessState(
        connectedNetworkName: 'Wi-Fi A',
        connectingNetworkName: 'Wi-Fi B',
        connectivityState: NetworkManagerConnectivityState.none,
      );
      expect(state.hasNoInternet, isFalse);
    });

    blocTest<WirelessBloc, WirelessState>(
      'suppresses offline message and stays in transition state during network switch until connected',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.connectToNetwork(any(), any()),
        ).thenAnswer((_) async {});
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(
        isWirelessOn: true,
        connectedNetworkName: 'Wi-Fi A',
        connectivityState: NetworkManagerConnectivityState.full,
      ),
      act: (bloc) {
        bloc.add(const ConnectToNetworkEvent('Wi-Fi B', null));
      },
      expect: () => [
        isA<WirelessState>()
            .having(
              (s) => s.connectingNetworkName,
              'connectingNetworkName',
              'Wi-Fi B',
            )
            .having((s) => s.hasNoInternet, 'hasNoInternet', false),
      ],
    );

    blocTest<WirelessBloc, WirelessState>(
      'ignores intermediate disconnected device state while connection is in progress',
      build: () {
        mockWirelessRepository = MockWirelessRepository();
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.connectToNetwork(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockWirelessRepository.getWifiDeviceState(),
        ).thenReturn(NetworkManagerDeviceState.disconnected);
        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      seed: () => const WirelessState(
        isWirelessOn: true,
        connectedNetworkName: 'Wi-Fi A',
        connectingNetworkName: 'Wi-Fi B',
      ),
      act: (bloc) {
        bloc.add(
          const ConnectivityStateChangedEvent(
            NetworkManagerConnectivityState.none,
          ),
        );
      },
      expect: () => [
        isA<WirelessState>()
            .having(
              (s) => s.connectivityState,
              'connectivityState',
              NetworkManagerConnectivityState.none,
            )
            .having(
              (s) => s.connectingNetworkName,
              'connectingNetworkName',
              'Wi-Fi B',
            )
            .having((s) => s.hasNoInternet, 'hasNoInternet', false),
      ],
    );
  });

  group('Captive Portal Events', () {
    blocTest<WirelessBloc, WirelessState>(
      'LoadWireless detects captive portal and updates state',
      build: () {
        setupDefaultMocks(mockWirelessRepository);
        stubWirelessActiveDefaults(mockWirelessRepository);
        when(
          () => mockWirelessRepository.isCaptivePortal(),
        ).thenAnswer((_) async => true);

        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      act: (bloc) => bloc.add(const LoadWireless(requestScan: false)),
      expect: () => [
        const WirelessState(
          isWirelessOn: true,
          isCaptivePortal: true,
        ),
      ],
    );
    blocTest<WirelessBloc, WirelessState>(
      'OpenCaptivePortal event calls repository openCaptivePortal',
      build: () {
        setupDefaultMocks(mockWirelessRepository);
        when(
          () => mockWirelessRepository.openCaptivePortal(),
        ).thenAnswer((_) async {});

        return WirelessBloc(wirelessRepository: mockWirelessRepository);
      },
      act: (bloc) => bloc.add(const OpenCaptivePortal()),
      verify: (_) {
        verify(() => mockWirelessRepository.openCaptivePortal()).called(1);
      },
    );
  });

  group('Lifecycle & Stream Subscription Safety', () {
    test('close() cancels timers and stream subscriptions safely', () async {
      setupDefaultMocks(mockWirelessRepository);
      final bloc = WirelessBloc(wirelessRepository: mockWirelessRepository);
      bloc.add(InitWifi());
      await Future.delayed(const Duration(milliseconds: 50));
      await expectLater(bloc.close(), completes);
    });

    test('multiple InitWifi calls safely re-subscribe without throwing', () async {
      setupDefaultMocks(mockWirelessRepository);
      final bloc = WirelessBloc(wirelessRepository: mockWirelessRepository);
      bloc.add(InitWifi());
      await Future.delayed(const Duration(milliseconds: 50));
      bloc.add(InitWifi());
      await Future.delayed(const Duration(milliseconds: 50));
      await bloc.close();
      verify(() => mockWirelessRepository.init()).called(2);
    });
  });
}
