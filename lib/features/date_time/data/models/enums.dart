enum DateTimeStatus { initial, loading, loaded, error }

enum DateTimeError {
  initializationFailed,
  timeUpdateFailed,
  timezoneUpdateFailed,
  ntpUpdateFailed,
  timeFormatUpdateFailed,
  timeLoadFailed,
  timezoneLoadFailed,
  ntpLoadFailed,
  timeFormatLoadFailed,
  unknown,
}
