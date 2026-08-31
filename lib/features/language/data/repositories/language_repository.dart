import 'dart:async';

abstract class LanguageRepository {
  /// Initializes the repository (e.g. D-Bus client).
  Future<void> init();

  /// Gets the primary language setting from the system.
  Future<String> getLanguage();

  /// Sets the primary language setting on the system.
  Future<void> setLanguage(String language);

  /// Releases resources.
  Future<void> close();

  /// Stream of property name lists changed in the repository.
  Stream<List<String>> get propertiesChangedStream;
}
