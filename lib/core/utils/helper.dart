import 'package:mechanix_settings/features/about/data/models/enums.dart';
import 'package:mechanix_settings/features/battery/data/models/enums.dart';
import 'package:mechanix_settings/features/date_time/data/models/enums.dart';
import 'package:mechanix_settings/features/sound/data/models/enums.dart';
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

String getSoundErrorMessage(AppLocalizations l10n, SoundError error) {
  switch (error) {
    case SoundError.initializationFailed:
      return l10n.failedToInitializeSound;

    case SoundError.getOutputVolumeFailed:
      return l10n.failedToGetOutputVolume;

    case SoundError.setOutputVolumeFailed:
      return l10n.failedToUpdateOutputVolume;

    case SoundError.getOutputDevicesFailed:
      return l10n.failedToGetOutputDevices;

    case SoundError.getSelectedOutputDeviceFailed:
      return l10n.failedToGetSelectedOutputDevice;

    case SoundError.setSelectedOutputDeviceFailed:
      return l10n.failedToUpdateOutputDevice;

    case SoundError.getInputVolumeFailed:
      return l10n.failedToGetInputVolume;

    case SoundError.setInputVolumeFailed:
      return l10n.failedToUpdateInputVolume;

    case SoundError.getInputDevicesFailed:
      return l10n.failedToGetInputDevices;

    case SoundError.getSelectedInputDeviceFailed:
      return l10n.failedToGetSelectedInputDevice;

    case SoundError.setSelectedInputDeviceFailed:
      return l10n.failedToUpdateInputDevice;

    case SoundError.getSoundSettingFailed:
      return l10n.failedToGetSoundSettings;

    case SoundError.setSoundSettingFailed:
      return l10n.failedToUpdateSoundSettings;

    case SoundError.unknown:
      return l10n.somethingWentWrong;
  }
}
