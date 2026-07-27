import 'package:mechanix_settings/features/date_time/data/models/enums.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

String getDateTimeErrorMessage(AppLocalizations l10n, DateTimeError error) {
  switch (error) {
    case DateTimeError.initializationFailed:
      return l10n.failedToInitializeDateTime;

    case DateTimeError.timeUpdateFailed:
      return l10n.failedToUpdateTime;

    case DateTimeError.timezoneLoadFailed:
      return l10n.failedToGetTimezone;

    case DateTimeError.timezoneUpdateFailed:
      return l10n.failedToUpdateTimezone;

    case DateTimeError.ntpUpdateFailed:
      return l10n.failedToUpdateAutomaticTime;

    case DateTimeError.timeFormatUpdateFailed:
      return l10n.failedToUpdateTimeFormat;

    case DateTimeError.ntpLoadFailed:
      return l10n.failedToGetAutomaticTime;

    case DateTimeError.timeLoadFailed:
      return l10n.failedToGetSystemTime;

    case DateTimeError.timeFormatLoadFailed:
      return l10n.failedToGetTimeFormat;

    case DateTimeError.unknown:
      return l10n.somethingWentWrong;
  }
}
