import 'package:mechanix_settings/l10n/app_localizations.dart';

class LanguageOption {
  final String label;
  final String code;

  const LanguageOption({required this.label, required this.code});
}

List<LanguageOption> getLanguageOptions(AppLocalizations l10n) {
  return [
    LanguageOption(label: l10n.languageEnglishUK, code: 'en_GB.UTF-8'),
    LanguageOption(label: l10n.languageEnglishUS, code: 'en_US.UTF-8'),
  ];
}
