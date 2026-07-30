import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:upower/upower.dart';

class BatteryInfo {
  final double batteryPercentage;
  final UPowerDeviceState status;
  final PowerProfileMode mode;
  final int batteryRemainingTime;
  final int batteryChargingTime;
  final List<String> availableBatteryModes;

  const BatteryInfo({
    required this.batteryPercentage,
    required this.status,
    required this.mode,
    required this.batteryChargingTime,
    required this.batteryRemainingTime,
    required this.availableBatteryModes,
  });
}
