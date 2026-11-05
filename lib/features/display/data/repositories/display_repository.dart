import 'package:mechanix_settings/generated/settingsapp.dart';
import 'package:mxconfig_dart/mxconfig.dart';

abstract class DisplayRepository {
  Future<void> init();
  Future<double> getBrightness();
  Future<void> setBrightness(double brightness);
  Future<bool> getAutoBrightness();
  Future<void> setAutoBrightness(bool enabled);
  Future<int> getScreenTimeout();
  Future<void> setScreenTimeout(int timeoutSeconds);
  Stream<SettingsappChange> changes();
  Stream<WriteFailure> watchWriteFailed();
  Future<void> close();
}
