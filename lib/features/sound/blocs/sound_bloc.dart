import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/exceptions/sound_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/sound/data/models/enums.dart';
import 'package:mechanix_settings/features/sound/data/repositories/sound_repository.dart';

import 'sound_event.dart';
import 'sound_state.dart';

class SoundBloc extends Bloc<SoundEvent, SoundState> {
  final SoundRepository _soundRepository;
  StreamSubscription? _changeSubscription;

  SoundBloc({required SoundRepository soundRepository})
      : _soundRepository = soundRepository,
        super(const SoundState()) {
    on<SoundInit>(_onInit);
    on<LoadSoundSettings>(_onLoadSoundSettings);
    on<SetOutputVolume>(_onSetOutputVolume);
    on<SetOutputDevice>(_onSetOutputDevice);
    on<SetInputVolume>(_onSetInputVolume);
    on<SetInputDevice>(_onSetInputDevice);
    on<ToggleLauncherSounds>(_onToggleLauncherSounds);
    on<ToggleHapticFeedback>(_onToggleHapticFeedback);
    on<SetNotificationSound>(_onSetNotificationSound);
    on<RefreshOutputDevicesList>(_onRefreshOutputDevicesList);
    on<RefreshInputDevicesList>(_onRefreshInputDevicesList);
    on<RefreshOutputVolume>(_onRefreshOutputVolume);
    on<RefreshInputVolume>(_onRefreshInputVolume);
  }

  /// Initializes the sound repository and starts listening for sound changes.
  Future<void> _onInit(SoundInit event, Emitter<SoundState> emit) async {
    emit(state.copyWith(status: SoundStatus.loading, error: null));
    try {
      await _soundRepository.init();
      await _initializeSoundStream();
      emit(state.copyWith(status: SoundStatus.loaded, error: null));
    } on SoundInitializationException catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Failed to initialize sound",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.initializationFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error initializing sound",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Subscribes to repository sound changes and dispatches
  /// only the event required for the type of change.
  Future<void> _initializeSoundStream() async {
    try {
      await _changeSubscription?.cancel();

      _changeSubscription = _soundRepository.onSoundChanged.listen((change) {
        if (isClosed) return;

        AppLogger.i("SoundBloc: Sound change received: $change");

        switch (change) {
          case SoundChangeType.outputDevice:
            add(const RefreshOutputDevicesList());
            break;

          case SoundChangeType.inputDevice:
            add(const RefreshInputDevicesList());
            break;

          case SoundChangeType.outputVolume:
            add(const RefreshOutputVolume());
            break;

          case SoundChangeType.inputVolume:
            add(const RefreshInputVolume());
            break;

          case SoundChangeType.defaultDevice:
            add(const LoadSoundSettings());
            break;
        }
      });
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Failed to initialize sound events stream",
        error: e,
        stack: stack,
      );
      rethrow;
    }
  }

  /// Loads all sound settings including volumes, selected devices,
  /// available devices, and other sound preferences.
  Future<void> _onLoadSoundSettings(
    LoadSoundSettings event,
    Emitter<SoundState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SoundStatus.loading,
        error: null,
        inputDeviceLoading: state.inputDevices.isEmpty,
        outputDeviceLoading: state.outputDevices.isEmpty,
      ),
    );

    try {
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

      emit(
        SoundState(
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
          inputDeviceLoading: false,
          outputDeviceLoading: false,
          status: SoundStatus.loaded,
          error: null,
        ),
      );
    } on GetOutputVolumeException catch (e, stack) {
      AppLogger.e("SoundBloc: Error getting output volume", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getOutputVolumeFailed,
        inputDeviceLoading: false,
        outputDeviceLoading: false,
      ));
    } on GetSelectedOutputDeviceException catch (e, stack) {
      AppLogger.e("SoundBloc: Error getting selected output device", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getSelectedOutputDeviceFailed,
        inputDeviceLoading: false,
        outputDeviceLoading: false,
      ));
    } on GetOutputDevicesException catch (e, stack) {
      AppLogger.e("SoundBloc: Error getting output devices", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getOutputDevicesFailed,
        inputDeviceLoading: false,
        outputDeviceLoading: false,
      ));
    } on GetInputVolumeException catch (e, stack) {
      AppLogger.e("SoundBloc: Error getting input volume", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getInputVolumeFailed,
        inputDeviceLoading: false,
        outputDeviceLoading: false,
      ));
    } on GetSelectedInputDeviceException catch (e, stack) {
      AppLogger.e("SoundBloc: Error getting selected input device", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getSelectedInputDeviceFailed,
        inputDeviceLoading: false,
        outputDeviceLoading: false,
      ));
    } on GetInputDevicesException catch (e, stack) {
      AppLogger.e("SoundBloc: Error getting input devices", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getInputDevicesFailed,
        inputDeviceLoading: false,
        outputDeviceLoading: false,
      ));
    } on GetSoundSettingException catch (e, stack) {
      AppLogger.e("SoundBloc: Error getting sound settings", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getSoundSettingFailed,
        inputDeviceLoading: false,
        outputDeviceLoading: false,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Error loading sound settings",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: SoundStatus.error,
          error: SoundError.unknown,
          inputDeviceLoading: false,
          outputDeviceLoading: false,
        ),
      );
    }
  }

  /// Updates the output volume in PulseAudio and immediately updates
  /// the corresponding value in the UI state.
  Future<void> _onSetOutputVolume(
    SetOutputVolume event,
    Emitter<SoundState> emit,
  ) async {
    try {
      await _soundRepository.setOutputVolume(event.volume);
      emit(state.copyWith(outputVolume: event.volume, error: null));
    } on SetOutputVolumeException catch (e, stack) {
      AppLogger.e("SoundBloc: Error setting output volume", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.setOutputVolumeFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error setting output volume",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Changes the default output device and updates the selected device
  /// in the UI state.
  Future<void> _onSetOutputDevice(
    SetOutputDevice event,
    Emitter<SoundState> emit,
  ) async {
    try {
      await _soundRepository.setSelectedOutputDevice(event.device);
      emit(state.copyWith(selectedOutputDevice: event.device, error: null));
    } on SetSelectedOutputDeviceException catch (e, stack) {
      AppLogger.e("SoundBloc: Error setting output device", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.setSelectedOutputDeviceFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error setting output device",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Updates the input volume in PulseAudio and immediately updates
  /// the corresponding value in the UI state.
  Future<void> _onSetInputVolume(
    SetInputVolume event,
    Emitter<SoundState> emit,
  ) async {
    try {
      await _soundRepository.setInputVolume(event.volume);
      emit(state.copyWith(inputVolume: event.volume, error: null));
    } on SetInputVolumeException catch (e, stack) {
      AppLogger.e("SoundBloc: Error setting input volume", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.setInputVolumeFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error setting input volume",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Changes the default input device and updates the selected device
  /// in the UI state.
  Future<void> _onSetInputDevice(
    SetInputDevice event,
    Emitter<SoundState> emit,
  ) async {
    try {
      await _soundRepository.setSelectedInputDevice(event.device);
      emit(state.copyWith(selectedInputDevice: event.device, error: null));
    } on SetSelectedInputDeviceException catch (e, stack) {
      AppLogger.e("SoundBloc: Error setting input device", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.setSelectedInputDeviceFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error setting input device",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Enables or disables launcher sounds and updates the UI state.
  Future<void> _onToggleLauncherSounds(
    ToggleLauncherSounds event,
    Emitter<SoundState> emit,
  ) async {
    try {
      await _soundRepository.setLauncherSoundsEnabled(event.enabled);
      emit(state.copyWith(launcherSoundsEnabled: event.enabled, error: null));
    } on SetSoundSettingException catch (e, stack) {
      AppLogger.e("SoundBloc: Error setting launcher sounds", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.setSoundSettingFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error setting launcher sounds",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Enables or disables haptic feedback and updates the UI state.
  Future<void> _onToggleHapticFeedback(
    ToggleHapticFeedback event,
    Emitter<SoundState> emit,
  ) async {
    try {
      await _soundRepository.setHapticFeedbackEnabled(event.enabled);
      emit(state.copyWith(hapticFeedbackEnabled: event.enabled, error: null));
    } on SetSoundSettingException catch (e, stack) {
      AppLogger.e("SoundBloc: Error setting haptic feedback", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.setSoundSettingFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error setting haptic feedback",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Changes the selected notification sound and updates the UI state.
  Future<void> _onSetNotificationSound(
    SetNotificationSound event,
    Emitter<SoundState> emit,
  ) async {
    try {
      await _soundRepository.setSelectedNotificationSound(event.sound);
      emit(state.copyWith(selectedNotificationSound: event.sound, error: null));
    } on SetSoundSettingException catch (e, stack) {
      AppLogger.e("SoundBloc: Error setting notification sound", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.setSoundSettingFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error setting notification sound",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Refreshes the available output devices and the currently selected
  /// output device.
  Future<void> _onRefreshOutputDevicesList(
    RefreshOutputDevicesList event,
    Emitter<SoundState> emit,
  ) async {
    AppLogger.i("SoundBloc: Refreshing output devices.");

    emit(state.copyWith(outputDeviceLoading: true, error: null));
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final outDevices = await _soundRepository.getOutputDevices();
      final selectedOut = await _soundRepository.getSelectedOutputDevice();

      emit(
        state.copyWith(
          outputDevices: outDevices,
          selectedOutputDevice: selectedOut,
          outputDeviceLoading: false,
          error: null,
        ),
      );
    } on GetOutputDevicesException catch (e, stack) {
      AppLogger.e("SoundBloc: Error refreshing output devices", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getOutputDevicesFailed,
        outputDeviceLoading: false,
      ));
    } on GetSelectedOutputDeviceException catch (e, stack) {
      AppLogger.e("SoundBloc: Error refreshing selected output device", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getSelectedOutputDeviceFailed,
        outputDeviceLoading: false,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error refreshing output devices",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
        outputDeviceLoading: false,
      ));
    }
  }

  /// Refreshes the available input devices and the currently selected
  /// input device.
  Future<void> _onRefreshInputDevicesList(
    RefreshInputDevicesList event,
    Emitter<SoundState> emit,
  ) async {
    AppLogger.i("SoundBloc: Refreshing input devices.");

    emit(state.copyWith(inputDeviceLoading: true, error: null));
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final inDevices = await _soundRepository.getInputDevices();
      final selectedIn = await _soundRepository.getSelectedInputDevice();

      emit(
        state.copyWith(
          inputDevices: inDevices,
          selectedInputDevice: selectedIn,
          inputDeviceLoading: false,
          error: null,
        ),
      );
    } on GetInputDevicesException catch (e, stack) {
      AppLogger.e("SoundBloc: Error refreshing input devices", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getInputDevicesFailed,
        inputDeviceLoading: false,
      ));
    } on GetSelectedInputDeviceException catch (e, stack) {
      AppLogger.e("SoundBloc: Error refreshing selected input device", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getSelectedInputDeviceFailed,
        inputDeviceLoading: false,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error refreshing input devices",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
        inputDeviceLoading: false,
      ));
    }
  }

  /// Refreshes only the output volume without reloading the complete
  /// sound settings or output device list.
  Future<void> _onRefreshOutputVolume(
    RefreshOutputVolume event,
    Emitter<SoundState> emit,
  ) async {
    try {
      final volume = await _soundRepository.getOutputVolume();
      emit(state.copyWith(outputVolume: volume, error: null));
    } on GetOutputVolumeException catch (e, stack) {
      AppLogger.e("SoundBloc: Error refreshing output volume", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getOutputVolumeFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error refreshing output volume",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Refreshes only the input volume without reloading the complete
  /// sound settings or input device list.
  Future<void> _onRefreshInputVolume(
    RefreshInputVolume event,
    Emitter<SoundState> emit,
  ) async {
    try {
      final volume = await _soundRepository.getInputVolume();
      emit(state.copyWith(inputVolume: volume, error: null));
    } on GetInputVolumeException catch (e, stack) {
      AppLogger.e("SoundBloc: Error refreshing input volume", error: e, stack: stack);
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.getInputVolumeFailed,
      ));
    } catch (e, stack) {
      AppLogger.e(
        "SoundBloc: Unexpected error refreshing input volume",
        error: e,
        stack: stack,
      );
      emit(state.copyWith(
        status: SoundStatus.error,
        error: SoundError.unknown,
      ));
    }
  }

  /// Cancels the sound change subscription and releases repository resources.
  @override
  Future<void> close() async {
    try {
      await _changeSubscription?.cancel();
      await _soundRepository.close();
    } finally {
      await super.close();
    }
  }
}
