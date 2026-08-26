import 'dart:async';
import 'package:dbus/dbus.dart';
import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'display_repository.dart';

class DisplayRepositoryImpl implements DisplayRepository {
  static const String _busName = 'org.mechanix.services.Display';
  static const String _objectPath = '/org/mechanix/services/Display';
  static const String _interface = 'org.mechanix.services.Display';

  static const String autoBrightnessKey =
      "org.mechanix.desktop.settings.display.enable_auto_brightness.value";
  static const String displayTimeoutKey =
      "org.mechanix.desktop.settings.display.timeout.value";

  DBusClient? _systemClient;
  DBusClient? _sessionClient;
  bool _initialized = false;

  final DBusClient? _injectSystemClient;
  final DBusClient? _injectSessionClient;

  // Local caching variables for graceful fallback
  double _cachedBrightness = 0.5;
  bool _cachedAutoBrightness = true;
  int _cachedScreenTimeout = 30; // default 30 seconds

  DisplayRepositoryImpl({DBusClient? systemClient, DBusClient? sessionClient})
    : _injectSystemClient = systemClient,
      _injectSessionClient = sessionClient;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      _systemClient = _injectSystemClient ?? DBusClient.system();
      _sessionClient = _injectSessionClient ?? DBusClient.session();
      _initialized = true;
      AppLogger.d("DisplayRepositoryImpl initialized successfully");
    } catch (e, stackTrace) {
      AppLogger.e(
        "Failed to initialize DisplayRepository DBus clients: $e",
        stack: stackTrace,
      );
      throw const DisplayInitializationException();
    }
  }

  @override
  Future<double> getBrightness() async {
    await init();
    try {
      final object = DBusRemoteObject(
        _systemClient!,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );

      final response = await object.callMethod(_interface, 'GetBrightness', []);

      if (response.values.isNotEmpty && response.values[0] is DBusByte) {
        final byteValue = (response.values[0] as DBusByte).value;
        _cachedBrightness = byteValue / 254.0;
      }
      return _cachedBrightness;
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error getting brightness from DBus, using cached: $e",
        stack: stackTrace,
      );
      // Return cached value if DBus service is unavailable
      return _cachedBrightness;
    }
  }

  @override
  Future<void> setBrightness(double brightness) async {
    await init();
    // Clamp to 0.0 - 1.0 range
    final clamped = brightness.clamp(0.0, 1.0);
    _cachedBrightness = clamped;

    try {
      final object = DBusRemoteObject(
        _systemClient!,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );

      final byteValue = (clamped * 254.0).round();
      await object.callMethod(_interface, 'SetBrightness', [
        DBusByte(byteValue),
      ]);
      AppLogger.i("Brightness set to $byteValue via DBus");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set brightness via DBus: $e", stack: stackTrace);
      throw const SetBrightnessException();
    }
  }

  @override
  Future<bool> getAutoBrightness() async {
    await init();
    // Since GetSetting is not implemented or commented out in old app, we might check if it's available or fallback to local cached.
    try {
      final object = DBusRemoteObject(
        _sessionClient!,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );

      final response = await object.callMethod(_interface, 'GetSetting', [
        const DBusString(autoBrightnessKey),
      ]);

      if (response.returnValues.isNotEmpty) {
        final dict = response.returnValues.first;
        if (dict is DBusDict) {
          final value = dict.children[const DBusString(autoBrightnessKey)];
          if (value is DBusString) {
            _cachedAutoBrightness = value.value.toLowerCase() == 'true';
          }
        }
      }
      return _cachedAutoBrightness;
    } catch (e) {
      AppLogger.e(
        "GetAutoBrightness DBus call not available, using cached: $e",
      );
      return _cachedAutoBrightness;
    }
  }

  @override
  Future<void> setAutoBrightness(bool enabled) async {
    await init();
    _cachedAutoBrightness = enabled;

    try {
      final object = DBusRemoteObject(
        _sessionClient!,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );

      await object.callMethod(_interface, 'SetSetting', [
        DBusStruct([
          const DBusString(autoBrightnessKey),
          DBusString(enabled.toString()),
        ]),
      ]);
      AppLogger.i("AutoBrightness set to $enabled via DBus");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set auto brightness: $e", stack: stackTrace);
      throw const SetAutoBrightnessException();
    }
  }

  @override
  Future<int> getScreenTimeout() async {
    await init();
    try {
      final object = DBusRemoteObject(
        _sessionClient!,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );

      final response = await object.callMethod(_interface, 'GetSetting', [
        const DBusString(displayTimeoutKey),
      ]);

      if (response.returnValues.isNotEmpty) {
        final dict = response.returnValues.first;
        if (dict is DBusDict) {
          final value = dict.children[const DBusString(displayTimeoutKey)];
          if (value is DBusString) {
            final parsed = int.tryParse(value.value);
            if (parsed != null) {
              _cachedScreenTimeout = parsed;
            }
          }
        }
      }
      return _cachedScreenTimeout;
    } catch (e) {
      AppLogger.e("GetScreenTimeout DBus call not available, using cached: $e");
      return _cachedScreenTimeout;
    }
  }

  @override
  Future<void> setScreenTimeout(int timeoutSeconds) async {
    await init();
    _cachedScreenTimeout = timeoutSeconds;

    try {
      final object = DBusRemoteObject(
        _sessionClient!,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );

      await object.callMethod(_interface, 'SetSetting', [
        DBusStruct([
          const DBusString(displayTimeoutKey),
          DBusString(timeoutSeconds.toString()),
        ]),
      ]);
      AppLogger.i("ScreenTimeout set to $timeoutSeconds via DBus");
    } catch (e, stackTrace) {
      AppLogger.e("Failed to set screen timeout: $e", stack: stackTrace);
      throw const SetScreenTimeoutException();
    }
  }

  @override
  Future<void> close() async {
    try {
      await _systemClient?.close();
      await _sessionClient?.close();
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error closing DisplayRepository DBus clients: $e",
        stack: stackTrace,
      );
      throw const DisplayCloseException();
    } finally {
      _systemClient = null;
      _sessionClient = null;
      _initialized = false;
    }
  }
}
