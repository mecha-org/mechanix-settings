import 'package:mechanix_settings/l10n/app_localizations.dart';

String getDateFormatLabel(AppLocalizations l10n, String format) {
  switch (format) {
    case "dd/MM/yyyy":
      return l10n.dateFormatDmy;
    case "MM/dd/yy":
      return l10n.dateFormatMdy;
    case "yyyy-MM-dd":
      return l10n.dateFormatYmd;
    case "dd MMM yyyy":
      return l10n.dateFormatDmyShort;
    case "dd MMMM yyyy":
      return l10n.dateFormatDmyLong;
    default:
      return format;
  }
}
