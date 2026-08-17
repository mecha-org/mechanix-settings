import 'package:dbus/dbus.dart';
import 'package:pulseaudio/pulseaudio.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'sound_repository.dart';

class SoundRepositoryImpl implements SoundRepository {
  final _client = PulseAudioClient();
  bool _connected = false;

  List<PulseAudioSink> _sinks = [];
  List<PulseAudioSource> _sources = [];

  final List<String> _notificationSounds = [
    "Wakeup",
    "Siren",
    "Cosmic",
    "Space",
    "Supernova",
    "Crash",
  ];

  static const String _busName = 'org.mechanix.MxConf';
  static const String _objectPath = '/org/mechanix/MxConf';

  static const enableLauncherSoundKey =
      "org.mechanix.desktop.settings.launcher.enable_sounds.value";

  static const enableVibrationKey =
      "org.mechanix.desktop.settings.haptics.enable_vibration.value";

  static const notificationSoundKey =
      "org.mechanix.desktop.notification.sound.value";

  SoundRepositoryImpl();

  Future<void> _ensureConnected() async {
    if (!_connected) {
      try {
        await _client.initialize();
        _connected = true;
      } catch (e, stack) {
        AppLogger.e("Error connecting to PulseAudio", error: e, stack: stack);
      }
    }
  }

  @override
  Future<void> init() async {
    await _ensureConnected();
  }

  @override
  Future<double> getOutputVolume() async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSinkName = serverInfo.defaultSinkName;
      final sinks = await _client.getSinkList();

      final defaultSink = sinks.firstWhere(
        (sink) => sink.name == defaultSinkName,
        orElse: () => sinks.first,
      );

      return defaultSink.volume.clamp(0.0, 1.0);
    } catch (e, stack) {
      AppLogger.e("Error getting output volume", error: e, stack: stack);
      return 0.5;
    }
  }

  @override
  Future<void> setOutputVolume(double volume) async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSinkName = serverInfo.defaultSinkName;
      await _client.setSinkVolume(defaultSinkName, volume.clamp(0.0, 1.0));
    } catch (e, stack) {
      AppLogger.e("Error setting output volume", error: e, stack: stack);
    }
  }

  @override
  Future<List<String>> getOutputDevices() async {
    await _ensureConnected();
    try {
      final sinks = await _client.getSinkList();
      _sinks = sinks.where((sink) => !sink.name.contains('.monitor')).toList();
      return _sinks
          .map(
            (sink) =>
                sink.description.isNotEmpty ? sink.description : sink.name,
          )
          .toList();
    } catch (e, stack) {
      AppLogger.e("Error getting output devices", error: e, stack: stack);
      return [];
    }
  }

  @override
  Future<String> getSelectedOutputDevice() async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSinkName = serverInfo.defaultSinkName;
      if (_sinks.isEmpty) {
        await getOutputDevices();
      }
      final matched = _sinks.firstWhere(
        (sink) => sink.name == defaultSinkName,
        orElse: () => _sinks.first,
      );
      return matched.description.isNotEmpty
          ? matched.description
          : matched.name;
    } catch (e, stack) {
      AppLogger.e(
        "Error getting selected output device",
        error: e,
        stack: stack,
      );
      return "";
    }
  }

  @override
  Future<void> setSelectedOutputDevice(String device) async {
    await _ensureConnected();
    try {
      if (_sinks.isEmpty) {
        await getOutputDevices();
      }
      final matched = _sinks.firstWhere(
        (sink) => sink.description == device || sink.name == device,
      );
      await _client.setDefaultSink(matched.name);
    } catch (e, stack) {
      AppLogger.e(
        "Error setting default output device",
        error: e,
        stack: stack,
      );
    }
  }

  @override
  Future<double> getInputVolume() async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSourceName = serverInfo.defaultSourceName;
      final sources = await _client.getSourceList();

      final defaultSource = sources.firstWhere(
        (source) => source.name == defaultSourceName,
        orElse: () => sources.first,
      );

      return defaultSource.volume.clamp(0.0, 1.0);
    } catch (e, stack) {
      AppLogger.e("Error getting input volume", error: e, stack: stack);
      return 0.5;
    }
  }

  @override
  Future<void> setInputVolume(double volume) async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSourceName = serverInfo.defaultSourceName;
      await _client.setSourceVolume(defaultSourceName, volume.clamp(0.0, 1.0));
    } catch (e, stack) {
      AppLogger.e("Error setting input volume", error: e, stack: stack);
    }
  }

  @override
  Future<List<String>> getInputDevices() async {
    await _ensureConnected();
    try {
      final sources = await _client.getSourceList();
      _sources = sources
          .where((source) => !source.name.contains('.monitor'))
          .toList();
      return _sources
          .map(
            (source) => source.description.isNotEmpty
                ? source.description
                : source.name,
          )
          .toList();
    } catch (e, stack) {
      AppLogger.e("Error getting input devices", error: e, stack: stack);
      return [];
    }
  }

  @override
  Future<String> getSelectedInputDevice() async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSourceName = serverInfo.defaultSourceName;
      if (_sources.isEmpty) {
        await getInputDevices();
      }
      final matched = _sources.firstWhere(
        (source) => source.name == defaultSourceName,
        orElse: () => _sources.first,
      );
      return matched.description.isNotEmpty
          ? matched.description
          : matched.name;
    } catch (e, stack) {
      AppLogger.e(
        "Error getting selected input device",
        error: e,
        stack: stack,
      );
      return "";
    }
  }

  @override
  Future<void> setSelectedInputDevice(String device) async {
    await _ensureConnected();
    try {
      if (_sources.isEmpty) {
        await getInputDevices();
      }
      final matched = _sources.firstWhere(
        (source) => source.description == device || source.name == device,
      );
      await _client.setDefaultSource(matched.name);
    } catch (e, stack) {
      AppLogger.e("Error setting default input device", error: e, stack: stack);
    }
  }

  Future<String?> _getDBusSetting(String key) async {
    final client = DBusClient.session();
    try {
      final object = DBusRemoteObject(
        client,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );
      final response = await object.callMethod(_busName, 'GetSetting', [
        DBusString(key),
      ]);
      if (response.returnValues.isNotEmpty) {
        final dict = response.returnValues.first;
        if (dict is DBusDict) {
          final value = dict.children[DBusString(key)];
          if (value is DBusString) {
            return value.value;
          }
        }
      }
    } catch (e, stack) {
      AppLogger.e(
        "Error calling get setting via DBus for key $key",
        error: e,
        stack: stack,
      );
    } finally {
      await client.close();
    }
    return null;
  }

  Future<void> _setDBusSetting(String key, String value) async {
    final client = DBusClient.session();
    try {
      final object = DBusRemoteObject(
        client,
        name: _busName,
        path: DBusObjectPath(_objectPath),
      );
      await object.callMethod(_busName, 'SetSetting', [
        DBusStruct([DBusString(key), DBusString(value)]),
      ]);
    } catch (e, stack) {
      AppLogger.e(
        "Error calling set setting via DBus for key $key",
        error: e,
        stack: stack,
      );
    } finally {
      await client.close();
    }
  }

  @override
  Future<bool> getLauncherSoundsEnabled() async {
    final val = await _getDBusSetting(enableLauncherSoundKey);
    if (val != null) {
      return val.toLowerCase() == 'true';
    }
    return true;
  }

  @override
  Future<void> setLauncherSoundsEnabled(bool enabled) async {
    await _setDBusSetting(enableLauncherSoundKey, enabled.toString());
  }

  @override
  Future<bool> getHapticFeedbackEnabled() async {
    final val = await _getDBusSetting(enableVibrationKey);
    if (val != null) {
      return val.toLowerCase() == 'true';
    }
    return true;
  }

  @override
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    await _setDBusSetting(enableVibrationKey, enabled.toString());
  }

  @override
  Future<List<String>> getNotificationSounds() async {
    return List.unmodifiable(_notificationSounds);
  }

  @override
  Future<String> getSelectedNotificationSound() async {
    final val = await _getDBusSetting(notificationSoundKey);
    if (val != null) {
      final matched = _notificationSounds.firstWhere(
        (s) => s.toLowerCase() == val.toLowerCase(),
        orElse: () => "Space",
      );
      return matched;
    }
    return "Space";
  }

  @override
  Future<void> setSelectedNotificationSound(String sound) async {
    await _setDBusSetting(notificationSoundKey, sound.toLowerCase());
  }
}
