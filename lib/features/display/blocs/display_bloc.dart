import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/display/data/models/display_enums.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository.dart';
import 'display_event.dart';
import 'display_state.dart';

class DisplayBloc extends Bloc<DisplayEvent, DisplayState> {
  final DisplayRepository _displayRepository;

  DisplayBloc(this._displayRepository) : super(const DisplayState()) {
    on<DisplayInit>(_onInit);
    on<LoadDisplaySettings>(_onLoadDisplaySettings);
    on<SetBrightness>(_onSetBrightness);
    on<SetAutoBrightness>(_onSetAutoBrightness);
    on<SetScreenTimeout>(_onSetScreenTimeout);
  }

  Future<void> _onInit(DisplayInit event, Emitter<DisplayState> emit) async {
    emit(state.copyWith(status: DisplayStatus.loading));
    try {
      await _displayRepository.init();
      add(const LoadDisplaySettings());
    } on DisplayInitializationException catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error during initialization",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.initializationFailed,
        ),
      );
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Unexpected error during initialization",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      );
    }
  }

  Future<void> _onLoadDisplaySettings(
    LoadDisplaySettings event,
    Emitter<DisplayState> emit,
  ) async {
    emit(state.copyWith(status: DisplayStatus.loading));
    try {
      final brightness = await _displayRepository.getBrightness();
      final autoBrightness = await _displayRepository.getAutoBrightness();
      final timeout = await _displayRepository.getScreenTimeout();

      emit(
        state.copyWith(
          brightness: brightness,
          isAutoBrightness: autoBrightness,
          screenTimeout: timeout,
          status: DisplayStatus.loaded,
          error: null,
        ),
      );
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error loading settings",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      );
    }
  }

  Future<void> _onSetBrightness(
    SetBrightness event,
    Emitter<DisplayState> emit,
  ) async {
    try {
      await _displayRepository.setBrightness(event.brightness);
      emit(state.copyWith(brightness: event.brightness, error: null));
    } on SetBrightnessException catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error setting brightness",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.setBrightnessFailed,
        ),
      );
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Unexpected error setting brightness",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      );
    }
  }

  Future<void> _onSetAutoBrightness(
    SetAutoBrightness event,
    Emitter<DisplayState> emit,
  ) async {
    try {
      await _displayRepository.setAutoBrightness(event.enabled);
      emit(state.copyWith(isAutoBrightness: event.enabled, error: null));
    } on SetAutoBrightnessException catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error setting auto brightness",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.setAutoBrightnessFailed,
        ),
      );
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Unexpected error setting auto brightness",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      );
    }
  }

  Future<void> _onSetScreenTimeout(
    SetScreenTimeout event,
    Emitter<DisplayState> emit,
  ) async {
    try {
      await _displayRepository.setScreenTimeout(event.timeoutSeconds);
      emit(state.copyWith(screenTimeout: event.timeoutSeconds, error: null));
    } on SetScreenTimeoutException catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error setting screen timeout",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.setScreenTimeoutFailed,
        ),
      );
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Unexpected error setting screen timeout",
        error: e,
        stack: stack,
      );
      emit(
        state.copyWith(
          status: DisplayStatus.error,
          error: DisplayError.unknown,
        ),
      );
    }
  }
}
