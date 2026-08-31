enum DisplayStatus { initial, loading, loaded, error }

enum DisplayError {
  initializationFailed,
  getBrightnessFailed,
  setBrightnessFailed,
  getAutoBrightnessFailed,
  setAutoBrightnessFailed,
  getScreenTimeoutFailed,
  setScreenTimeoutFailed,
  unknown,
}
