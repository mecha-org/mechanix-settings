import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bluez/bluez.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository_impl.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';

class MockBlueZClient extends Mock implements BlueZClient {}

class MockBlueZAdapter extends Mock implements BlueZAdapter {}

class MockBlueZDevice extends Mock implements BlueZDevice {}

void main() {
  late BluetoothRepositoryImpl repository;
  late MockBlueZClient mockClient;
  late MockBlueZAdapter mockAdapter;
  late StreamController<List<String>> adapterPropsController;
  late StreamController<BlueZDevice> deviceAddedController;
  late StreamController<BlueZDevice> deviceRemovedController;

  setUpAll(() {
    registerFallbackValue(MockBlueZDevice());
  });

  MockBlueZDevice createMockDevice({
    required String name,
    required String alias,
    required String address,
    required int deviceClass,
    required List<BlueZUUID> uuids,
    required bool connected,
    required bool paired,
  }) {
    final mockDevice = MockBlueZDevice();
    when(() => mockDevice.name).thenReturn(name);
    when(() => mockDevice.alias).thenReturn(alias);
    when(() => mockDevice.address).thenReturn(address);
    when(() => mockDevice.deviceClass).thenReturn(deviceClass);
    when(() => mockDevice.uuids).thenReturn(uuids);
    when(() => mockDevice.connected).thenReturn(connected);
    when(() => mockDevice.paired).thenReturn(paired);
    when(
      () => mockDevice.propertiesChanged,
    ).thenAnswer((_) => const Stream<List<String>>.empty());

    when(() => mockDevice.pair()).thenAnswer((_) async => {});
    when(() => mockDevice.connect()).thenAnswer((_) async => {});
    when(() => mockDevice.disconnect()).thenAnswer((_) async => {});
    return mockDevice;
  }

  setUp(() {
    mockClient = MockBlueZClient();
    mockAdapter = MockBlueZAdapter();
    adapterPropsController = StreamController<List<String>>.broadcast();
    deviceAddedController = StreamController<BlueZDevice>.broadcast();
    deviceRemovedController = StreamController<BlueZDevice>.broadcast();

    when(() => mockClient.adapters).thenReturn([mockAdapter]);
    when(() => mockClient.devices).thenReturn([]);
    when(
      () => mockClient.deviceAdded,
    ).thenAnswer((_) => deviceAddedController.stream);
    when(
      () => mockClient.deviceRemoved,
    ).thenAnswer((_) => deviceRemovedController.stream);
    when(() => mockClient.close()).thenAnswer((_) async => {});

    when(() => mockAdapter.powered).thenReturn(true);
    when(() => mockAdapter.discoverable).thenReturn(false);
    when(() => mockAdapter.discovering).thenReturn(false);
    when(() => mockAdapter.name).thenReturn('Test Adapter');
    when(() => mockAdapter.alias).thenReturn('test-adapter');
    when(
      () => mockAdapter.propertiesChanged,
    ).thenAnswer((_) => adapterPropsController.stream);

    repository = BluetoothRepositoryImpl(client: mockClient);
  });

  tearDown(() async {
    await adapterPropsController.close();
    await deviceAddedController.close();
    await deviceRemovedController.close();
    await repository.close();
  });

  group('BluetoothRepositoryImpl initialization', () {
    test('init calls ensures connection and configures listeners', () async {
      await repository.init();
      expect(await repository.getBluezAdapter(), mockAdapter);
      verify(() => mockClient.adapters).called(greaterThanOrEqualTo(1));
    });

    test('init handles empty adapters list gracefully', () async {
      when(() => mockClient.adapters).thenReturn([]);
      await repository.init();
      expect(await repository.getBluezAdapter(), null);
    });
  });

  group('Bluetooth power status & toggling', () {
    test('isBluetoothEnabled returns correct state from adapter', () async {
      await repository.init();
      when(() => mockAdapter.powered).thenReturn(true);
      expect(await repository.isBluetoothEnabled(), true);

      when(() => mockAdapter.powered).thenReturn(false);
      expect(await repository.isBluetoothEnabled(), false);
    });

    test('isBluetoothEnabled returns false when adapter is null', () async {
      when(() => mockClient.adapters).thenReturn([]);
      await repository.init();
      expect(await repository.isBluetoothEnabled(), false);
    });

    test('togglePower returns true instantly if states match', () async {
      await repository.init();
      when(() => mockAdapter.powered).thenReturn(true);
      final result = await repository.togglePower(true);
      expect(result, true);
      verifyNever(() => mockAdapter.setPowered(any()));
    });

    test(
      'togglePower sets power and returns result when states differ',
      () async {
        await repository.init();
        var poweredValue = false;
        when(() => mockAdapter.powered).thenAnswer((_) => poweredValue);
        when(() => mockAdapter.setPowered(true)).thenAnswer((_) async {
          poweredValue = true;
        });

        final result = await repository.togglePower(true);
        expect(result, true);
        verify(() => mockAdapter.setPowered(true)).called(1);
      },
    );

    test('togglePower returns false if setPowered throws', () async {
      await repository.init();
      when(() => mockAdapter.powered).thenReturn(false);
      when(() => mockAdapter.setPowered(true)).thenThrow(Exception('Fail'));

      final result = await repository.togglePower(true);
      expect(result, false);
    });
  });

  group('Discoverable settings', () {
    test('isDiscoverable returns correct state', () async {
      await repository.init();
      when(() => mockAdapter.discoverable).thenReturn(true);
      expect(await repository.isDiscoverable(), true);

      when(() => mockAdapter.discoverable).thenReturn(false);
      expect(await repository.isDiscoverable(), false);
    });

    test('setDiscoverable calls setDiscoverable on adapter', () async {
      await repository.init();
      when(() => mockAdapter.setDiscoverable(true)).thenAnswer((_) async {});
      await repository.setDiscoverable(true);
      verify(() => mockAdapter.setDiscoverable(true)).called(1);
    });
  });

  group('Discovery/Scanning management', () {
    test('startDiscovery calls adapter startDiscovery if powered', () async {
      await repository.init();
      when(() => mockAdapter.powered).thenReturn(true);
      when(() => mockAdapter.discovering).thenReturn(false);
      when(() => mockAdapter.startDiscovery()).thenAnswer((_) async {});

      await repository.startDiscovery();
      verify(() => mockAdapter.startDiscovery()).called(1);
    });

    test(
      'startDiscovery does not call adapter startDiscovery if already discovering',
      () async {
        await repository.init();
        when(() => mockAdapter.powered).thenReturn(true);
        when(() => mockAdapter.discovering).thenReturn(true);

        await repository.startDiscovery();
        verifyNever(() => mockAdapter.startDiscovery());
      },
    );

    test(
      'startDiscovery does not call adapter startDiscovery if adapter powered off',
      () async {
        await repository.init();
        when(() => mockAdapter.powered).thenReturn(false);

        await repository.startDiscovery();
        verifyNever(() => mockAdapter.startDiscovery());
      },
    );

    test('stopDiscovery calls adapter stopDiscovery', () async {
      await repository.init();
      when(() => mockAdapter.stopDiscovery()).thenAnswer((_) async {});

      await repository.stopDiscovery();
      verify(() => mockAdapter.stopDiscovery()).called(1);
    });

    test('stopDiscovery ignores No discovery started exception', () async {
      await repository.init();
      when(
        () => mockAdapter.stopDiscovery(),
      ).thenThrow(Exception('No discovery started'));

      // Should not throw
      await repository.stopDiscovery();
    });
  });

  group('Device interactions', () {
    test('pairDevice calls pair on matching device', () async {
      final mockDevice = createMockDevice(
        name: 'Device1',
        alias: 'Dev1',
        address: '11:22:33:44:55:66',
        deviceClass: 0,
        uuids: [],
        connected: false,
        paired: false,
      );
      when(() => mockClient.devices).thenReturn([mockDevice]);

      await repository.init();
      await repository.pairDevice('11:22:33:44:55:66');

      verify(() => mockDevice.pair()).called(1);
    });

    test('pairDevice throws when device not found', () async {
      when(() => mockClient.devices).thenReturn([]);
      await repository.init();

      expect(() => repository.pairDevice('NonExistent'), throwsException);
    });

    test('connectToDevice calls connect on matching device', () async {
      final mockDevice = createMockDevice(
        name: 'Device1',
        alias: 'Dev1',
        address: '11:22:33:44:55:66',
        deviceClass: 0,
        uuids: [],
        connected: false,
        paired: false,
      );
      when(() => mockClient.devices).thenReturn([mockDevice]);

      await repository.init();
      await repository.connectToDevice('Dev1');

      verify(() => mockDevice.connect()).called(1);
    });

    test('disconnectFromDevice calls disconnect on matching device', () async {
      final mockDevice = createMockDevice(
        name: 'Device1',
        alias: 'Dev1',
        address: '11:22:33:44:55:66',
        deviceClass: 0,
        uuids: [],
        connected: true,
        paired: true,
      );
      when(() => mockClient.devices).thenReturn([mockDevice]);

      await repository.init();
      await repository.disconnectFromDevice('Device1');

      verify(() => mockDevice.disconnect()).called(1);
    });

    test(
      'forgetDevice disconnects if connected and then removes device',
      () async {
        final mockDevice = createMockDevice(
          name: 'Device1',
          alias: 'Dev1',
          address: '11:22:33:44:55:66',
          deviceClass: 0,
          uuids: [],
          connected: true,
          paired: true,
        );
        when(() => mockClient.devices).thenReturn([mockDevice]);
        when(
          () => mockAdapter.removeDevice(mockDevice),
        ).thenAnswer((_) async {});

        await repository.init();
        await repository.forgetDevice('11:22:33:44:55:66');

        verify(() => mockDevice.disconnect()).called(1);
        verify(() => mockAdapter.removeDevice(mockDevice)).called(1);
      },
    );
  });

  group('Local device name info', () {
    test('getLocalDeviceName returns alias or name from adapter', () async {
      await repository.init();
      when(() => mockAdapter.alias).thenReturn('my-alias');
      expect(await repository.getLocalDeviceName(), 'my-alias');

      when(() => mockAdapter.alias).thenReturn('');
      when(() => mockAdapter.name).thenReturn('my-name');
      expect(await repository.getLocalDeviceName(), 'my-name');
    });

    test('updateLocalDeviceName updates adapter alias', () async {
      await repository.init();
      when(() => mockAdapter.setAlias('new-name')).thenAnswer((_) async {});

      await repository.updateLocalDeviceName('new-name');
      verify(() => mockAdapter.setAlias('new-name')).called(1);
    });
  });

  group('Device mapping & classification', () {
    test('maps deviceClass computer to computer type', () async {
      final mockDevice = createMockDevice(
        name: 'MyPC',
        alias: 'MyPC',
        address: '11:22:33:44:55:66',
        deviceClass: 0x01 << 8, // Computer
        uuids: [],
        connected: false,
        paired: true,
      );
      when(() => mockClient.devices).thenReturn([mockDevice]);

      await repository.init();
      final paired = await repository.getPairedDevices();

      expect(paired.length, 1);
      expect(paired.first.type, BluetoothDeviceType.computer);
    });

    test('maps deviceClass phone to mobile type', () async {
      final mockDevice = createMockDevice(
        name: 'MyPhone',
        alias: 'MyPhone',
        address: '11:22:33:44:55:66',
        deviceClass: 0x02 << 8, // Phone
        uuids: [],
        connected: false,
        paired: true,
      );
      when(() => mockClient.devices).thenReturn([mockDevice]);

      await repository.init();
      final paired = await repository.getPairedDevices();

      expect(paired.length, 1);
      expect(paired.first.type, BluetoothDeviceType.mobile);
    });

    test(
      'maps audio major class and speaker minor class to speaker type',
      () async {
        final mockDevice = createMockDevice(
          name: 'MySpeaker',
          alias: 'MySpeaker',
          address: '11:22:33:44:55:66',
          deviceClass: (0x04 << 8) | (0x05 << 2), // Audio Major, Speaker Minor
          uuids: [],
          connected: false,
          paired: true,
        );
        when(() => mockClient.devices).thenReturn([mockDevice]);

        await repository.init();
        final paired = await repository.getPairedDevices();

        expect(paired.length, 1);
        expect(paired.first.type, BluetoothDeviceType.speaker);
      },
    );

    test(
      'maps audio major class and headphones minor class to headphones type',
      () async {
        final mockDevice = createMockDevice(
          name: 'MyHeadphones',
          alias: 'MyHeadphones',
          address: '11:22:33:44:55:66',
          deviceClass:
              (0x04 << 8) | (0x01 << 2), // Audio Major, Wearable Headset Minor
          uuids: [],
          connected: false,
          paired: true,
        );
        when(() => mockClient.devices).thenReturn([mockDevice]);

        await repository.init();
        final paired = await repository.getPairedDevices();

        expect(paired.length, 1);
        expect(paired.first.type, BluetoothDeviceType.headphones);
      },
    );

    test(
      'ignores non-saved anonymous devices matching MAC address pattern',
      () async {
        final anonymousDevice = createMockDevice(
          name: '11:22:33:44:55:66',
          alias: '',
          address: '11:22:33:44:55:66',
          deviceClass: 0,
          uuids: [],
          connected: false,
          paired: false, // Unsaved
        );
        when(() => mockClient.devices).thenReturn([anonymousDevice]);

        await repository.init();
        final paired = await repository.getPairedDevices();
        expect(paired, isEmpty);
      },
    );
  });

  group('Event Streams & Broadcast Controllers', () {
    test('broadcast controllers emit events on properties changed', () async {
      await repository.init();

      // Setup expectations for stream listeners
      final powerStates = <bool>[];
      final discoverableStates = <bool>[];
      final scanningStates = <bool>[];

      final powerSub = repository.powerStream.listen(powerStates.add);
      final discoverableSub = repository.discoverableStream.listen(
        discoverableStates.add,
      );
      final scanningSub = repository.scanningStream.listen(scanningStates.add);

      // Trigger changes via the adapter propertiesChanged stream
      when(() => mockAdapter.powered).thenReturn(false);
      adapterPropsController.add(['Powered']);
      await Future.delayed(Duration.zero);

      when(() => mockAdapter.discoverable).thenReturn(true);
      adapterPropsController.add(['Discoverable']);
      await Future.delayed(Duration.zero);

      when(() => mockAdapter.discovering).thenReturn(true);
      adapterPropsController.add(['Discovering']);
      await Future.delayed(Duration.zero);

      // Cancel subscriptions
      await powerSub.cancel();
      await discoverableSub.cancel();
      await scanningSub.cancel();

      expect(powerStates, contains(false));
      expect(discoverableStates, contains(true));
      expect(scanningStates, contains(true));
    });
  });
}
