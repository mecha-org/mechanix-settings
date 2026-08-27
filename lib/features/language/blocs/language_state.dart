import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'package:mechanix_settings/features/language/data/models/enums.dart';

class LanguageState extends Equatable {
  final LanguageStatus status;
  final LanguageError? error;
  final String systemLanguage;
  final Locale appLocale;

  const LanguageState({
    required this.status,
    this.error,
    required this.systemLanguage,
    required this.appLocale,
  });

  factory LanguageState.initial() {
    return const LanguageState(
      status: LanguageStatus.initial,
      error: null,
      systemLanguage: 'en_US.UTF-8',
      appLocale: Locale('en', 'US'),
    );
  }

  LanguageState copyWith({
    LanguageStatus? status,
    LanguageError? error,
    String? systemLanguage,
    Locale? appLocale,
  }) {
    return LanguageState(
      status: status ?? this.status,
      error: error,
      systemLanguage: systemLanguage ?? this.systemLanguage,
      appLocale: appLocale ?? this.appLocale,
    );
  }

  @override
  List<Object?> get props => [status, error, systemLanguage, appLocale];
}
