import 'package:equatable/equatable.dart';

abstract class DisplayEvent extends Equatable {
  const DisplayEvent();

  @override
  List<Object?> get props => [];
}

class DisplayInit extends DisplayEvent {
  const DisplayInit();
}

class LoadDisplaySettings extends DisplayEvent {
  const LoadDisplaySettings();
}

class SetBrightness extends DisplayEvent {
  final double brightness;

  const SetBrightness(this.brightness);

  @override
  List<Object?> get props => [brightness];
}

class SetAutoBrightness extends DisplayEvent {
  final bool enabled;

  const SetAutoBrightness(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetScreenTimeout extends DisplayEvent {
  final int timeoutSeconds;

  const SetScreenTimeout(this.timeoutSeconds);

  @override
  List<Object?> get props => [timeoutSeconds];
}
