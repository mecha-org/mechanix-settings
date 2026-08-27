abstract class LanguageException implements Exception {
  final String message;

  const LanguageException(this.message);

  @override
  String toString() => message;
}

class LanguageInitializationException extends LanguageException {
  const LanguageInitializationException([
    super.message = 'Failed to initialize language settings.',
  ]);
}

class GetLanguageException extends LanguageException {
  const GetLanguageException([
    super.message = 'Failed to retrieve system language settings.',
  ]);
}

class SetLanguageException extends LanguageException {
  const SetLanguageException([
    super.message = 'Failed to update system language settings.',
  ]);
}
