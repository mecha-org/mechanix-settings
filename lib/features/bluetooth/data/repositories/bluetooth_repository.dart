import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';

abstract class BluetoothRepository {
  Stream<bool> get powerStream;

  Stream<bool> get discoverableStream;

  Stream<bool> get scanningStream;

  Stream<List<BluetoothDevice>> get devicesStream;

  Future<void> init();

  Future<bool> isBluetoothEnabled();

  Future<bool> isDiscoverable();

  Future<bool> togglePower(bool enable);

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<List<BluetoothDevice>> getPairedDevices();

  Future<void> pairDevice(String addressOrName);

  Future<void> connectToDevice(String addressOrName);

  Future<void> disconnectFromDevice(String addressOrName);

  Future<void> forgetDevice(String addressOrName);

  Future<String> getLocalDeviceName();

  Future<void> updateLocalDeviceName(String name);

  Future<void> setDiscoverable(bool discoverable);

  Future<void> close();
}
