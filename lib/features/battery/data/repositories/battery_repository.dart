import 'package:mechanix_settings/features/battery/data/models/battery_info.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';

abstract class BatteryRepository {
  Future<void> init();

  Future<BatteryInfo> getBatteryInfo();

  Future<PowerProfileMode> setBatteryMode(PowerProfileMode mode);

  Future<Stream<List<String>>?> streamBatteryEvents();

  Future<void> close();
}
