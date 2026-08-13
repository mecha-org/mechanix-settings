import 'package:equatable/equatable.dart';

class SoundState extends Equatable {
  final double outputVolume;
  final String selectedOutputDevice;
  final List<String> outputDevices;

  final double inputVolume;
  final String selectedInputDevice;
  final List<String> inputDevices;

  final bool launcherSoundsEnabled;
  final bool hapticFeedbackEnabled;

  final String selectedNotificationSound;
  final List<String> notificationSounds;

  final bool isRefreshingDevices;

  const SoundState({
    this.outputVolume = 0.60,
    this.selectedOutputDevice = "",
    this.outputDevices = const [],
    this.inputVolume = 0.40,
    this.selectedInputDevice = "",
    this.inputDevices = const [],
    this.launcherSoundsEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.selectedNotificationSound = "",
    this.notificationSounds = const [],
    this.isRefreshingDevices = false,
  });

  SoundState copyWith({
    double? outputVolume,
    String? selectedOutputDevice,
    List<String>? outputDevices,
    double? inputVolume,
    String? selectedInputDevice,
    List<String>? inputDevices,
    bool? launcherSoundsEnabled,
    bool? hapticFeedbackEnabled,
    String? selectedNotificationSound,
    List<String>? notificationSounds,
    bool? isRefreshingDevices,
  }) {
    return SoundState(
      outputVolume: outputVolume ?? this.outputVolume,
      selectedOutputDevice: selectedOutputDevice ?? this.selectedOutputDevice,
      outputDevices: outputDevices ?? this.outputDevices,
      inputVolume: inputVolume ?? this.inputVolume,
      selectedInputDevice: selectedInputDevice ?? this.selectedInputDevice,
      inputDevices: inputDevices ?? this.inputDevices,
      launcherSoundsEnabled: launcherSoundsEnabled ?? this.launcherSoundsEnabled,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      selectedNotificationSound: selectedNotificationSound ?? this.selectedNotificationSound,
      notificationSounds: notificationSounds ?? this.notificationSounds,
      isRefreshingDevices: isRefreshingDevices ?? this.isRefreshingDevices,
    );
  }

  @override
  List<Object?> get props => [
        outputVolume,
        selectedOutputDevice,
        outputDevices,
        inputVolume,
        selectedInputDevice,
        inputDevices,
        launcherSoundsEnabled,
        hapticFeedbackEnabled,
        selectedNotificationSound,
        notificationSounds,
        isRefreshingDevices,
      ];
}
