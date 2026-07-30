import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';

abstract class BatteryEvent extends Equatable {
  const BatteryEvent();

  @override
  List<Object?> get props => [];
}

class BatteryInit extends BatteryEvent {
  const BatteryInit();
}

class BatteryInfoRequested extends BatteryEvent {
  const BatteryInfoRequested();
}

class SetBatteryMode extends BatteryEvent {
  final PowerProfileMode mode;
  const SetBatteryMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

class ToggleBatterySaver extends BatteryEvent {
  final bool enable;
  const ToggleBatterySaver(this.enable);

  @override
  List<Object?> get props => [enable];
}
