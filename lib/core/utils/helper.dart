import 'package:mechanix_settings/features/about/data/models/enums.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
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

String getBatteryErrorMessage(AppLocalizations l10n, BatteryError error) {
  switch (error) {
    case BatteryError.initializationFailed:
      return l10n.failedToInitializeBattery;

    case BatteryError.batteryInfoLoadFailed:
      return l10n.failedToGetBatteryInfo;

    case BatteryError.batteryModeUpdateFailed:
      return l10n.failedToUpdateBatteryMode;

    case BatteryError.batteryModeLoadFailed:
      return l10n.failedToGetBatteryMode;

    case BatteryError.batteryModesLoadFailed:
      return l10n.failedToGetAvailableBatteryModes;

    case BatteryError.batteryEventsInitializationFailed:
      return l10n.failedToInitializeBatteryEvents;

    case BatteryError.unknown:
      return l10n.somethingWentWrong;
  }
}

String getAboutErrorMessage(AppLocalizations l10n, AboutError error) {
  switch (error) {
    case AboutError.aboutDetailsLoadFailed:
      return l10n.failedToGetAboutDetails;

    case AboutError.deviceNameUpdateFailed:
      return l10n.failedToUpdateDeviceName;

    case AboutError.hostnameUpdateFailed:
      return l10n.failedToUpdateHostname;

    case AboutError.unknown:
      return l10n.somethingWentWrong;
  }
}
