import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';

class BluetoothState extends Equatable {
  static const _unset = Object();

  final bool isBluetoothOn;
  final bool isScanning;
  final List<BluetoothDevice> pairedDevices;
  final List<BluetoothDevice> discoveredDevices;
  final String? connectingDeviceName;
  final String? connectedDeviceName;
  final BluetoothDevice? pairingRequestDevice;
  final BluetoothDevice? pairingCodeDisplayDevice;
  final String localDeviceName;

  const BluetoothState({
    this.isBluetoothOn = false,
    this.isScanning = false,
    this.pairedDevices = const [],
    this.discoveredDevices = const [],
    this.connectingDeviceName,
    this.connectedDeviceName,
    this.pairingRequestDevice,
    this.pairingCodeDisplayDevice,
    this.localDeviceName = 'comet',
  });

  BluetoothState copyWith({
    bool? isBluetoothOn,
    bool? isScanning,
    List<BluetoothDevice>? pairedDevices,
    List<BluetoothDevice>? discoveredDevices,
    Object? connectingDeviceName = _unset,
    Object? connectedDeviceName = _unset,
    Object? pairingRequestDevice = _unset,
    Object? pairingCodeDisplayDevice = _unset,
    String? localDeviceName,
  }) {
    return BluetoothState(
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      isScanning: isScanning ?? this.isScanning,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectingDeviceName: connectingDeviceName == _unset
          ? this.connectingDeviceName
          : connectingDeviceName as String?,
      connectedDeviceName: connectedDeviceName == _unset
          ? this.connectedDeviceName
          : connectedDeviceName as String?,
      pairingRequestDevice: pairingRequestDevice == _unset
          ? this.pairingRequestDevice
          : pairingRequestDevice as BluetoothDevice?,
      pairingCodeDisplayDevice: pairingCodeDisplayDevice == _unset
          ? this.pairingCodeDisplayDevice
          : pairingCodeDisplayDevice as BluetoothDevice?,
      localDeviceName: localDeviceName ?? this.localDeviceName,
    );
  }

  @override
  List<Object?> get props => [
    isBluetoothOn,
    isScanning,
    pairedDevices,
    discoveredDevices,
    connectingDeviceName,
    connectedDeviceName,
    pairingRequestDevice,
    pairingCodeDisplayDevice,
    localDeviceName,
  ];
}
