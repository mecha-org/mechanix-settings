import 'dart:async';
import 'package:dbus/dbus.dart';

class DisplayService {
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

  DisplayService({DBusClient? systemClient, DBusClient? sessionClient})
      : _injectSystemClient = systemClient,
        _injectSessionClient = sessionClient;

  Future<void> init() async {
    if (_initialized) return;
    _systemClient = _injectSystemClient ?? DBusClient.system();
    _sessionClient = _injectSessionClient ?? DBusClient.session();
    _initialized = true;
  }

  Future<double> getBrightness() async {
    await init();
    final object = DBusRemoteObject(
      _systemClient!,
      name: _busName,
      path: DBusObjectPath(_objectPath),
    );

    final response = await object.callMethod(_interface, 'GetBrightness', []);

    if (response.values.isNotEmpty && response.values[0] is DBusByte) {
      final byteValue = (response.values[0] as DBusByte).value;
      return byteValue / 254.0;
    }
    throw Exception('Failed to get brightness: Invalid DBus response');
  }

  Future<void> setBrightness(double brightness) async {
    await init();
    final object = DBusRemoteObject(
      _systemClient!,
      name: _busName,
      path: DBusObjectPath(_objectPath),
    );

    final byteValue = (brightness * 254.0).round();
    await object.callMethod(_interface, 'SetBrightness', [
      DBusByte(byteValue),
    ]);
  }

  Future<bool> getAutoBrightness() async {
    await init();
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
          return value.value.toLowerCase() == 'true';
        }
      }
    }
    throw Exception('Failed to get auto-brightness: Invalid DBus response');
  }

  Future<void> setAutoBrightness(bool enabled) async {
    await init();
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
  }

  Future<int> getScreenTimeout() async {
    await init();
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
            return parsed;
          }
        }
      }
    }
    throw Exception('Failed to get screen timeout: Invalid DBus response');
  }

  Future<void> setScreenTimeout(int timeoutSeconds) async {
    await init();
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
  }

  Future<void> close() async {
    await _systemClient?.close();
    await _sessionClient?.close();
    _systemClient = null;
    _sessionClient = null;
    _initialized = false;
  }
}
