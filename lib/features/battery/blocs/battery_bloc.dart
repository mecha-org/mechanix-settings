import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_event.dart';
import 'package:mechanix_settings/features/battery/blocs/battery_state.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:mechanix_settings/features/battery/data/repositories/battery_repository.dart';

class BatteryBloc extends Bloc<BatteryEvent, BatteryState> {
  final BatteryRepository batteryRepository;
  StreamSubscription? _changeSubscription;

  BatteryBloc({required this.batteryRepository}) : super(const BatteryState()) {
    on<BatteryInit>(_onInit);
    on<BatteryInfoRequested>(_onInfoRequested);
    on<SetBatteryMode>(_onSetBatteryMode);
    on<ToggleBatterySaver>(_onToggleBatterySaver);
  }

  Future<void> _onInit(BatteryInit event, Emitter<BatteryState> emit) async {
    try {
      emit(state.copyWith(status: BatteryStatus.loading, error: null));

      await batteryRepository.init();
      await _initializeBatteryStream();
    } catch (e, stack) {
      AppLogger.e("Failed to initialize battery", error: e, stack: stack);

      emit(
        state.copyWith(
          status: BatteryStatus.error,
          error: BatteryError.initializationFailed,
        ),
      );
    }
  }

  Future<void> _onInfoRequested(
    BatteryInfoRequested event,
    Emitter<BatteryState> emit,
  ) async {
    try {
      await _loadBatteryInfo(emit);
    } catch (e, stack) {
      AppLogger.e("Failed to get battery info", error: e, stack: stack);

      emit(
        state.copyWith(
          status: BatteryStatus.error,
          error: BatteryError.batteryInfoLoadFailed,
        ),
      );
    }
  }

  Future<void> _onSetBatteryMode(
    SetBatteryMode event,
    Emitter<BatteryState> emit,
  ) async {
    try {
      await batteryRepository.setBatteryMode(event.mode);
      await _loadBatteryInfo(emit);
    } catch (e, stack) {
      AppLogger.e("Failed to update battery mode", error: e, stack: stack);

      emit(
        state.copyWith(
          status: BatteryStatus.error,
          error: BatteryError.batteryModeUpdateFailed,
        ),
      );
    }
  }

  Future<void> _onToggleBatterySaver(
    ToggleBatterySaver event,
    Emitter<BatteryState> emit,
  ) async {
    try {
      final targetMode = event.enable
          ? PowerProfileMode.powerSaver
          : PowerProfileMode.balanced;

      emit(state.copyWith(performanceMode: targetMode));
      await batteryRepository.setBatteryMode(targetMode);
      await _loadBatteryInfo(emit);
    } catch (e, stack) {
      AppLogger.e("Failed to toggle battery saver", error: e, stack: stack);

      emit(
        state.copyWith(
          status: BatteryStatus.error,
          error: BatteryError.batteryModeUpdateFailed,
        ),
      );
    }
  }

  Future<void> _initializeBatteryStream() async {
    try {
      await _changeSubscription?.cancel();

      final stream = await batteryRepository.streamBatteryEvents();

      if (stream != null) {
        _changeSubscription = stream.listen((properties) {
          AppLogger.d("Battery properties changed: $properties");

          if (properties.contains("TimeToFull") ||
              properties.contains("Percentage") ||
              properties.contains("TimeToEmpty") ||
              properties.contains("State") ||
              properties.contains("ActiveProfile")) {
            add(const BatteryInfoRequested());
          }
        });
      }
    } catch (e, stack) {
      AppLogger.e(
        "Failed to initialize battery events stream",
        error: e,
        stack: stack,
      );
    }
  }

  Future<void> _loadBatteryInfo(Emitter<BatteryState> emit) async {
    final info = await batteryRepository.getBatteryInfo();

    emit(
      state.copyWith(
        status: BatteryStatus.loaded,
        batteryPercentage: info.batteryPercentage,
        batteryStatus: info.status,
        performanceMode: info.mode,
        batteryChargingTime: info.batteryChargingTime,
        batteryRemainingTime: info.batteryRemainingTime,
        availableBatteryModes: info.availableBatteryModes,
        error: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _changeSubscription?.cancel();
    await batteryRepository.close();
    return super.close();
  }
}
