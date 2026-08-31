import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'display_repository.dart';
import '../services/display_service.dart';

class DisplayRepositoryImpl implements DisplayRepository {
  final DisplayService _displayService;

  DisplayRepositoryImpl({
    DisplayService? displayService,
    DBusClient? systemClient,
    DBusClient? sessionClient,
  }) : _displayService =
           displayService ??
           DisplayService(
             systemClient: systemClient,
             sessionClient: sessionClient,
           );

  @override
  Future<void> init() async {
    try {
      await _displayService.init();
      AppLogger.d("DisplayRepositoryImpl initialized successfully");
    } catch (e, stackTrace) {
      AppLogger.e(
        "Failed to initialize DisplayRepository: $e",
        stack: stackTrace,
      );
      throw const DisplayInitializationException();
    }
  }

  @override
  Future<double> getBrightness() async {
    try {
      return await _displayService.getBrightness();
    } catch (e, stackTrace) {
      AppLogger.e("Error getting brightness from DBus: $e", stack: stackTrace);
      throw const GetBrightnessException();
    }
  }

  @override
  Future<void> setBrightness(double brightness) async {
    final clamped = brightness.clamp(0.0, 1.0);

    try {
      await _displayService.setBrightness(clamped);
      AppLogger.i("Brightness set to $clamped");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set brightness: $e", stack: stackTrace);
      throw const SetBrightnessException();
    }
  }

  @override
  Future<bool> getAutoBrightness() async {
    try {
      return await _displayService.getAutoBrightness();
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error getting auto-brightness from DBus: $e",
        stack: stackTrace,
      );
      throw const GetAutoBrightnessException();
    }
  }

  @override
  Future<void> setAutoBrightness(bool enabled) async {
    try {
      await _displayService.setAutoBrightness(enabled);
      AppLogger.i("AutoBrightness set to $enabled");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set auto-brightness: $e", stack: stackTrace);
      throw const SetAutoBrightnessException();
    }
  }

  @override
  Future<int> getScreenTimeout() async {
    try {
      return await _displayService.getScreenTimeout();
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error getting screen timeout from DBus: $e",
        stack: stackTrace,
      );
      throw const GetScreenTimeoutException();
    }
  }

  @override
  Future<void> setScreenTimeout(int timeoutSeconds) async {
    try {
      await _displayService.setScreenTimeout(timeoutSeconds);
      AppLogger.i("ScreenTimeout set to $timeoutSeconds");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set screen timeout: $e", stack: stackTrace);
      throw const SetScreenTimeoutException();
    }
  }

  @override
  Future<void> close() async {
    try {
      await _displayService.close();
    } catch (e, stackTrace) {
      AppLogger.e("Error closing DisplayRepository: $e", stack: stackTrace);
      throw const DisplayCloseException();
    }
  }
}
