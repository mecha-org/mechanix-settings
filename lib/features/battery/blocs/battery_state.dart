import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:upower/upower.dart';

class BatteryState extends Equatable {
  final double batteryPercentage;
  final UPowerDeviceState batteryStatus;
  final int? batteryChargingTime;
  final int? batteryRemainingTime;
  final PowerProfileMode? performanceMode;
  final List<String> availableBatteryModes;
  final BatteryStatus status;
  final BatteryError? error;

  const BatteryState({
    this.status = BatteryStatus.initial,
    this.batteryPercentage = 0.0,
    this.batteryStatus = UPowerDeviceState.unknown,
    this.batteryChargingTime = 0,
    this.batteryRemainingTime = 0,
    this.performanceMode = PowerProfileMode.balanced,
    this.availableBatteryModes = const [],
    this.error,
  });

  BatteryState copyWith({
    BatteryStatus? status,
    double? batteryPercentage,
    UPowerDeviceState? batteryStatus,
    int? batteryChargingTime,
    int? batteryRemainingTime,
    PowerProfileMode? performanceMode,
    List<String>? availableBatteryModes,
    BatteryError? error,
  }) {
    return BatteryState(
      status: status ?? this.status,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      batteryChargingTime: batteryChargingTime ?? this.batteryChargingTime,
      batteryRemainingTime: batteryRemainingTime ?? this.batteryRemainingTime,
      performanceMode: performanceMode ?? this.performanceMode,
      availableBatteryModes:
          availableBatteryModes ?? this.availableBatteryModes,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    batteryPercentage,
    batteryStatus,
    batteryChargingTime,
    batteryRemainingTime,
    performanceMode,
    availableBatteryModes,
    error,
  ];
}
