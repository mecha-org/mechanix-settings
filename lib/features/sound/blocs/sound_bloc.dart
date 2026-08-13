import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/features/sound/data/repositories/sound_repository.dart';
import 'sound_event.dart';
import 'sound_state.dart';

class SoundBloc extends Bloc<SoundEvent, SoundState> {
  final SoundRepository _soundRepository;

  SoundBloc({required SoundRepository soundRepository})
      : _soundRepository = soundRepository,
        super(const SoundState()) {
    on<LoadSoundSettings>(_onLoadSoundSettings);
    on<SetOutputVolume>(_onSetOutputVolume);
    on<SetOutputDevice>(_onSetOutputDevice);
    on<SetInputVolume>(_onSetInputVolume);
    on<SetInputDevice>(_onSetInputDevice);
    on<ToggleLauncherSounds>(_onToggleLauncherSounds);
    on<ToggleHapticFeedback>(_onToggleHapticFeedback);
    on<SetNotificationSound>(_onSetNotificationSound);
    on<RefreshDevices>(_onRefreshDevices);
  }

  Future<void> _onLoadSoundSettings(
    LoadSoundSettings event,
    Emitter<SoundState> emit,
  ) async {
    final outputVol = await _soundRepository.getOutputVolume();
    final selectedOut = await _soundRepository.getSelectedOutputDevice();
    final outDevices = await _soundRepository.getOutputDevices();

    final inputVol = await _soundRepository.getInputVolume();
    final selectedIn = await _soundRepository.getSelectedInputDevice();
    final inDevices = await _soundRepository.getInputDevices();

    final launcherEnabled = await _soundRepository.getLauncherSoundsEnabled();
    final hapticEnabled = await _soundRepository.getHapticFeedbackEnabled();

    final selectedNotif = await _soundRepository.getSelectedNotificationSound();
    final notifSounds = await _soundRepository.getNotificationSounds();

    emit(SoundState(
      outputVolume: outputVol,
      selectedOutputDevice: selectedOut,
      outputDevices: outDevices,
      inputVolume: inputVol,
      selectedInputDevice: selectedIn,
      inputDevices: inDevices,
      launcherSoundsEnabled: launcherEnabled,
      hapticFeedbackEnabled: hapticEnabled,
      selectedNotificationSound: selectedNotif,
      notificationSounds: notifSounds,
    ));
  }

  Future<void> _onSetOutputVolume(
    SetOutputVolume event,
    Emitter<SoundState> emit,
  ) async {
    await _soundRepository.setOutputVolume(event.volume);
    emit(state.copyWith(outputVolume: event.volume));
  }

  Future<void> _onSetOutputDevice(
    SetOutputDevice event,
    Emitter<SoundState> emit,
  ) async {
    await _soundRepository.setSelectedOutputDevice(event.device);
    emit(state.copyWith(selectedOutputDevice: event.device));
  }

  Future<void> _onSetInputVolume(
    SetInputVolume event,
    Emitter<SoundState> emit,
  ) async {
    await _soundRepository.setInputVolume(event.volume);
    emit(state.copyWith(inputVolume: event.volume));
  }

  Future<void> _onSetInputDevice(
    SetInputDevice event,
    Emitter<SoundState> emit,
  ) async {
    await _soundRepository.setSelectedInputDevice(event.device);
    emit(state.copyWith(selectedInputDevice: event.device));
  }

  Future<void> _onToggleLauncherSounds(
    ToggleLauncherSounds event,
    Emitter<SoundState> emit,
  ) async {
    await _soundRepository.setLauncherSoundsEnabled(event.enabled);
    emit(state.copyWith(launcherSoundsEnabled: event.enabled));
  }

  Future<void> _onToggleHapticFeedback(
    ToggleHapticFeedback event,
    Emitter<SoundState> emit,
  ) async {
    await _soundRepository.setHapticFeedbackEnabled(event.enabled);
    emit(state.copyWith(hapticFeedbackEnabled: event.enabled));
  }

  Future<void> _onSetNotificationSound(
    SetNotificationSound event,
    Emitter<SoundState> emit,
  ) async {
    await _soundRepository.setSelectedNotificationSound(event.sound);
    emit(state.copyWith(selectedNotificationSound: event.sound));
  }

  Future<void> _onRefreshDevices(
    RefreshDevices event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(isRefreshingDevices: true));
    
    // Simulate short discovery delay to refresh devices list
    await Future.delayed(const Duration(milliseconds: 800));
    
    emit(state.copyWith(isRefreshingDevices: false));
  }
}
