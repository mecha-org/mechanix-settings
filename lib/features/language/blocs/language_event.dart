import 'package:equatable/equatable.dart';

abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object?> get props => [];
}

class InitializeLanguage extends LanguageEvent {
  const InitializeLanguage();
}

class RefreshLanguage extends LanguageEvent {
  const RefreshLanguage();
}

class SetSystemLanguage extends LanguageEvent {
  final String language;

  const SetSystemLanguage(this.language);

  @override
  List<Object?> get props => [language];
}
