import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_settings/core/utils/app_logger.dart';
import 'package:mechanix_settings/features/language/data/models/enums.dart';
import 'package:mechanix_settings/features/language/data/repositories/language_repository.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final LanguageRepository _repository;
  StreamSubscription? _propertiesSubscription;

  LanguageBloc(this._repository) : super(LanguageState.initial()) {
    on<InitializeLanguage>(_onInitialize);
    on<RefreshLanguage>(_onRefresh);
    on<SetSystemLanguage>(_onSetSystemLanguage);
  }

  Locale _parseLocale(String lang) {
    final localePart = lang.split('.').first;
    final parts = localePart.split('_');
    if (parts.length > 1) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(parts[0]);
    }
  }

  Future<void> _onInitialize(
    InitializeLanguage event,
    Emitter<LanguageState> emit,
  ) async {
    emit(state.copyWith(status: LanguageStatus.loading));
    try {
      await _repository.init();

      await _propertiesSubscription?.cancel();
      _propertiesSubscription = _repository.propertiesChangedStream.listen((
        changed,
      ) {
        if (!isClosed && changed.contains('Language')) {
          add(const RefreshLanguage());
        }
      });

      final language = await _repository.getLanguage();
      final appLocale = _parseLocale(language);

      emit(
        state.copyWith(
          status: LanguageStatus.loaded,
          systemLanguage: language,
          appLocale: appLocale,
          error: null,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to initialize language settings: $e', stack: stack);
      emit(
        state.copyWith(
          status: LanguageStatus.error,
          error: LanguageError.initializationFailed,
        ),
      );
    }
  }

  Future<void> _onRefresh(
    RefreshLanguage event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      final language = await _repository.getLanguage();
      final appLocale = _parseLocale(language);

      emit(
        state.copyWith(
          status: LanguageStatus.loaded,
          systemLanguage: language,
          appLocale: appLocale,
          error: null,
        ),
      );
    } catch (e, stack) {
      AppLogger.e('Failed to refresh language settings: $e', stack: stack);
      emit(
        state.copyWith(
          status: LanguageStatus.error,
          error: LanguageError.unknown,
        ),
      );
    }
  }

  Future<void> _onSetSystemLanguage(
    SetSystemLanguage event,
    Emitter<LanguageState> emit,
  ) async {
    final currentLanguage = state.systemLanguage;
    final currentLocale = state.appLocale;

    try {
      final newLocale = _parseLocale(event.language);
      emit(
        state.copyWith(
          status: LanguageStatus.loaded,
          systemLanguage: event.language,
          appLocale: newLocale,
          error: null,
        ),
      );

      await _repository.setLanguage(event.language);
    } catch (e, stack) {
      AppLogger.e('Failed to set system language: $e', stack: stack);
      emit(
        state.copyWith(
          status: LanguageStatus.error,
          error: LanguageError.setLanguageFailed,
          systemLanguage: currentLanguage,
          appLocale: currentLocale,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _propertiesSubscription?.cancel();
    await _repository.close();
    return super.close();
  }
}
