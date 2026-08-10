import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/core/exceptions/about_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/about/data/models/about_details.dart';
import 'about_repository.dart';

class AboutRepositoryImpl implements AboutRepository {
  static const String _busName = 'org.freedesktop.hostname1';
  static const String _objectPath = '/org/freedesktop/hostname1';
  static const bool _interactive = true;

  final DBusClient? _injectClient;
  final DBusRemoteObject? _injectObject;

  AboutRepositoryImpl({DBusClient? client, DBusRemoteObject? object})
      : _injectClient = client,
        _injectObject = object;

  /// Retrieves device, OS, kernel, firmware, and system identification details from hostname1 D-Bus.
  @override
  Future<AboutDetails> getAboutDetails() async {
    final client = _injectClient ?? DBusClient.system();

    String deviceName = '';
    String hostname = '';
    String model = '';
    String manufacturer = '';
    String operatingSystem = '';
    String supportUntil = '';
    String kernel = '';
    String kernelBuild = '';
    String firmwareVersion = '';
    String firmwareVendor = '';
    String firmwareDate = '';
    String? serialNumber;
    String machineId = '';
    String bootId = '';
    String osWebsite = '';

    try {
      final object = _injectObject ??
          DBusRemoteObject(
            client,
            name: _busName,
            path: DBusObjectPath(_objectPath),
          );

      // Device name
      deviceName = await _getStringProperty(object, 'PrettyHostname');

      // Hostname
      hostname = await _getStringProperty(object, 'StaticHostname');

      // Fallback to hostname when PrettyHostname is not available.
      if (deviceName.isEmpty) {
        deviceName = hostname;
      }

      // If both are empty, the connection or service has failed.
      if (deviceName.isEmpty) {
        throw Exception('Failed to communicate with hostname1 D-Bus service');
      }

      // Model
      model = await _getStringProperty(object, 'HardwareModel');

      // Manufacturer
      manufacturer = await _getStringProperty(object, 'HardwareVendor');

      // Operating system
      operatingSystem = await _getStringProperty(
        object,
        'OperatingSystemPrettyName',
      );

      // Support until
      try {
        final value = await object.getProperty(
          _busName,
          'OperatingSystemSupportEnd',
        );

        supportUntil = _formatTimestamp(value);
      } catch (e, stackTrace) {
        AppLogger.e(
          'Failed to get OperatingSystemSupportEnd: $e',
          stack: stackTrace,
        );
      }

      // Kernel name + release
      try {
        final kernelName = await _getStringProperty(object, 'KernelName');

        final kernelRelease = await _getStringProperty(object, 'KernelRelease');

        if (kernelName.isNotEmpty && kernelRelease.isNotEmpty) {
          kernel = '$kernelName $kernelRelease';
        } else if (kernelName.isNotEmpty) {
          kernel = kernelName;
        } else {
          kernel = kernelRelease;
        }
      } catch (e, stackTrace) {
        AppLogger.e('Failed to get kernel information: $e', stack: stackTrace);
      }

      // Kernel build
      kernelBuild = await _getStringProperty(object, 'KernelVersion');

      // Firmware version
      firmwareVersion = await _getStringProperty(object, 'FirmwareVersion');

      // Firmware vendor
      firmwareVendor = await _getStringProperty(object, 'FirmwareVendor');

      // Firmware date
      try {
        final value = await object.getProperty(_busName, 'FirmwareDate');

        firmwareDate = _formatTimestamp(value);
      } catch (e, stackTrace) {
        AppLogger.e('Failed to get FirmwareDate: $e', stack: stackTrace);
      }

      // Serial number
      try {
        final response = await object.callMethod(
          _busName,
          'GetHardwareSerial',
          [],
        );

        if (response.returnValues.isNotEmpty &&
            response.returnValues.first is DBusString) {
          final value = (response.returnValues.first as DBusString).value;

          if (value.isNotEmpty) {
            serialNumber = value;
          }
        }
      } catch (e, stackTrace) {
        AppLogger.e('Failed to get GetHardwareSerial: $e', stack: stackTrace);
      }

      // Get the system machine ID and convert its byte array to hex.
      try {
        final value = await object.getProperty(_busName, 'MachineID');

        machineId = _formatMachineId(value);
      } catch (e, stackTrace) {
        AppLogger.e('Failed to get MachineID: $e', stack: stackTrace);
      }

      // Get the current boot ID and format it as a UUID.
      try {
        final value = await object.getProperty(_busName, 'BootID');

        bootId = _formatBootId(value);

        AppLogger.d('BootId: $bootId');
      } catch (e, stackTrace) {
        AppLogger.e('Failed to get BootID: $e', stack: stackTrace);
      }

      // Get the operating system website URL.
      osWebsite = await _getStringProperty(object, 'HomeURL');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error connecting to hostname1 D-Bus service: $e',
        stack: stackTrace,
      );
      throw const GetAboutDetailsException();
    } finally {
      // Close the client only when it was created by this repository.
      if (_injectClient == null) {
        await client.close();
      }
    }

    return AboutDetails(
      deviceName: deviceName,
      hostname: hostname,
      model: model,
      manufacturer: manufacturer,
      operatingSystem: operatingSystem,
      supportUntil: supportUntil,
      kernel: kernel,
      kernelBuild: kernelBuild,
      firmwareVersion: firmwareVersion,
      firmwareVendor: firmwareVendor,
      firmwareDate: firmwareDate,
      serialNumber: serialNumber,
      machineId: machineId,
      bootId: bootId,
      osWebsite: osWebsite,
    );
  }

  /// Reads a string property from hostname1 and returns an empty value on failure.
  Future<String> _getStringProperty(
    DBusRemoteObject object,
    String property,
  ) async {
    try {
      final value = await object.getProperty(_busName, property);

      if (value is DBusString && value.value.isNotEmpty) {
        return value.value;
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get $property: $e', stack: stackTrace);
    }

    return '';
  }

  /// Converts the machine ID byte array into a hexadecimal string.
  String _formatMachineId(DBusValue value) {
    if (value is! DBusArray) {
      return '';
    }

    final bytes = value.children
        .whereType<DBusByte>()
        .map((byte) => byte.value)
        .toList();

    if (bytes.length != 16) {
      return '';
    }

    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Converts a systemd microsecond timestamp into a local date.
  String _formatTimestamp(DBusValue value) {
    int? microseconds;

    if (value is DBusUint64) {
      microseconds = value.value;
    } else if (value is DBusInt64) {
      microseconds = value.value;
    }

    // Zero and UINT64_MAX indicate an unknown or unavailable timestamp.
    if (microseconds == null ||
        microseconds == 0 ||
        microseconds == 0xFFFFFFFFFFFFFFFF) {
      return '';
    }

    try {
      final dateTime = DateTime.fromMicrosecondsSinceEpoch(
        microseconds,
        isUtc: true,
      ).toLocal();

      return '${dateTime.year.toString().padLeft(4, '0')}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      AppLogger.e('Failed to format timestamp: $e');
      return '';
    }
  }

  /// Converts the 16-byte boot ID into standard UUID format.
  String _formatBootId(DBusValue value) {
    if (value is! DBusArray) {
      return '';
    }

    final bytes = value.children
        .whereType<DBusByte>()
        .map((byte) => byte.value)
        .toList();

    if (bytes.length != 16) {
      return '';
    }

    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .toList();

    return '${hex.sublist(0, 4).join()}'
        '-${hex.sublist(4, 6).join()}'
        '-${hex.sublist(6, 8).join()}'
        '-${hex.sublist(8, 10).join()}'
        '-${hex.sublist(10, 16).join()}';
  }

  /// Updates the user-visible device name (PrettyHostname) through hostname1 D-Bus.
  @override
  Future<void> updateDeviceName(String name) async {
    final trimmedName = name.trim();
    final client = _injectClient ?? DBusClient.system();

    try {
      final object = _injectObject ??
          DBusRemoteObject(
            client,
            name: _busName,
            path: DBusObjectPath(_objectPath),
          );

      await object.callMethod(_busName, 'SetPrettyHostname', [
        DBusString(trimmedName),
        const DBusBoolean(_interactive),
      ]);

      AppLogger.d('SetPrettyHostname updated: $trimmedName');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update device name', error: e, stack: stackTrace);

      throw const UpdateDeviceNameException();
    } finally {
      if (_injectClient == null) {
        await client.close();
      }
    }
  }

  /// Updates the system hostname (StaticHostname) through hostname1 D-Bus.
  @override
  Future<void> updateHostname(String name) async {
    final trimmedName = name.trim();
    final client = _injectClient ?? DBusClient.system();

    try {
      final object = _injectObject ??
          DBusRemoteObject(
            client,
            name: _busName,
            path: DBusObjectPath(_objectPath),
          );

      await object.callMethod(_busName, 'SetStaticHostname', [
        DBusString(trimmedName),
        const DBusBoolean(_interactive),
      ]);

      AppLogger.d('SetStaticHostname updated: $trimmedName');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to update hostname', error: e, stack: stackTrace);

      throw const UpdateHostnameException();
    } finally {
      if (_injectClient == null) {
        await client.close();
      }
    }
  }
}
