import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class WifiPasswordValidator {
  const WifiPasswordValidator._();

  static final _hexPattern = RegExp(r'^[0-9a-fA-F]+$');
  static final _printableAsciiPattern = RegExp(r'^[\x20-\x7E]+$');

  /// Validates password length and format based on Wi-Fi security.
  /// Does NOT trim spaces, preserving valid leading/trailing spaces in WPA passphrases.
  static bool isValid(String password, [WirelessSecurity? security]) {
    final length = password.length;
    bool isAscii() => _printableAsciiPattern.hasMatch(password);
    bool isHex() => _hexPattern.hasMatch(password);

    return switch (security ?? WirelessSecurity.wpaWpa2Personal) {
      WirelessSecurity.none || WirelessSecurity.enhancedOpen => true,

      // 5 or 13 ASCII chars (40/104-bit key), or 10 or 26 hex digits
      WirelessSecurity.wep =>
        ((length == 5 || length == 13) && isAscii()) ||
            ((length == 10 || length == 26) && isHex()),

      // 8–63 ASCII chars passphrase, or 64 hex digits (raw PSK)
      WirelessSecurity.wpaWpa2Personal || WirelessSecurity.wpa3Personal =>
        (length >= 8 && length <= 63 && isAscii()) || (length == 64 && isHex()),
    };
  }

  /// Returns the localized validation error message, or null if valid.
  static String? getErrorMessage(
    String password,
    WirelessSecurity security,
    AppLocalizations l10n,
  ) {
    if (password.isEmpty) {
      return l10n.passwordRequired;
    }
    switch (security) {
      case WirelessSecurity.wep:
        if (!isValid(password, security)) {
          return l10n.invalidWepPassword;
        }
        break;
      case WirelessSecurity.wpaWpa2Personal:
      case WirelessSecurity.wpa3Personal:
        if (!isValid(password, security)) {
          return l10n.invalidWpaPassword;
        }
        break;
      default:
        break;
    }
    return null;
  }
}
