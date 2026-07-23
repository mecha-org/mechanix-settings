import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';

abstract class BluetoothEvent extends Equatable {
  const BluetoothEvent();

  @override
  List<Object?> get props => [];
}

class LoadBluetooth extends BluetoothEvent {
  const LoadBluetooth();
}

class ToggleBluetoothPower extends BluetoothEvent {
  final bool isEnabled;
  const ToggleBluetoothPower(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

class ScanBluetoothDevices extends BluetoothEvent {
  const ScanBluetoothDevices();
}

class ConnectToDeviceEvent extends BluetoothEvent {
  final BluetoothDevice device;
  const ConnectToDeviceEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class DisconnectFromDeviceEvent extends BluetoothEvent {
  final BluetoothDevice device;
  const DisconnectFromDeviceEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class ForgetDeviceEvent extends BluetoothEvent {
  final BluetoothDevice device;
  const ForgetDeviceEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class ShowPairingInputEvent extends BluetoothEvent {
  final BluetoothDevice device;
  const ShowPairingInputEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class ShowPairingCodeEvent extends BluetoothEvent {
  final BluetoothDevice device;
  const ShowPairingCodeEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class CancelPairingEvent extends BluetoothEvent {
  final BluetoothDevice device;

  const CancelPairingEvent(this.device);
}

class CompletePairingEvent extends BluetoothEvent {
  final BluetoothDevice device;
  const CompletePairingEvent(this.device);

  @override
  List<Object?> get props => [device];
}

class RenameLocalDeviceEvent extends BluetoothEvent {
  final String name;
  const RenameLocalDeviceEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class BluetoothPowerChanged extends BluetoothEvent {
  final bool isOn;
  const BluetoothPowerChanged(this.isOn);

  @override
  List<Object?> get props => [isOn];
}

class BluetoothScanningChanged extends BluetoothEvent {
  final bool isScanning;
  const BluetoothScanningChanged(this.isScanning);

  @override
  List<Object?> get props => [isScanning];
}

class BluetoothDevicesUpdated extends BluetoothEvent {
  final List<BluetoothDevice> devices;
  const BluetoothDevicesUpdated(this.devices);

  @override
  List<Object?> get props => [devices];
}

class ToggleBluetoothDiscoverable extends BluetoothEvent {
  final bool isDiscoverable;
  const ToggleBluetoothDiscoverable(this.isDiscoverable);

  @override
  List<Object?> get props => [isDiscoverable];
}

class BluetoothDiscoverableChanged extends BluetoothEvent {
  final bool isDiscoverable;
  const BluetoothDiscoverableChanged(this.isDiscoverable);

  @override
  List<Object?> get props => [isDiscoverable];
}

class RefreshDeviceList extends BluetoothEvent {}
