import 'dart:async';
import 'package:mechanix_settings/core/exceptions/sound_exceptions.dart';
import 'package:mechanix_settings/features/sound/data/models/enums.dart';
import 'package:pulseaudio/pulseaudio.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'sound_repository.dart';

class SoundRepositoryImpl implements SoundRepository {
  final PulseAudioClient _client;
  bool _connected = false;
  bool _listenersConfigured = false;

  StreamSubscription<PulseAudioSink>? _sinkSubscription;
  StreamSubscription<PulseAudioSource>? _sourceSubscription;
  StreamSubscription<int>? _sinkRemovedSubscription;
  StreamSubscription<int>? _sourceRemovedSubscription;
  StreamSubscription<PulseAudioServerInfo>? _serverInfoSubscription;

  /// Broadcasts sound-related changes from PulseAudio to the SoundBloc.
  late final StreamController<SoundChangeType> _soundChangedController =
      StreamController<SoundChangeType>.broadcast();

  @override
  Stream<SoundChangeType> get onSoundChanged => _soundChangedController.stream;

  List<PulseAudioSink> _sinks = []; // Output devices
  List<PulseAudioSource> _sources = []; // Input devices

  /// List of notification sounds
  final List<String> _notificationSounds = [
    "Wakeup",
    "Siren",
    "Cosmic",
    "Space",
    "Supernova",
    "Crash",
  ];

  // TODO: Add MxConf integration for persistent settings later.
  bool _launcherSoundsEnabled = true;
  bool _hapticFeedbackEnabled = true;
  String _selectedNotificationSound = "Space";

  SoundRepositoryImpl({PulseAudioClient? client})
    : _client = client ?? PulseAudioClient();

  /// Establishes the PulseAudio connection if it is not already connected
  /// and configures the PulseAudio event listeners.
  Future<void> _ensureConnected() async {
    if (!_connected) {
      AppLogger.i("SoundRepositoryImpl: Connecting to PulseAudio Client...");

      try {
        await _client.initialize();
        _connected = true;
        _setupPulseAudioListeners();

        AppLogger.i(
          "SoundRepositoryImpl: PulseAudio Client connected successfully.",
        );
      } catch (e, stack) {
        AppLogger.e("Error connecting to PulseAudio", error: e, stack: stack);
        throw const SoundInitializationException();
      }
    }
  }

  /// Registers listeners for PulseAudio sink, source, removal, and
  /// server information changes.
  ///
  /// These events are converted into [SoundChangeType] events and exposed
  /// through [onSoundChanged] so the SoundBloc can refresh only the
  /// affected part of the sound settings.
  void _setupPulseAudioListeners() {
    if (_listenersConfigured) return;
    _listenersConfigured = true;

    _sinkSubscription = _client.onSinkChanged.listen((sink) {
      AppLogger.i(
        "SoundRepositoryImpl: PulseAudio sink changed "
        "(sink: ${sink.name}, volume: ${sink.volume}).",
      );

      _notifyChange(SoundChangeType.outputVolume);
    });

    _sourceSubscription = _client.onSourceChanged.listen((source) {
      AppLogger.i(
        "SoundRepositoryImpl: PulseAudio source changed "
        "(source: ${source.name}, volume: ${source.volume}).",
      );

      _notifyChange(SoundChangeType.inputVolume);
    });

    _sinkRemovedSubscription = _client.onSinkRemoved.listen((index) {
      AppLogger.i(
        "SoundRepositoryImpl: PulseAudio sink removed "
        "(index: $index).",
      );

      _notifyChange(SoundChangeType.outputDevice);
    });

    _sourceRemovedSubscription = _client.onSourceRemoved.listen((index) {
      AppLogger.i(
        "SoundRepositoryImpl: PulseAudio source removed "
        "(index: $index).",
      );

      _notifyChange(SoundChangeType.inputDevice);
    });

    _serverInfoSubscription = _client.onServerInfoChanged.listen((info) {
      AppLogger.i(
        "SoundRepositoryImpl: PulseAudio server info changed "
        "(defaultSink: ${info.defaultSinkName}, "
        "defaultSource: ${info.defaultSourceName}).",
      );

      _notifyChange(SoundChangeType.defaultDevice);
    });
  }

  /// Publishes a sound change event to all listeners.
  void _notifyChange(SoundChangeType changeType) {
    AppLogger.i("SoundRepositoryImpl: Sound change detected: $changeType");

    if (!_soundChangedController.isClosed) {
      _soundChangedController.add(changeType);
    }
  }

  /// Initializes the sound repository and establishes the PulseAudio
  /// connection.
  @override
  Future<void> init() async {
    try {
      await _ensureConnected();
    } catch (e, stack) {
      AppLogger.e("Error during sound initialization", error: e, stack: stack);
      throw const SoundInitializationException();
    }
  }

  /// Returns the volume of the currently selected/default output device.
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
      throw const GetOutputVolumeException();
    }
  }

  /// Sets the volume of the currently selected/default output device.
  @override
  Future<void> setOutputVolume(double volume) async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSinkName = serverInfo.defaultSinkName;

      await _client.setSinkVolume(defaultSinkName, volume.clamp(0.0, 1.0));
    } catch (e, stack) {
      AppLogger.e("Error setting output volume", error: e, stack: stack);
      throw const SetOutputVolumeException();
    }
  }

  /// Returns the list of available output devices (sinks) from PulseAudio.
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
      throw const GetOutputDevicesException();
    }
  }

  /// Returns the currently selected/default output device.
  @override
  Future<String> getSelectedOutputDevice() async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSinkName = serverInfo.defaultSinkName;

      await getOutputDevices();

      if (_sinks.isEmpty) return "";

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
      throw const GetSelectedOutputDeviceException();
    }
  }

  /// Sets the specified output device as the default PulseAudio sink.
  @override
  Future<void> setSelectedOutputDevice(String device) async {
    await _ensureConnected();
    try {
      await getOutputDevices();
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
      throw const SetSelectedOutputDeviceException();
    }
  }

  /// Returns the volume of the currently selected/default input device.
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
      throw const GetInputVolumeException();
    }
  }

  /// Sets the volume of the currently selected/default input device.
  @override
  Future<void> setInputVolume(double volume) async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSourceName = serverInfo.defaultSourceName;

      await _client.setSourceVolume(defaultSourceName, volume.clamp(0.0, 1.0));
    } catch (e, stack) {
      AppLogger.e("Error setting input volume", error: e, stack: stack);
      throw const SetInputVolumeException();
    }
  }

  /// Returns the list of available input devices (sources) from PulseAudio.
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
      throw const GetInputDevicesException();
    }
  }

  /// Returns the currently selected/default input device.
  @override
  Future<String> getSelectedInputDevice() async {
    await _ensureConnected();
    try {
      final serverInfo = await _client.getServerInfo();
      final defaultSourceName = serverInfo.defaultSourceName;
      await getInputDevices();

      if (_sources.isEmpty) return "";

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
      throw const GetSelectedInputDeviceException();
    }
  }

  /// Sets the specified input device as the default PulseAudio source.
  @override
  Future<void> setSelectedInputDevice(String device) async {
    await _ensureConnected();
    try {
      await getInputDevices();

      final matched = _sources.firstWhere(
        (source) => source.description == device || source.name == device,
      );

      await _client.setDefaultSource(matched.name);
    } catch (e, stack) {
      AppLogger.e("Error setting default input device", error: e, stack: stack);
      throw const SetSelectedInputDeviceException();
    }
  }

  /// Returns whether launcher sounds are enabled.
  ///
  /// TODO: Replace the in-memory value with MxConf persistence.
  @override
  Future<bool> getLauncherSoundsEnabled() async {
    try {
      return _launcherSoundsEnabled;
    } catch (e, stack) {
      AppLogger.e("Error getting launcher sounds", error: e, stack: stack);
      throw const GetSoundSettingException();
    }
  }

  /// Updates the launcher sound enabled state.
  ///
  /// TODO: Persist the value using MxConf.
  @override
  Future<void> setLauncherSoundsEnabled(bool enabled) async {
    try {
      _launcherSoundsEnabled = enabled;
    } catch (e, stack) {
      AppLogger.e("Error setting launcher sounds", error: e, stack: stack);
      throw const SetSoundSettingException();
    }
  }

  /// Returns whether haptic feedback is enabled.
  ///
  /// TODO: Replace the in-memory value with MxConf persistence.
  @override
  Future<bool> getHapticFeedbackEnabled() async {
    try {
      return _hapticFeedbackEnabled;
    } catch (e, stack) {
      AppLogger.e("Error getting haptic feedback", error: e, stack: stack);
      throw const GetSoundSettingException();
    }
  }

  /// Updates the haptic feedback enabled state.
  ///
  /// TODO: Persist the value using MxConf.
  @override
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    try {
      _hapticFeedbackEnabled = enabled;
    } catch (e, stack) {
      AppLogger.e("Error setting haptic feedback", error: e, stack: stack);
      throw const SetSoundSettingException();
    }
  }

  /// Returns the list of available notification sounds.
  @override
  Future<List<String>> getNotificationSounds() async {
    try {
      return List.unmodifiable(_notificationSounds);
    } catch (e, stack) {
      AppLogger.e(
        "Error getting notification sounds list",
        error: e,
        stack: stack,
      );
      throw const GetSoundSettingException();
    }
  }

  /// Returns the currently selected notification sound.
  ///
  /// TODO: Replace the in-memory value with MxConf persistence.
  @override
  Future<String> getSelectedNotificationSound() async {
    try {
      return _selectedNotificationSound;
    } catch (e, stack) {
      AppLogger.e(
        "Error getting selected notification sound",
        error: e,
        stack: stack,
      );
      throw const GetSoundSettingException();
    }
  }

  /// Updates the selected notification sound.
  ///
  /// TODO: Persist the value using MxConf.
  @override
  Future<void> setSelectedNotificationSound(String sound) async {
    try {
      _selectedNotificationSound = sound;
    } catch (e, stack) {
      AppLogger.e("Error setting notification sound", error: e, stack: stack);
      throw const SetSoundSettingException();
    }
  }

  /// Releases PulseAudio subscriptions, closes the change stream, and
  /// resets the repository connection state.
  @override
  Future<void> close() async {
    try {
      await _sinkSubscription?.cancel();
      await _sourceSubscription?.cancel();
      await _sinkRemovedSubscription?.cancel();
      await _sourceRemovedSubscription?.cancel();
      await _serverInfoSubscription?.cancel();

      _sinkSubscription = null;
      _sourceSubscription = null;
      _sinkRemovedSubscription = null;
      _sourceRemovedSubscription = null;
      _serverInfoSubscription = null;

      if (!_soundChangedController.isClosed) {
        await _soundChangedController.close();
      }

      _connected = false;
      _listenersConfigured = false;

      _sinks.clear();
      _sources.clear();
    } catch (e, stack) {
      AppLogger.e("Error closing PulseAudio client", error: e, stack: stack);
      throw const SoundCloseException();
    }
  }
}
