import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/bluetooth/data/models/enums.dart';

class BluetoothDevice extends Equatable {
  final String name;
  final String deviceName;
  final BluetoothDeviceType type;
  final bool isConnected;
  final bool isConnecting;
  final bool isSaved;
  final String macAddress;

  const BluetoothDevice({
    required this.name,
    required this.deviceName,
    required this.type,
    this.isConnected = false,
    this.isConnecting = false,
    this.isSaved = false,
    this.macAddress = '00:11:22:33:44:55',
  });

  BluetoothDevice copyWith({
    String? name,
    String? deviceName,
    BluetoothDeviceType? type,
    bool? isConnected,
    bool? isConnecting,
    bool? isSaved,
    String? macAddress,
  }) {
    return BluetoothDevice(
      name: name ?? this.name,
      deviceName: deviceName ?? this.deviceName,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isSaved: isSaved ?? this.isSaved,
      macAddress: macAddress ?? this.macAddress,
    );
  }

  @override
  List<Object?> get props => [
    name,
    deviceName,
    type,
    isConnected,
    isConnecting,
    isSaved,
    macAddress,
  ];
}
