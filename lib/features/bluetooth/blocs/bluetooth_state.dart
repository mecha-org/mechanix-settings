import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/bluetooth_device.dart';

enum BluetoothErrorType {
  connectionFailed,
  pairingFailed,
  unknown,
}

class BluetoothFailure extends Equatable {
  final BluetoothErrorType type;
  final String? message;
  final Map<String, dynamic>? data;

  const BluetoothFailure({required this.type, this.message, this.data});

  @override
  List<Object?> get props => [type, message, data];
}

class BluetoothState extends Equatable {
  static const _unset = Object();

  final bool isBluetoothOn;
  final bool isScanning;
  final bool isDiscoverable;
  final List<BluetoothDevice> pairedDevices;
  final List<BluetoothDevice> discoveredDevices;

  /// Devices currently trying to connect
  final Set<String> connectingDevices;

  final String? connectedDeviceName;
  final String localDeviceName;
  final BluetoothFailure? error;

  const BluetoothState({
    this.isBluetoothOn = false,
    this.isScanning = false,
    this.isDiscoverable = false,
    this.pairedDevices = const [],
    this.discoveredDevices = const [],
    this.connectingDevices = const {},
    this.connectedDeviceName,
    this.localDeviceName = '',
    this.error,
  });

  BluetoothState copyWith({
    bool? isBluetoothOn,
    bool? isScanning,
    bool? isDiscoverable,
    List<BluetoothDevice>? pairedDevices,
    List<BluetoothDevice>? discoveredDevices,
    Set<String>? connectingDevices,
    Object? connectedDeviceName = _unset,
    String? localDeviceName,
    Object? error = _unset,
  }) {
    return BluetoothState(
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      isScanning: isScanning ?? this.isScanning,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      pairedDevices: pairedDevices ?? this.pairedDevices,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectingDevices: connectingDevices ?? this.connectingDevices,
      connectedDeviceName: connectedDeviceName == _unset
          ? this.connectedDeviceName
          : connectedDeviceName as String?,
      localDeviceName: localDeviceName ?? this.localDeviceName,
      error: error == _unset ? this.error : error as BluetoothFailure?,
    );
  }

  @override
  List<Object?> get props => [
    isBluetoothOn,
    isScanning,
    isDiscoverable,
    pairedDevices,
    discoveredDevices,
    connectingDevices,
    connectedDeviceName,
    localDeviceName,
    error,
  ];
}
