enum PowerProfileMode { balanced, powerSaver, performance }

extension PowerProfileModeExtension on PowerProfileMode {
  String get value {
    switch (this) {
      case PowerProfileMode.balanced:
        return 'balanced';
      case PowerProfileMode.powerSaver:
        return 'power-saver';
      case PowerProfileMode.performance:
        return 'performance';
    }
  }

  static PowerProfileMode fromValue(String value) {
    switch (value) {
      case 'power-saver':
        return PowerProfileMode.powerSaver;
      case 'performance':
        return PowerProfileMode.performance;
      case 'balanced':
      default:
        return PowerProfileMode.balanced;
    }
  }
}

enum BatteryStatus { initial, loading, loaded, error }

enum BatteryError {
  initializationFailed,
  batteryInfoLoadFailed,
  batteryModeUpdateFailed,
  batteryModeLoadFailed,
  batteryModesLoadFailed,
  batteryEventsInitializationFailed,
  unknown,
}
