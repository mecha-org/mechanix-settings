import 'package:mechanix_settings/features/wireless/data/models/enums.dart';

/// Thrown by `WirelessRepository.connectToNetwork` when the network cannot be
/// joined without a (new) password from the user, for example:
///
/// * the access point's security changed since the profile was saved
///   (open → WPA, WPA2 → WPA3, ...), so the saved profile cannot be used;
/// * the saved profile has no stored secret;
/// * a new secured network is joined without a password.
///
/// The saved profile is left untouched so nothing is lost if the user cancels.
class WifiPasswordRequiredException implements Exception {
  final String networkName;

  /// Security the access point currently requires.
  final WirelessSecurity security;

  const WifiPasswordRequiredException({
    required this.networkName,
    required this.security,
  });

  @override
  String toString() =>
      'WifiPasswordRequiredException: "$networkName" requires a password '
      '(${security.name})';
}
