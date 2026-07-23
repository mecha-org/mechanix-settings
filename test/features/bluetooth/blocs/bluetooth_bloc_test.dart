import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mechanix_settings/features/bluetooth/blocs/bluetooth_bloc.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';

class MockBluetoothRepository extends Mock implements BluetoothRepository {}

void main() {
  late BluetoothBloc bluetoothBloc;
  late MockBluetoothRepository mockRepository;

  final testDevice = const BluetoothDevice(
    name: 'Test Device',
    deviceName: 'Test Device',
    type: BluetoothDeviceType.mobile,
    macAddress: '11:22:33:44:55:66',
    isSaved: false,
    isConnected: false,
  );

  final testSavedDevice = const BluetoothDevice(
    name: 'Saved Device',
    deviceName: 'Saved Device',
    type: BluetoothDeviceType.headphones,
    macAddress: 'AA:BB:CC:DD:EE:FF',
    isSaved: true,
    isConnected: false,
  );

  setUpAll(() {
    registerFallbackValue(testDevice);
  });

  setUp(() {
    mockRepository = MockBluetoothRepository();

    // Default mocks to prevent crashes on init
    when(() => mockRepository.init()).thenAnswer((_) async {});
    when(
      () => mockRepository.powerStream,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => mockRepository.scanningStream,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => mockRepository.discoverableStream,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => mockRepository.devicesStream,
    ).thenAnswer((_) => const Stream<List<BluetoothDevice>>.empty());
    when(() => mockRepository.close()).thenAnswer((_) async {});

    bluetoothBloc = BluetoothBloc(mockRepository);
  });

  tearDown(() {
    bluetoothBloc.close();
  });

  group('BluetoothBloc Initial State', () {
    test('initial state is correct', () {
      expect(bluetoothBloc.state, const BluetoothState());
    });
  });

  group('LoadBluetooth', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'initializes repository, listens to streams, and sets state (bluetooth off)',
      build: () {
        when(
          () => mockRepository.isBluetoothEnabled(),
        ).thenAnswer((_) async => false);
        when(
          () => mockRepository.getLocalDeviceName(),
        ).thenAnswer((_) async => 'comet');
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(const LoadBluetooth()),
      expect: () => [
        const BluetoothState(
          isBluetoothOn: false,
          localDeviceName: 'comet',
          isDiscoverable: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.init()).called(1);
        verify(() => mockRepository.powerStream).called(1);
        verify(() => mockRepository.scanningStream).called(1);
        verify(() => mockRepository.discoverableStream).called(1);
        verify(() => mockRepository.devicesStream).called(1);
      },
    );

    test('initializes and triggers RefreshDeviceList if bluetooth is on', () {
      fakeAsync((async) {
        when(
          () => mockRepository.isBluetoothEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.isDiscoverable(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getLocalDeviceName(),
        ).thenAnswer((_) async => 'comet');
        when(() => mockRepository.startDiscovery()).thenAnswer((_) async => {});
        when(() => mockRepository.stopDiscovery()).thenAnswer((_) async => {});
        when(
          () => mockRepository.getPairedDevices(),
        ).thenAnswer((_) async => [testSavedDevice]);

        final localBloc = BluetoothBloc(mockRepository);
        final states = <BluetoothState>[];
        final sub = localBloc.stream.listen(states.add);

        localBloc.add(const LoadBluetooth());
        async.elapse(const Duration(seconds: 20));

        sub.cancel();
        localBloc.close();

        // Verifying that initial state update is emitted first
        expect(
          states,
          contains(
            isA<BluetoothState>()
                .having((s) => s.isBluetoothOn, 'isBluetoothOn', true)
                .having((s) => s.localDeviceName, 'localDeviceName', 'comet')
                .having((s) => s.isDiscoverable, 'isDiscoverable', true),
          ),
        );

        // Verifying RefreshDeviceList calls occurred
        verify(() => mockRepository.startDiscovery()).called(1);
        verify(() => mockRepository.stopDiscovery()).called(1);
      });
    });
  });

  group('ToggleBluetoothPower', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'calls togglePower on repository',
      build: () {
        when(
          () => mockRepository.togglePower(true),
        ).thenAnswer((_) async => true);
        when(() => mockRepository.startDiscovery()).thenAnswer((_) async => {});
        when(() => mockRepository.stopDiscovery()).thenAnswer((_) async => {});
        when(
          () => mockRepository.getPairedDevices(),
        ).thenAnswer((_) async => []);
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(const ToggleBluetoothPower(true)),
      verify: (_) {
        verify(() => mockRepository.togglePower(true)).called(1);
      },
    );
  });

  group('ToggleBluetoothDiscoverable', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'calls setDiscoverable on repository',
      build: () {
        when(
          () => mockRepository.setDiscoverable(true),
        ).thenAnswer((_) async => {});
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(const ToggleBluetoothDiscoverable(true)),
      verify: (_) {
        verify(() => mockRepository.setDiscoverable(true)).called(1);
      },
    );
  });

  group('ScanBluetoothDevices', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'triggers RefreshDeviceList if Bluetooth is on',
      seed: () => const BluetoothState(isBluetoothOn: true),
      build: () {
        when(() => mockRepository.startDiscovery()).thenAnswer((_) async => {});
        when(() => mockRepository.stopDiscovery()).thenAnswer((_) async => {});
        when(
          () => mockRepository.getPairedDevices(),
        ).thenAnswer((_) async => []);
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(const ScanBluetoothDevices()),
      verify: (_) {
        verify(() => mockRepository.startDiscovery()).called(1);
      },
    );

    blocTest<BluetoothBloc, BluetoothState>(
      'does nothing if Bluetooth is off',
      seed: () => const BluetoothState(isBluetoothOn: false),
      build: () => bluetoothBloc,
      act: (bloc) => bloc.add(const ScanBluetoothDevices()),
      verify: (_) {
        verifyNever(() => mockRepository.startDiscovery());
      },
    );
  });

  group('ConnectToDeviceEvent', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'emits connecting state and pairs when device is not saved',
      build: () {
        when(() => mockRepository.pairDevice(any())).thenAnswer((_) async {});
        when(
          () => mockRepository.connectToDevice(any()),
        ).thenAnswer((_) async {});
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(ConnectToDeviceEvent(testDevice)),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        BluetoothState(connectingDevices: {testDevice.macAddress}),
      ],
      verify: (_) {
        verify(
          () => mockRepository.pairDevice(testDevice.macAddress),
        ).called(1);
      },
    );

    blocTest<BluetoothBloc, BluetoothState>(
      'emits connecting state and connects directly when device is saved',
      build: () {
        when(
          () => mockRepository.connectToDevice(any()),
        ).thenAnswer((_) async {});
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(ConnectToDeviceEvent(testSavedDevice)),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        BluetoothState(connectingDevices: {testSavedDevice.macAddress}),
      ],
      verify: (_) {
        verifyNever(() => mockRepository.pairDevice(any()));
        verify(
          () => mockRepository.connectToDevice(testSavedDevice.macAddress),
        ).called(1);
      },
    );

    blocTest<BluetoothBloc, BluetoothState>(
      'emits error failure when pairing fails',
      build: () {
        when(
          () => mockRepository.pairDevice(any()),
        ).thenThrow(Exception('Pair fail'));
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(ConnectToDeviceEvent(testDevice)),
      expect: () => [
        BluetoothState(connectingDevices: {testDevice.macAddress}),
        isA<BluetoothState>()
            .having((s) => s.connectingDevices, 'connectingDevices', isEmpty)
            .having(
              (s) => s.error?.type,
              'error.type',
              BluetoothErrorType.pairingFailed,
            )
            .having(
              (s) => s.error?.message,
              'error.message',
              contains('Pair fail'),
            ),
      ],
    );
  });

  group('CancelPairingEvent', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'removes device from connecting list',
      seed: () =>
          const BluetoothState(connectingDevices: {'11:22:33:44:55:66'}),
      build: () => bluetoothBloc,
      act: (bloc) => bloc.add(CancelPairingEvent(testDevice)),
      expect: () => [const BluetoothState(connectingDevices: {})],
    );
  });

  group('CompletePairingEvent', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'calls connectToDevice on repository',
      build: () {
        when(
          () => mockRepository.connectToDevice(any()),
        ).thenAnswer((_) async {});
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(CompletePairingEvent(testDevice)),
      verify: (_) {
        verify(
          () => mockRepository.connectToDevice(testDevice.macAddress),
        ).called(1);
      },
    );

    blocTest<BluetoothBloc, BluetoothState>(
      'emits failure on connect error',
      seed: () =>
          const BluetoothState(connectingDevices: {'11:22:33:44:55:66'}),
      build: () {
        when(
          () => mockRepository.connectToDevice(any()),
        ).thenThrow(Exception('Connect failed'));
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(CompletePairingEvent(testDevice)),
      expect: () => [
        isA<BluetoothState>()
            .having((s) => s.connectingDevices, 'connectingDevices', isEmpty)
            .having(
              (s) => s.error?.type,
              'error.type',
              BluetoothErrorType.connectionFailed,
            ),
      ],
    );
  });

  group('DisconnectFromDeviceEvent', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'calls disconnectFromDevice on repository',
      build: () {
        when(
          () => mockRepository.disconnectFromDevice(any()),
        ).thenAnswer((_) async {});
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(DisconnectFromDeviceEvent(testSavedDevice)),
      verify: (_) {
        verify(
          () => mockRepository.disconnectFromDevice(testSavedDevice.macAddress),
        ).called(1);
      },
    );
  });

  group('ForgetDeviceEvent', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'calls forgetDevice on repository',
      build: () {
        when(() => mockRepository.forgetDevice(any())).thenAnswer((_) async {});
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(ForgetDeviceEvent(testSavedDevice)),
      verify: (_) {
        verify(
          () => mockRepository.forgetDevice(testSavedDevice.macAddress),
        ).called(1);
      },
    );
  });

  group('RenameLocalDeviceEvent', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'updates name on repository and emits new state name',
      build: () {
        when(
          () => mockRepository.updateLocalDeviceName(any()),
        ).thenAnswer((_) async {});
        return bluetoothBloc;
      },
      act: (bloc) => bloc.add(const RenameLocalDeviceEvent('NewName')),
      expect: () => [const BluetoothState(localDeviceName: 'NewName')],
      verify: (_) {
        verify(() => mockRepository.updateLocalDeviceName('NewName')).called(1);
      },
    );
  });

  group('Internal changed events', () {
    blocTest<BluetoothBloc, BluetoothState>(
      'BluetoothPowerChanged emits power state and clears lists if turned off',
      seed: () => BluetoothState(
        isBluetoothOn: true,
        pairedDevices: [testSavedDevice],
        discoveredDevices: [testDevice],
      ),
      build: () => bluetoothBloc,
      act: (bloc) => bloc.add(const BluetoothPowerChanged(false)),
      expect: () => [
        BluetoothState(
          isBluetoothOn: false,
          pairedDevices: [testSavedDevice],
          discoveredDevices: [testDevice],
        ),
        const BluetoothState(
          isBluetoothOn: false,
          pairedDevices: [],
          discoveredDevices: [],
        ),
      ],
    );

    blocTest<BluetoothBloc, BluetoothState>(
      'BluetoothDiscoverableChanged updates isDiscoverable',
      build: () => bluetoothBloc,
      act: (bloc) => bloc.add(const BluetoothDiscoverableChanged(true)),
      expect: () => [const BluetoothState(isDiscoverable: true)],
    );

    blocTest<BluetoothBloc, BluetoothState>(
      'BluetoothScanningChanged updates isScanning',
      build: () => bluetoothBloc,
      act: (bloc) => bloc.add(const BluetoothScanningChanged(true)),
      expect: () => [const BluetoothState(isScanning: true)],
    );

    blocTest<BluetoothBloc, BluetoothState>(
      'BluetoothDevicesUpdated filters devices into paired and discovered lists',
      build: () => bluetoothBloc,
      act: (bloc) =>
          bloc.add(BluetoothDevicesUpdated([testDevice, testSavedDevice])),
      expect: () => [
        BluetoothState(
          pairedDevices: [testSavedDevice],
          discoveredDevices: [testDevice],
        ),
      ],
    );
  });
}
