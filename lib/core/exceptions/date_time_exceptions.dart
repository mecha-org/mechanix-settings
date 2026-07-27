abstract class DateTimeException implements Exception {
  final String message;

  const DateTimeException(this.message);

  @override
  String toString() => message;
}

class DateTimeInitializationException extends DateTimeException {
  const DateTimeInitializationException([
    super.message = 'Failed to initialize date and time service.',
  ]);
}

class SetTimeException extends DateTimeException {
  const SetTimeException([super.message = 'Failed to update system time.']);
}

class SetTimezoneException extends DateTimeException {
  const SetTimezoneException([super.message = 'Failed to update timezone.']);
}

class SetNtpException extends DateTimeException {
  const SetNtpException([super.message = 'Failed to update automatic time.']);
}

class SetTimeFormatException extends DateTimeException {
  const SetTimeFormatException([
    super.message = 'Failed to update time format.',
  ]);
}

class GetTimezoneException extends DateTimeException {
  const GetTimezoneException([super.message = 'Failed to get timezone.']);
}

class GetNtpException extends DateTimeException {
  const GetNtpException([
    super.message = 'Failed to get automatic time status.',
  ]);
}

class GetTimeException extends DateTimeException {
  const GetTimeException([super.message = 'Failed to get system time.']);
}

class GetTimeFormatException extends DateTimeException {
  const GetTimeFormatException([super.message = 'Failed to get time format.']);
}
