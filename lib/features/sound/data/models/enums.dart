enum SoundChangeType {
  outputDevice,
  inputDevice,
  outputVolume,
  inputVolume,
  defaultDevice,
}

enum SoundStatus { initial, loading, loaded, error }

enum SoundError {
  initializationFailed,
  getOutputVolumeFailed,
  setOutputVolumeFailed,
  getOutputDevicesFailed,
  getSelectedOutputDeviceFailed,
  setSelectedOutputDeviceFailed,
  getInputVolumeFailed,
  setInputVolumeFailed,
  getInputDevicesFailed,
  getSelectedInputDeviceFailed,
  setSelectedInputDeviceFailed,
  getSoundSettingFailed,
  setSoundSettingFailed,
  unknown,
}
