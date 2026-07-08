import 'package:flutter/material.dart';
import 'package:mechanix_settings/l10n/app_localizations.dart';

class TimezoneItem {
  final String id; // IANA timezone identifier

  const TimezoneItem({required this.id});
}

extension TimezoneItemLocalization on TimezoneItem {
  String getLocalizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (l10n == null) return id;

    switch (id) {
      case "Etc/GMT":
        return l10n.timezoneGmt;
      case "Asia/Kolkata":
        return l10n.timezoneIst;
      case "Pacific/Honolulu":
        return l10n.timezoneHst;
      case "America/Anchorage":
        return l10n.timezoneAkst;
      case "America/Los Angeles":
        return l10n.timezonePst;
      case "America/Denver":
        return l10n.timezoneMst;
      case "America/Chicago":
        return l10n.timezoneCstMinus6;
      case "America/New York":
        return l10n.timezoneEst;
      case "America/Halifax":
        return l10n.timezoneAst;
      case "America/Sao_Paulo":
        return l10n.timezoneBrt;
      case "Europe/Paris":
        return l10n.timezoneCet;
      case "Europe/Helsinki":
        return l10n.timezoneEet;
      case "Asia/Dubai":
        return l10n.timezoneGst;
      case "Asia/Bangkok":
        return l10n.timezoneIct;
      case "Asia/Shanghai":
        return l10n.timezoneCstPlus8;
      case "Asia/Tokyo":
        return l10n.timezoneJst;
      case "Australia/Sydney":
        return l10n.timezoneAest;
      case "Pacific/Auckland":
        return l10n.timezoneNzst;
      default:
        return id;
    }
  }
}

const List<TimezoneItem> timezones = [
  TimezoneItem(id: "Etc/GMT"),
  TimezoneItem(id: "Asia/Kolkata"),
  TimezoneItem(id: "Pacific/Honolulu"),
  TimezoneItem(id: "America/Anchorage"),
  TimezoneItem(id: "America/Los Angeles"),
  TimezoneItem(id: "America/Denver"),
  TimezoneItem(id: "America/Chicago"),
  TimezoneItem(id: "America/New York"),
  TimezoneItem(id: "America/Halifax"),
  TimezoneItem(id: "America/Sao Paulo"),
  TimezoneItem(id: "Europe/Paris"),
  TimezoneItem(id: "Europe/Helsinki"),
  TimezoneItem(id: "Asia/Dubai"),
  TimezoneItem(id: "Asia/Bangkok"),
  TimezoneItem(id: "Asia/Shanghai"),
  TimezoneItem(id: "Asia/Tokyo"),
  TimezoneItem(id: "Australia/Sydney"),
  TimezoneItem(id: "Pacific/Auckland"),
];
