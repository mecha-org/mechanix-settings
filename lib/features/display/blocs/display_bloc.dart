import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/exceptions/display_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/display/data/models/display_enums.dart';
import 'package:mechanix_settings/features/display/data/repositories/display_repository.dart';
import 'package:mechanix_settings/generated/settingsapp.dart';
import 'package:mxconfig_dart/mxconfig.dart';
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

      // Follow changes and write failures made elsewhere until the bloc closes.
      await Future.wait([
        emit.onEach<SettingsappChange>(
          _displayRepository.changes(),
          onData: (change) {
            switch (change) {
              case DisplayBrightnessChange(:final value):
                emit(state.copyWith(brightness: value / 254));
              case DisplayAutoBrightnessChange(:final value):
                emit(state.copyWith(isAutoBrightness: value));
              case DisplayScreenTimeoutChange(:final value):
                emit(state.copyWith(screenTimeout: value));
              default:
            }
          },
          onError: (e, stack) => AppLogger.e(
            "DisplayBloc: Error watching display settings",
            error: e,
            stack: stack,
          ),
        ),
        emit.onEach<WriteFailure>(
          _displayRepository.watchWriteFailed(),
          onData: (failure) {
            AppLogger.e("DisplayBloc: Write failure: ${failure.error}");
            for (final change in failure.current) {
              switch (SettingsappChange.from(change)) {
                case DisplayBrightnessChange(:final value):
                  emit(
                    state.copyWith(
                      status: DisplayStatus.error,
                      error: DisplayError.setBrightnessFailed,
                      brightness: value / 254,
                    ),
                  );
                case DisplayAutoBrightnessChange(:final value):
                  emit(
                    state.copyWith(
                      status: DisplayStatus.error,
                      error: DisplayError.setAutoBrightnessFailed,
                      isAutoBrightness: value,
                    ),
                  );
                case DisplayScreenTimeoutChange(:final value):
                  emit(
                    state.copyWith(
                      status: DisplayStatus.error,
                      error: DisplayError.setScreenTimeoutFailed,
                      screenTimeout: value,
                    ),
                  );
                default:
                  // Ignore non-display changes from the shared namespace.
                  break;
              }
            }
          },
          onError: (e, stack) => AppLogger.e(
            "DisplayBloc: Error watching write failures",
            error: e,
            stack: stack,
          ),
        ),
      ]);
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
    emit(state.copyWith(status: DisplayStatus.loading, error: null));

    DisplayError? loadError;
    double? brightness;
    bool? autoBrightness;
    int? screenTimeout;

    // Brightness
    try {
      brightness = await _displayRepository.getBrightness();
    } on GetBrightnessException catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error getting brightness",
        error: e,
        stack: stack,
      );
      loadError ??= DisplayError.getBrightnessFailed;
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Unexpected error getting brightness",
        error: e,
        stack: stack,
      );
      loadError ??= DisplayError.unknown;
    }

    // Auto brightness
    try {
      autoBrightness = await _displayRepository.getAutoBrightness();
    } on GetAutoBrightnessException catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error getting auto brightness",
        error: e,
        stack: stack,
      );
      loadError ??= DisplayError.getAutoBrightnessFailed;
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Unexpected error getting auto brightness",
        error: e,
        stack: stack,
      );
      loadError ??= DisplayError.unknown;
    }

    // Screen timeout
    try {
      screenTimeout = await _displayRepository.getScreenTimeout();
    } on GetScreenTimeoutException catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Error getting screen timeout",
        error: e,
        stack: stack,
      );
      loadError ??= DisplayError.getScreenTimeoutFailed;
    } catch (e, stack) {
      AppLogger.e(
        "DisplayBloc: Unexpected error getting screen timeout",
        error: e,
        stack: stack,
      );
      loadError ??= DisplayError.unknown;
    }

    emit(
      state.copyWith(
        brightness: brightness,
        isAutoBrightness: autoBrightness,
        screenTimeout: screenTimeout,
        status: loadError == null ? DisplayStatus.loaded : DisplayStatus.error,
        error: loadError,
      ),
    );
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
