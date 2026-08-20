import 'package:equatable/equatable.dart';

abstract class SoundEvent extends Equatable {
  const SoundEvent();

  @override
  List<Object?> get props => [];
}

class SoundInit extends SoundEvent {
  const SoundInit();
}

class LoadSoundSettings extends SoundEvent {
  const LoadSoundSettings();
}

class SetOutputVolume extends SoundEvent {
  final double volume;

  const SetOutputVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

class SetOutputDevice extends SoundEvent {
  final String device;

  const SetOutputDevice(this.device);

  @override
  List<Object?> get props => [device];
}

class SetInputVolume extends SoundEvent {
  final double volume;

  const SetInputVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

class SetInputDevice extends SoundEvent {
  final String device;

  const SetInputDevice(this.device);

  @override
  List<Object?> get props => [device];
}

class ToggleLauncherSounds extends SoundEvent {
  final bool enabled;

  const ToggleLauncherSounds(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleHapticFeedback extends SoundEvent {
  final bool enabled;

  const ToggleHapticFeedback(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SetNotificationSound extends SoundEvent {
  final String sound;

  const SetNotificationSound(this.sound);

  @override
  List<Object?> get props => [sound];
}

class RefreshOutputDevicesList extends SoundEvent {
  const RefreshOutputDevicesList();
}

class RefreshInputDevicesList extends SoundEvent {
  const RefreshInputDevicesList();
}

class RefreshOutputVolume extends SoundEvent {
  const RefreshOutputVolume();
}

class RefreshInputVolume extends SoundEvent {
  const RefreshInputVolume();
}
