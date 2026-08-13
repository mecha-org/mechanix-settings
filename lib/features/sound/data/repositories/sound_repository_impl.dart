import 'sound_repository.dart';

class SoundRepositoryImpl implements SoundRepository {
  double _outputVolume = 0.60;
  String _selectedOutputDevice = "Comet in-built speaker";
  final List<String> _outputDevices = [
    "Comet in-built speaker",
    "Mac speaker",
    "JBL Cinema",
  ];

  double _inputVolume = 0.40;
  String _selectedInputDevice = "Comet in-built mic";
  final List<String> _inputDevices = [
    "Comet in-built mic",
    "JBL headshot",
    "Mac in-built mic",
  ];

  bool _launcherSoundsEnabled = true;
  bool _hapticFeedbackEnabled = true;

  String _selectedNotificationSound = "Space";
  final List<String> _notificationSounds = [
    "Wakeup",
    "Siren",
    "Cosmic",
    "Space",
    "Supernova",
    "Crash",
  ];

  @override
  Future<void> init() async {
    // No-op for mock implementation
  }

  @override
  Future<double> getOutputVolume() async {
    return _outputVolume;
  }

  @override
  Future<void> setOutputVolume(double volume) async {
    _outputVolume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<List<String>> getOutputDevices() async {
    return List.unmodifiable(_outputDevices);
  }

  @override
  Future<String> getSelectedOutputDevice() async {
    return _selectedOutputDevice;
  }

  @override
  Future<void> setSelectedOutputDevice(String device) async {
    if (_outputDevices.contains(device)) {
      _selectedOutputDevice = device;
    }
  }

  @override
  Future<double> getInputVolume() async {
    return _inputVolume;
  }

  @override
  Future<void> setInputVolume(double volume) async {
    _inputVolume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<List<String>> getInputDevices() async {
    return List.unmodifiable(_inputDevices);
  }

  @override
  Future<String> getSelectedInputDevice() async {
    return _selectedInputDevice;
  }

  @override
  Future<void> setSelectedInputDevice(String device) async {
    if (_inputDevices.contains(device)) {
      _selectedInputDevice = device;
    }
  }

  @override
  Future<bool> getLauncherSoundsEnabled() async {
    return _launcherSoundsEnabled;
  }

  @override
  Future<void> setLauncherSoundsEnabled(bool enabled) async {
    _launcherSoundsEnabled = enabled;
  }

  @override
  Future<bool> getHapticFeedbackEnabled() async {
    return _hapticFeedbackEnabled;
  }

  @override
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
  }

  @override
  Future<List<String>> getNotificationSounds() async {
    return List.unmodifiable(_notificationSounds);
  }

  @override
  Future<String> getSelectedNotificationSound() async {
    return _selectedNotificationSound;
  }

  @override
  Future<void> setSelectedNotificationSound(String sound) async {
    if (_notificationSounds.contains(sound)) {
      _selectedNotificationSound = sound;
    }
  }
}
