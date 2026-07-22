import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';

class BluetoothState extends Equatable {
  static const _unset = Object();

  final bool isBluetoothOn;
  final bool isScanning;
  final List<BluetoothDevice> pairedDevices;
  final List<BluetoothDevice> discoveredDevices;

  /// Devices currently trying to connect
  final Set<String> connectingDevices;

  final String? connectedDeviceName;
  final String localDeviceName;

  const BluetoothState({
    this.isBluetoothOn = false,
    this.isScanning = false,
    this.pairedDevices = const [],
    this.discoveredDevices = const [],
    this.connectingDevices = const {},
    this.connectedDeviceName,
    this.localDeviceName = '',
  });

  BluetoothState copyWith({
    bool? isBluetoothOn,
    bool? isScanning,
    List<BluetoothDevice>? pairedDevices,
    List<BluetoothDevice>? discoveredDevices,
    Set<String>? connectingDevices,
    Object? connectedDeviceName = _unset,
    String? localDeviceName,
  }) {
    return BluetoothState(
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      isScanning: isScanning ?? this.isScanning,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectingDevices: connectingDevices ?? this.connectingDevices,
      connectedDeviceName: connectedDeviceName == _unset
          ? this.connectedDeviceName
          : connectedDeviceName as String?,
      localDeviceName: localDeviceName ?? this.localDeviceName,
    );
  }

  @override
  List<Object?> get props => [
    isBluetoothOn,
    isScanning,
    pairedDevices,
    discoveredDevices,
    connectingDevices,
    connectedDeviceName,
    localDeviceName,
  ];
}
