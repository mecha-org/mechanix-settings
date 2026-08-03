abstract class BatteryException implements Exception {
  final String message;

  const BatteryException(this.message);

  @override
  String toString() => message;
}

class BatteryInitializationException extends BatteryException {
  const BatteryInitializationException([
    super.message = 'Failed to initialize battery service.',
  ]);
}

class BatteryConnectionException extends BatteryException {
  const BatteryConnectionException([
    super.message = 'Failed to connect to the battery service.',
  ]);
}

class GetBatteryInfoException extends BatteryException {
  const GetBatteryInfoException([
    super.message = 'Failed to retrieve battery information.',
  ]);
}

class GetBatteryModeException extends BatteryException {
  const GetBatteryModeException([
    super.message = 'Failed to retrieve power profile.',
  ]);
}

class SetBatteryModeException extends BatteryException {
  const SetBatteryModeException([
    super.message = 'Failed to update power profile.',
  ]);
}

class GetAvailableBatteryModesException extends BatteryException {
  const GetAvailableBatteryModesException([
    super.message = 'Failed to retrieve available power profiles.',
  ]);
}

class BatteryEventStreamException extends BatteryException {
  const BatteryEventStreamException([
    super.message = 'Failed to initialize battery event stream.',
  ]);
}

class BatteryCloseException extends BatteryException {
  const BatteryCloseException([
    super.message = 'Failed to close battery service.',
  ]);
}
