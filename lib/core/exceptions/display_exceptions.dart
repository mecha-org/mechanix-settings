abstract class DisplayException implements Exception {
  final String message;

  const DisplayException(this.message);

  @override
  String toString() => message;
}

class DisplayInitializationException extends DisplayException {
  const DisplayInitializationException([
    super.message = 'Failed to initialize display settings.',
  ]);
}

class GetBrightnessException extends DisplayException {
  const GetBrightnessException([
    super.message = 'Failed to retrieve brightness.',
  ]);
}

class SetBrightnessException extends DisplayException {
  const SetBrightnessException([
    super.message = 'Failed to update brightness.',
  ]);
}

class GetAutoBrightnessException extends DisplayException {
  const GetAutoBrightnessException([
    super.message = 'Failed to retrieve auto brightness status.',
  ]);
}

class SetAutoBrightnessException extends DisplayException {
  const SetAutoBrightnessException([
    super.message = 'Failed to update auto brightness.',
  ]);
}

class GetScreenTimeoutException extends DisplayException {
  const GetScreenTimeoutException([
    super.message = 'Failed to retrieve screen off time.',
  ]);
}

class SetScreenTimeoutException extends DisplayException {
  const SetScreenTimeoutException([
    super.message = 'Failed to update screen off time.',
  ]);
}

class DisplayCloseException extends DisplayException {
  const DisplayCloseException([
    super.message = 'Failed to close display connection.',
  ]);
}
