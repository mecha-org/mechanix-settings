import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/core/exceptions/about_exceptions.dart';
import 'package:mechanix_settings/features/about/data/repositories/about_repository_impl.dart';

class MockDBusClient extends Mock implements DBusClient {}

class MockDBusRemoteObject extends Mock implements DBusRemoteObject {}

class MockDBusMethodSuccessResponse extends Mock
    implements DBusMethodSuccessResponse {}

void main() {
  late AboutRepositoryImpl repository;
  late MockDBusClient mockClient;
  late MockDBusRemoteObject mockObject;

  setUpAll(() {
    registerFallbackValue(const DBusBoolean(true));
    registerFallbackValue(const DBusString(''));
    registerFallbackValue(const DBusInt64(0));
    registerFallbackValue(const DBusUint64(0));
  });

  setUp(() {
    mockClient = MockDBusClient();
    mockObject = MockDBusRemoteObject();

    when(() => mockClient.close()).thenAnswer((_) async {});

    repository = AboutRepositoryImpl(client: mockClient, object: mockObject);
  });

  group('getAboutDetails', () {
    test('returns AboutDetails with correct mapping on success', () async {
      // Mock D-Bus property calls
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'PrettyHostname',
        ),
      ).thenAnswer((_) async => const DBusString('My Device'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'StaticHostname',
        ),
      ).thenAnswer((_) async => const DBusString('my-hostname'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'HardwareModel',
        ),
      ).thenAnswer((_) async => const DBusString('Test Model'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'HardwareVendor',
        ),
      ).thenAnswer((_) async => const DBusString('Test Vendor'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'OperatingSystemPrettyName',
        ),
      ).thenAnswer((_) async => const DBusString('Test OS'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'OperatingSystemSupportEnd',
        ),
      ).thenAnswer(
        (_) async => const DBusUint64(1767139200000000),
      ); // Timestamp in microseconds
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'KernelName'),
      ).thenAnswer((_) async => const DBusString('Linux'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'KernelRelease',
        ),
      ).thenAnswer((_) async => const DBusString('6.1.0'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'KernelVersion',
        ),
      ).thenAnswer((_) async => const DBusString('SMP Build'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'FirmwareVersion',
        ),
      ).thenAnswer((_) async => const DBusString('v1.2.3'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'FirmwareVendor',
        ),
      ).thenAnswer((_) async => const DBusString('Bios Inc'));
      when(
        () =>
            mockObject.getProperty('org.freedesktop.hostname1', 'FirmwareDate'),
      ).thenAnswer(
        (_) async => const DBusUint64(1735689600000000),
      ); // Timestamp in microseconds

      // Mock GetHardwareSerial method call
      final mockResponse = MockDBusMethodSuccessResponse();
      when(
        () => mockResponse.returnValues,
      ).thenReturn([const DBusString('SN12345')]);
      when(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'GetHardwareSerial',
          [],
        ),
      ).thenAnswer((_) async => mockResponse);

      // Mock MachineID and BootID (16 bytes arrays)
      final machineIdBytes = List.generate(
        16,
        (i) => DBusByte(i),
      ); // hex representation: 000102030405060708090a0b0c0d0e0f
      final bootIdBytes = List.generate(
        16,
        (i) => DBusByte(i + 16),
      ); // hex representation: 101112131415161718191a1b1c1d1e1f

      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'MachineID'),
      ).thenAnswer((_) async => DBusArray(DBusSignature.byte, machineIdBytes));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'BootID'),
      ).thenAnswer((_) async => DBusArray(DBusSignature.byte, bootIdBytes));

      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'HomeURL'),
      ).thenAnswer((_) async => const DBusString('https://os-z.org'));

      final details = await repository.getAboutDetails();

      expect(details.deviceName, 'My Device');
      expect(details.hostname, 'my-hostname');
      expect(details.model, 'Test Model');
      expect(details.manufacturer, 'Test Vendor');
      expect(details.operatingSystem, 'Test OS');
      expect(details.supportUntil, isNotEmpty);
      expect(details.kernel, 'Linux 6.1.0');
      expect(details.kernelBuild, 'SMP Build');
      expect(details.firmwareVersion, 'v1.2.3');
      expect(details.firmwareVendor, 'Bios Inc');
      expect(details.firmwareDate, isNotEmpty);
      expect(details.serialNumber, 'SN12345');
      expect(details.machineId, '000102030405060708090a0b0c0d0e0f');
      expect(details.bootId, '10111213-1415-1617-1819-1a1b1c1d1e1f');
      expect(details.osWebsite, 'https://os-z.org');
    });

    test('falls back to StaticHostname when PrettyHostname is empty', () async {
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'PrettyHostname',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'StaticHostname',
        ),
      ).thenAnswer((_) async => const DBusString('fallback-hostname'));

      // Stub remaining properties with empty/defaults to avoid exceptions
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'HardwareModel',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'HardwareVendor',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'OperatingSystemPrettyName',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'OperatingSystemSupportEnd',
        ),
      ).thenAnswer((_) async => const DBusUint64(0));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'KernelName'),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'KernelRelease',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'KernelVersion',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'FirmwareVersion',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'FirmwareVendor',
        ),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () =>
            mockObject.getProperty('org.freedesktop.hostname1', 'FirmwareDate'),
      ).thenAnswer((_) async => const DBusUint64(0));

      final mockResponse = MockDBusMethodSuccessResponse();
      when(() => mockResponse.returnValues).thenReturn([]);
      when(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'GetHardwareSerial',
          [],
        ),
      ).thenAnswer((_) async => mockResponse);

      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'MachineID'),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'BootID'),
      ).thenAnswer((_) async => const DBusString(''));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'HomeURL'),
      ).thenAnswer((_) async => const DBusString(''));

      final details = await repository.getAboutDetails();
      expect(details.deviceName, 'fallback-hostname');
    });

    test('recovers gracefully when some properties fail to load', () async {
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'PrettyHostname',
        ),
      ).thenAnswer((_) async => const DBusString('My Device'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'StaticHostname',
        ),
      ).thenAnswer((_) async => const DBusString('my-hostname'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'HardwareModel',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'HardwareVendor',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'OperatingSystemPrettyName',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'OperatingSystemSupportEnd',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'KernelName'),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'KernelRelease',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'KernelVersion',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'FirmwareVersion',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty(
          'org.freedesktop.hostname1',
          'FirmwareVendor',
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () =>
            mockObject.getProperty('org.freedesktop.hostname1', 'FirmwareDate'),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'GetHardwareSerial',
          [],
        ),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'MachineID'),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'BootID'),
      ).thenThrow(Exception('D-Bus failure'));
      when(
        () => mockObject.getProperty('org.freedesktop.hostname1', 'HomeURL'),
      ).thenThrow(Exception('D-Bus failure'));

      final details = await repository.getAboutDetails();
      expect(details.deviceName, 'My Device');
      expect(details.hostname, 'my-hostname');
      expect(details.model, '');
      expect(details.manufacturer, '');
      expect(details.operatingSystem, '');
      expect(details.supportUntil, '');
      expect(details.kernel, '');
      expect(details.kernelBuild, '');
      expect(details.firmwareVersion, '');
      expect(details.firmwareVendor, '');
      expect(details.firmwareDate, '');
      expect(details.serialNumber, isNull);
      expect(details.machineId, '');
      expect(details.bootId, '');
      expect(details.osWebsite, '');
    });

    test(
      'throws GetAboutDetailsException when outer call fails completely',
      () async {
        when(
          () => mockObject.getProperty(
            'org.freedesktop.hostname1',
            'PrettyHostname',
          ),
        ).thenThrow(Exception('D-Bus failure'));
        when(
          () => mockObject.getProperty(
            'org.freedesktop.hostname1',
            'StaticHostname',
          ),
        ).thenThrow(Exception('D-Bus failure'));

        expect(
          () => repository.getAboutDetails(),
          throwsA(isA<GetAboutDetailsException>()),
        );
      },
    );
  });

  group('updateDeviceName', () {
    test('calls SetPrettyHostname on success', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'SetPrettyHostname',
          any(),
        ),
      ).thenAnswer((_) async => mockResponse);

      await repository.updateDeviceName('  New Device Name  ');

      verify(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'SetPrettyHostname',
          [const DBusString('New Device Name'), const DBusBoolean(true)],
        ),
      ).called(1);
    });

    test('throws UpdateDeviceNameException on D-Bus failure', () async {
      when(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'SetPrettyHostname',
          any(),
        ),
      ).thenThrow(Exception('SetPrettyHostname failed'));

      expect(
        () => repository.updateDeviceName('New Name'),
        throwsA(isA<UpdateDeviceNameException>()),
      );
    });
  });

  group('updateHostname', () {
    test('calls SetStaticHostname on success', () async {
      final mockResponse = MockDBusMethodSuccessResponse();
      when(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'SetStaticHostname',
          any(),
        ),
      ).thenAnswer((_) async => mockResponse);

      await repository.updateHostname('  new-hostname  ');

      verify(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'SetStaticHostname',
          [const DBusString('new-hostname'), const DBusBoolean(true)],
        ),
      ).called(1);
    });

    test('throws UpdateHostnameException on D-Bus failure', () async {
      when(
        () => mockObject.callMethod(
          'org.freedesktop.hostname1',
          'SetStaticHostname',
          any(),
        ),
      ).thenThrow(Exception('SetStaticHostname failed'));

      expect(
        () => repository.updateHostname('new-hostname'),
        throwsA(isA<UpdateHostnameException>()),
      );
    });
  });
}
