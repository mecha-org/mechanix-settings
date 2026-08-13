abstract class SoundRepository {
  Future<void> init();
  
  Future<double> getOutputVolume();
  Future<void> setOutputVolume(double volume);
  
  Future<List<String>> getOutputDevices();
  Future<String> getSelectedOutputDevice();
  Future<void> setSelectedOutputDevice(String device);
  
  Future<double> getInputVolume();
  Future<void> setInputVolume(double volume);
  
  Future<List<String>> getInputDevices();
  Future<String> getSelectedInputDevice();
  Future<void> setSelectedInputDevice(String device);
  
  Future<bool> getLauncherSoundsEnabled();
  Future<void> setLauncherSoundsEnabled(bool enabled);
  
  Future<bool> getHapticFeedbackEnabled();
  Future<void> setHapticFeedbackEnabled(bool enabled);
  
  Future<List<String>> getNotificationSounds();
  Future<String> getSelectedNotificationSound();
  Future<void> setSelectedNotificationSound(String sound);
}
