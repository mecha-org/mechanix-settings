import 'package:mechanix_settings/l10n/app_localizations.dart';

class AboutValidators {
  static String? validateDeviceName(String value, AppLocalizations l10n) {
    if (value.trim().isEmpty) {
      return l10n.deviceNameCannotBeEmpty;
    }

    if (value.length > 64) {
      return l10n.deviceNameMaxLength;
    }

    return null;
  }

  static String? validateHostname(String value, AppLocalizations l10n) {
    if (value.isEmpty) {
      return null;
    }

    if (value.length > 64) {
      return l10n.hostnameMaxLength;
    }

    if (value.startsWith('.') || value.endsWith('.')) {
      return l10n.hostnameDotError;
    }

    final labels = value.split('.');
    final regex = RegExp(r'^[a-zA-Z0-9-]+$');

    for (final label in labels) {
      if (label.isEmpty) {
        return l10n.invalidHostname;
      }

      if (label.startsWith('-') || label.endsWith('-')) {
        return l10n.hostnameHyphenError;
      }

      if (!regex.hasMatch(label)) {
        return l10n.hostnameCharactersError;
      }
    }

    return null;
  }
}
