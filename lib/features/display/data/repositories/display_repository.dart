abstract class DisplayRepository {
  Future<void> init();
  Future<double> getBrightness();
  Future<void> setBrightness(double brightness);
  Future<bool> getAutoBrightness();
  Future<void> setAutoBrightness(bool enabled);
  Future<int> getScreenTimeout();
  Future<void> setScreenTimeout(int timeoutSeconds);
  Future<void> close();
}
