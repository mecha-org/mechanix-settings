import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/exceptions/about_exceptions.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/about/data/models/enums.dart';
import 'package:mechanix_settings/features/about/data/repositories/about_repository.dart';
import 'about_event.dart';
import 'about_state.dart';

class AboutBloc extends Bloc<AboutEvent, AboutState> {
  final AboutRepository _repository;

  AboutBloc(this._repository) : super(const AboutState()) {
    on<LoadAboutDetails>(_onLoadAboutDetails);
    on<UpdateDeviceName>(_onUpdateDeviceName);
    on<UpdateHostname>(_onUpdateHostname);
  }

  // Loads the latest system information.
  Future<void> _onLoadAboutDetails(
    LoadAboutDetails event,
    Emitter<AboutState> emit,
  ) async {
    emit(state.copyWith(status: AboutStatus.loading, error: null));

    try {
      final details = await _repository.getAboutDetails();

      emit(
        state.copyWith(
          status: AboutStatus.success,
          details: details,
          error: null,
        ),
      );
    } on GetAboutDetailsException catch (e, stackTrace) {
      AppLogger.e('Failed to get about details', error: e, stack: stackTrace);

      emit(
        state.copyWith(
          status: AboutStatus.failure,
          error: AboutError.aboutDetailsLoadFailed,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'Unexpected error while getting about details',
        error: e,
        stack: stackTrace,
      );

      emit(
        state.copyWith(status: AboutStatus.failure, error: AboutError.unknown),
      );
    }
  }

  // Updates the device name and reloads the latest details.
  Future<void> _onUpdateDeviceName(
    UpdateDeviceName event,
    Emitter<AboutState> emit,
  ) async {
    try {
      await _repository.updateDeviceName(event.name);
      add(const LoadAboutDetails());
    } on UpdateDeviceNameException catch (e, stackTrace) {
      AppLogger.e('Failed to update device name', error: e, stack: stackTrace);

      emit(
        state.copyWith(
          status: AboutStatus.failure,
          error: AboutError.deviceNameUpdateFailed,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'Unexpected error while updating device name',
        error: e,
        stack: stackTrace,
      );

      emit(
        state.copyWith(status: AboutStatus.failure, error: AboutError.unknown),
      );
    }
  }

  // Updates the hostname and reloads the latest details.
  Future<void> _onUpdateHostname(
    UpdateHostname event,
    Emitter<AboutState> emit,
  ) async {
    try {
      await _repository.updateHostname(event.hostname);
      add(const LoadAboutDetails());
    } on UpdateHostnameException catch (e, stackTrace) {
      AppLogger.e('Failed to update hostname', error: e, stack: stackTrace);

      emit(
        state.copyWith(
          status: AboutStatus.failure,
          error: AboutError.hostnameUpdateFailed,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'Unexpected error while updating hostname',
        error: e,
        stack: stackTrace,
      );

      emit(
        state.copyWith(status: AboutStatus.failure, error: AboutError.unknown),
      );
    }
  }
}
