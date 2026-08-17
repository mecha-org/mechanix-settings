abstract class AboutException implements Exception {
  final String message;

  const AboutException(this.message);

  @override
  String toString() => message;
}

class GetAboutDetailsException extends AboutException {
  const GetAboutDetailsException([
    super.message = 'Failed to retrieve system information.',
  ]);
}

class UpdateDeviceNameException extends AboutException {
  const UpdateDeviceNameException([
    super.message = 'Failed to update device name.',
  ]);
}

class UpdateHostnameException extends AboutException {
  const UpdateHostnameException([super.message = 'Failed to update hostname.']);
}
