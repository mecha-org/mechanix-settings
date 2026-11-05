import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/generated/settingsapp.dart';
import 'package:mxconfig_dart/mxconfig.dart';
import 'display_repository.dart';

class DisplayRepositoryImpl implements DisplayRepository {
  final Future<Settingsapp> Function() _openSettings;
  Future<Settingsapp>? _opening;

  DisplayRepositoryImpl({Future<Settingsapp> Function()? openSettings})
    : _openSettings = openSettings ?? Settingsapp.open;

  /// Opens the settings on first use and shares that open between callers,
  /// since the bloc may read before [init] has finished.
  Future<Display> _display() async {
    final opening = _opening ??= _openSettings();
    try {
      return (await opening).display;
    } catch (_) {
      // Let the next call retry rather than replay the failure.
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
  }

  @override
  Future<void> init() async {
    try {
      await _display();
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
      return (await _display()).brightness / 254;
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error getting brightness from settings: $e",
        stack: stackTrace,
      );
      throw const GetBrightnessException();
    }
  }

  @override
  Future<void> setBrightness(double brightness) async {
    final clamped = brightness.clamp(0.0, 1.0);

    try {
      (await _display()).setBrightness((clamped * 254).round());
      AppLogger.i("Brightness set to $clamped");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set brightness: $e", stack: stackTrace);
      throw const SetBrightnessException();
    }
  }

  @override
  Future<bool> getAutoBrightness() async {
    try {
      return (await _display()).autoBrightness;
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error getting auto-brightness from settings: $e",
        stack: stackTrace,
      );
      throw const GetAutoBrightnessException();
    }
  }

  @override
  Future<void> setAutoBrightness(bool enabled) async {
    try {
      (await _display()).setAutoBrightness(enabled);
      AppLogger.i("AutoBrightness set to $enabled");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set auto-brightness: $e", stack: stackTrace);
      throw const SetAutoBrightnessException();
    }
  }

  @override
  Future<int> getScreenTimeout() async {
    try {
      return (await _display()).screenTimeout;
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error getting screen timeout from settings: $e",
        stack: stackTrace,
      );
      throw const GetScreenTimeoutException();
    }
  }

  @override
  Future<void> setScreenTimeout(int timeoutSeconds) async {
    try {
      (await _display()).setScreenTimeout(timeoutSeconds);
      AppLogger.i("ScreenTimeout set to $timeoutSeconds");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set screen timeout: $e", stack: stackTrace);
      throw const SetScreenTimeoutException();
    }
  }

  @override
  Stream<SettingsappChange> changes() async* {
    final opening = _opening ??= _openSettings();
    yield* (await opening).changes();
  }

  @override
  Stream<WriteFailure> watchWriteFailed() async* {
    final opening = _opening ??= _openSettings();
    yield* (await opening).settings.watchWriteFailed();
  }

  @override
  Future<void> close() async {
    try {
      final opening = _opening;
      _opening = null;
      (await opening)?.settings.dispose();
    } catch (e, stackTrace) {
      AppLogger.e("Error closing DisplayRepository: $e", stack: stackTrace);
      throw const DisplayCloseException();
    }
  }
}
