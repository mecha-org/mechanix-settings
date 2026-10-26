import 'package:mechanix_settings/features/wireless/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class WifiPasswordValidator {
  const WifiPasswordValidator._();

  static bool _isHex(String s) => RegExp(r'^[0-9a-fA-F]+$').hasMatch(s);

  /// Validates password length and format based on Wi-Fi security.
  /// Does NOT trim spaces, preserving valid leading/trailing spaces in WPA passphrases.
  static bool isValid(String password, [WirelessSecurity? security]) {
    if (security == null) {
      return password.length >= 8 && password.length <= 63;
    }
    switch (security) {
      case WirelessSecurity.none:
      case WirelessSecurity.enhancedOpen:
        return true;
      case WirelessSecurity.wep:
        // WEP requires 5 or 13 ASCII chars, or 10 or 26 hex digits
        if (password.length == 5 || password.length == 13) return true;
        if ((password.length == 10 || password.length == 26) &&
            _isHex(password)) {
          return true;
        }
        return false;
      case WirelessSecurity.wpaWpa2Personal:
      case WirelessSecurity.wpa3Personal:
        // WPA/WPA2/WPA3 passphrase must be 8-63 ASCII characters, or 64 hex digits
        if (password.length >= 8 && password.length <= 63) return true;
        if (password.length == 64 && _isHex(password)) return true;
        return false;
    }
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
