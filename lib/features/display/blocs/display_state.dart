import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/display/data/models/display_enums.dart';

class DisplayState extends Equatable {
  final double brightness;
  final bool isAutoBrightness;
  final int screenTimeout;
  final DisplayStatus status;
  final DisplayError? error;

  const DisplayState({
    this.brightness = 0.5,
    this.isAutoBrightness = true,
    this.screenTimeout = 30,
    this.status = DisplayStatus.initial,
    this.error,
  });

  DisplayState copyWith({
    double? brightness,
    bool? isAutoBrightness,
    int? screenTimeout,
    DisplayStatus? status,
    DisplayError? error,
  }) {
    return DisplayState(
      brightness: brightness ?? this.brightness,
      isAutoBrightness: isAutoBrightness ?? this.isAutoBrightness,
      screenTimeout: screenTimeout ?? this.screenTimeout,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        brightness,
        isAutoBrightness,
        screenTimeout,
        status,
        error,
      ];
}
