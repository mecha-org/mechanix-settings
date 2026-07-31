import 'dart:async';

import 'package:bluez/bluez.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';
import 'package:mechanix_settings/features/bluetooth/data/repositories/bluetooth_repository.dart';

class BluetoothRepositoryImpl implements BluetoothRepository {
  final BlueZClient? _injectedClient;
  late BlueZClient _client;
  BlueZAdapter? _adapter;
  bool _connected = false;

  BluetoothRepositoryImpl({BlueZClient? client}) : _injectedClient = client;

  final _powerController = StreamController<bool>.broadcast();
  final _discoverableController = StreamController<bool>.broadcast();
  final _scanningController = StreamController<bool>.broadcast();
  final _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();

  StreamSubscription<List<String>>? _adapterPropsSub;
  StreamSubscription<BlueZDevice>? _deviceAddedSub;
  StreamSubscription<BlueZDevice>? _deviceRemovedSub;
  final Map<String, StreamSubscription> _devicePropSubs = {};

  @override
  Stream<bool> get powerStream => _powerController.stream;

  @override
  Stream<bool> get discoverableStream => _discoverableController.stream;

  @override
  Stream<bool> get scanningStream => _scanningController.stream;

  @override
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;

  @override
  Future<void> init() async {
    await _ensureConnected();
  }

  Future<void> _ensureConnected() async {
    if (_connected) return;

    try {
      _client = _injectedClient ?? BlueZClient();
      if (_injectedClient == null) {
        await _client.connect();
      }
      _connected = true;

      if (_client.adapters.isEmpty) {
        AppLogger.i('No Bluetooth adapter found');
        return;
      }

      _adapter = _client.adapters.first;

      _setupAdapterListeners();
      _setupClientListeners();

      await _emitDevices();
    } catch (e, stackTrace) {
      AppLogger.e(
        'Failed to initialize Bluetooth repository: $e',
        stack: stackTrace,
      );
    }
  }

  void _setupAdapterListeners() {
    _adapterPropsSub?.cancel();

    final adapter = _adapter;
    if (adapter == null) return;

    _powerController.add(adapter.powered);
    _discoverableController.add(adapter.discoverable);
    _scanningController.add(adapter.discovering);

    _adapterPropsSub = adapter.propertiesChanged.listen((props) {
      if (props.contains('Powered')) {
        final powered = adapter.powered;

        AppLogger.i('Bluetooth power changed: $powered');

        _powerController.add(powered);

        if (powered) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _setupClientListeners();
            _emitDevices();
          });
        } else {
          _devicesController.add([]);
          _scanningController.add(false);
        }
      }

      if (props.contains('Discoverable')) {
        _discoverableController.add(adapter.discoverable);
      }

      if (props.contains('Discovering')) {
        _scanningController.add(adapter.discovering);
      }
    });
  }

  void _setupClientListeners() {
    _deviceAddedSub?.cancel();
    _deviceAddedSub = _client.deviceAdded.listen((device) {
      _subscribeToDeviceProps(device);
      _emitDevices();
    });

    _deviceRemovedSub?.cancel();
    _deviceRemovedSub = _client.deviceRemoved.listen((device) {
      _devicePropSubs[device.address]?.cancel();
      _devicePropSubs.remove(device.address);
      _emitDevices();
    });

    for (final device in _client.devices) {
      _subscribeToDeviceProps(device);
    }
  }

  void _subscribeToDeviceProps(BlueZDevice device) {
    if (_devicePropSubs.containsKey(device.address)) {
      return;
    }

    _devicePropSubs[device.address] = device.propertiesChanged.listen((_) {
      _emitDevices();
    });
  }

  Future<void> _emitDevices() async {
    final devices = await _getDevicesList();
    _devicesController.add(devices);
  }

  Future<List<BluetoothDevice>> _getDevicesList() async {
    if (!_connected) {
      return [];
    }

    final devices = <BluetoothDevice>[];
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');

    for (final device in _client.devices) {
      final mapped = _mapToBluetoothDevice(device);

      // Ignore anonymous scanned devices that only expose MAC address.
      if (!mapped.isSaved && macRegex.hasMatch(mapped.name)) {
        continue;
      }

      devices.add(mapped);
    }

    return devices;
  }

  BluetoothDevice _mapToBluetoothDevice(BlueZDevice device) {
    final name = device.name.isNotEmpty
        ? device.name
        : device.alias.isNotEmpty
        ? device.alias
        : device.address;

    final deviceName = name;

    final majorClass = (device.deviceClass >> 8) & 0x1F;
    final minorClass = (device.deviceClass >> 2) & 0x3F;

    final uuids = device.uuids
        .map((uuid) => uuid.toString().toLowerCase())
        .toList();

    // Common Bluetooth service UUIDs
    final hasAudioSink = uuids.any((u) => u.contains('110b'));
    final hasAudioSource = uuids.any((u) => u.contains('110a'));
    final hasHeadset = uuids.any((u) => u.contains('1108'));
    final hasHandsFree = uuids.any((u) => u.contains('111e'));
    final hasAvRemote = uuids.any((u) => u.contains('110e'));
    final hasPnP = uuids.any((u) => u.contains('1200'));

    BluetoothDeviceType type = BluetoothDeviceType.unknown;

    switch (majorClass) {
      // Computer
      case 0x01:
        type = BluetoothDeviceType.computer;
        break;

      // Phone
      case 0x02:
        type = BluetoothDeviceType.mobile;
        break;

      // Audio / Video
      case 0x04: // Audio / Video
        // Prefer advertised audio services because many Bluetooth
        // speakers report an incorrect device class.
        if (hasAudioSink) {
          type = BluetoothDeviceType.speaker;
          break;
        }

        switch (minorClass) {
          case 0x08:
            type = BluetoothDeviceType.car;
            break;

          case 0x04:
            type = BluetoothDeviceType.tv;
            break;

          case 0x05:
          case 0x0A:
            type = BluetoothDeviceType.speaker;
            break;

          case 0x01:
          case 0x02:
          case 0x06:
            type = BluetoothDeviceType.headphones;
            break;

          default:
            if (hasHeadset || hasHandsFree) {
              type = BluetoothDeviceType.headphones;
            } else if (hasAudioSource || hasAvRemote) {
              type = BluetoothDeviceType.speaker;
            }
        }
        break;

      default:
        // Fallback using advertised services.
        if (hasHeadset || hasHandsFree) {
          type = BluetoothDeviceType.headphones;
        } else if (hasAudioSink || hasAudioSource || hasAvRemote) {
          type = BluetoothDeviceType.speaker;
        } else if (hasPnP) {
          type = BluetoothDeviceType.computer;
        } else {
          type = BluetoothDeviceType.unknown;
        }
    }

    return BluetoothDevice(
      name: name,
      deviceName: deviceName,
      type: type,
      isConnected: device.connected,
      isSaved: device.paired,
      macAddress: device.address,
    );
  }

  @override
  Future<List<BluetoothDevice>> getPairedDevices() async {
    await _ensureConnected();
    final devices = await _getDevicesList();
    return devices.where((device) => device.isSaved).toList();
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    final adapter = await getBluezAdapter();
    return adapter?.powered ?? false;
  }

  @override
  Future<bool> isDiscoverable() async {
    final adapter = await getBluezAdapter();
    return adapter?.discoverable ?? false;
  }

  @override
  Future<bool> togglePower(bool enable) async {
    final adapter = await getBluezAdapter();

    if (adapter == null) {
      AppLogger.e('Bluetooth adapter not found');
      return false;
    }

    AppLogger.i(
      'Adapter state: '
      'powered=${adapter.powered}, '
      'discovering=${adapter.discovering}',
    );

    if (adapter.powered == enable) {
      return true;
    }

    try {
      await adapter.setPowered(enable);

      // Wait for BlueZ to update the property.
      await Future.delayed(const Duration(milliseconds: 300));

      AppLogger.i('Bluetooth power updated. powered=${adapter.powered}');

      return adapter.powered == enable;
    } catch (e, stack) {
      AppLogger.e('Failed to toggle bluetooth power: $e', stack: stack);
      return false;
    }
  }

  Future<BlueZAdapter?> getBluezAdapter() async {
    await _ensureConnected();
    return _adapter;
  }

  @override
  Future<void> startDiscovery() async {
    try {
      final adapter = await getBluezAdapter();

      if (adapter == null) {
        AppLogger.e('Bluetooth adapter not found');
        return;
      }

      if (!adapter.powered) {
        return;
      }

      if (adapter.discovering) {
        _scanningController.add(true);
        return;
      }

      await adapter.startDiscovery();

      _scanningController.add(true);
    } catch (e, stack) {
      AppLogger.e('Failed to start bluetooth discovery: $e', stack: stack);
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      final adapter = await getBluezAdapter();

      if (adapter == null) {
        return;
      }

      try {
        await adapter.stopDiscovery();
      } catch (e) {
        // Ignore BlueZ race condition.
        if (e.toString().contains('No discovery started')) {
          AppLogger.i('Discovery already stopped');
        } else {
          rethrow;
        }
      }

      _scanningController.add(false);
    } catch (e, stack) {
      AppLogger.e('Failed to stop bluetooth discovery: $e', stack: stack);
    }
  }

  @override
  Future<void> pairDevice(String addressOrName) async {
    try {
      await _ensureConnected();

      final device = _findDevice(addressOrName);

      if (device == null) {
        throw Exception('Device not found: $addressOrName');
      }

      AppLogger.i(
        'Pairing with ${device.alias.isNotEmpty ? device.alias : device.address}',
      );

      await device.pair();

      AppLogger.i('Pair request completed for ${device.address}');
    } catch (e, stack) {
      AppLogger.e('Failed to pair bluetooth device: $e', stack: stack);
      rethrow;
    }
  }

  @override
  Future<void> connectToDevice(String addressOrName) async {
    try {
      await _ensureConnected();

      final device = _findDevice(addressOrName);

      if (device == null) {
        throw Exception('Device not found: $addressOrName');
      }

      AppLogger.i(
        'Connecting to ${device.alias.isNotEmpty ? device.alias : device.address}',
      );

      await device.connect();

      AppLogger.i('Connect request completed for ${device.address}');
    } catch (e, stack) {
      AppLogger.e('Failed to connect bluetooth device: $e', stack: stack);
      rethrow;
    }
  }

  @override
  Future<void> disconnectFromDevice(String addressOrName) async {
    try {
      await _ensureConnected();

      final device = _findDevice(addressOrName);

      if (device == null) {
        AppLogger.e('Disconnect failed. Device not found: $addressOrName');
        return;
      }

      await device.disconnect();

      AppLogger.i(
        'Disconnect request completed for ${device.alias.isNotEmpty ? device.alias : device.address}',
      );
    } catch (e, stack) {
      AppLogger.e('Failed to disconnect bluetooth device: $e', stack: stack);
    }
  }

  @override
  Future<void> forgetDevice(String addressOrName) async {
    try {
      await _ensureConnected();

      final device = _findDevice(addressOrName);

      if (device == null) {
        AppLogger.e('Forget failed. Device not found: $addressOrName');
        return;
      }

      if (_adapter == null) {
        AppLogger.e('Bluetooth adapter not available');
        return;
      }

      // Disconnect before removing device
      if (device.connected) {
        await device.disconnect();

        await Future.delayed(const Duration(milliseconds: 500));
      }

      await _adapter!.removeDevice(device);

      AppLogger.i('Forgot bluetooth device: ${device.address}');
    } catch (e, stack) {
      AppLogger.e('Failed to forget bluetooth device: $e', stack: stack);
    }
  }

  @override
  Future<String> getLocalDeviceName() async {
    await _ensureConnected();

    final alias = _adapter?.alias;
    final name = _adapter?.name;
    final displayName = (alias != null && alias.isNotEmpty)
        ? alias
        : (name != null && name.isNotEmpty)
            ? name
            : 'comet';

    AppLogger.i('Local bluetooth device name: $displayName');

    return displayName;
  }

  @override
  Future<void> updateLocalDeviceName(String name) async {
    try {
      await _ensureConnected();

      if (_adapter == null) {
        AppLogger.e('Bluetooth adapter not available');
        return;
      }

      await _adapter!.setAlias(name);

      AppLogger.i('Updated local bluetooth device name to "$name"');
    } catch (e, stack) {
      AppLogger.e('Failed to update bluetooth device name: $e', stack: stack);
    }
  }

  @override
  Future<void> setDiscoverable(bool discoverable) async {
    try {
      await _ensureConnected();

      if (_adapter == null) {
        AppLogger.e('Bluetooth adapter not available');
        return;
      }

      await _adapter!.setDiscoverable(discoverable);

      AppLogger.i('Bluetooth discoverable set to $discoverable');
    } catch (e, stack) {
      AppLogger.e('Failed to set bluetooth discoverable: $e', stack: stack);
    }
  }

  BlueZDevice? _findDevice(String addressOrName) {
    try {
      return _client.devices.firstWhere(
        (device) =>
            device.address == addressOrName ||
            device.name == addressOrName ||
            device.alias == addressOrName,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _adapterPropsSub?.cancel();
    await _deviceAddedSub?.cancel();
    await _deviceRemovedSub?.cancel();

    for (final subscription in _devicePropSubs.values) {
      await subscription.cancel();
    }

    _devicePropSubs.clear();

    await _powerController.close();
    await _discoverableController.close();
    await _scanningController.close();
    await _devicesController.close();

    if (_connected) {
      await _client.close();
    }

    _connected = false;
    _adapter = null;
  }
}
